#!/bin/bash

# Reclaim disk on the Proxmox host from routine accumulations that have no
# upper bound by default:
#   - apt package cache (/var/cache/apt/archives)
#   - orphaned kernels (apt autoremove, keeps the running one + its deps)
#   - systemd journal (vacuum down to the configured SystemMaxUse)
#
# Nothing here touches LXC disks, /mnt data or Podman images. For images see
# prune_images.sh.
#
# Usage: ./cleanup_host.sh [-n|--dry-run] [-h|--help] [--apt|--kernels|--journal]...
#   No selector given -> all three steps.
#
# Run from the Proxmox host as root.

set -uo pipefail

DRY_RUN=0
DO_APT=0
DO_KERNELS=0
DO_JOURNAL=0
SELECTED=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-h|--help] [--apt] [--kernels] [--journal]

Reclaim disk on the Proxmox host.

  (no selector) Run all three steps below
  --apt         Clear /var/cache/apt/archives
  --kernels     Remove orphaned kernels via apt autoremove
  --journal     Vacuum the systemd journal to its configured SystemMaxUse
  -n, --dry-run Report only, change nothing
  -h, --help    Show this help

Examples:
  $(basename "$0")              # run every cleanup step
  $(basename "$0") -n           # show what would be freed, change nothing
  $(basename "$0") --journal    # only vacuum the journal
EOF
}

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    --apt) DO_APT=1; SELECTED=1 ;;
    --kernels) DO_KERNELS=1; SELECTED=1 ;;
    --journal) DO_JOURNAL=1; SELECTED=1 ;;
    *)
      echo "Error: invalid argument '$arg'."
      usage
      exit 1
      ;;
  esac
done

# No explicit selector -> run everything
if [ "$SELECTED" -eq 0 ]; then
  DO_APT=1
  DO_KERNELS=1
  DO_JOURNAL=1
fi

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root."
  exit 1
fi

human() {
  # Bytes -> human readable, e.g. 1753180775 -> 1.6G
  if [ -z "${1:-}" ] || [ "$1" -le 0 ] 2>/dev/null; then
    echo "0B"
  else
    numfmt --to=iec --suffix=B --format="%.1f" "$1"
  fi
}

dir_bytes() {
  [ -d "$1" ] || { echo 0; return; }
  du -sb "$1" 2>/dev/null | awk '{print $1}'
}

# Journal bytes, parsed from "take up 791.2M in the file system."
journal_bytes() {
  local out num unit
  out=$(journalctl --disk-usage 2>/dev/null)
  if [[ "$out" =~ take\ up\ ([0-9.]+)([KMGTP]?) ]]; then
    num=${BASH_REMATCH[1]}
    unit=${BASH_REMATCH[2]}
    awk -v n="$num" -v u="$unit" 'BEGIN{
      m[""]=1; m["K"]=1024; m["M"]=1024^2; m["G"]=1024^3; m["T"]=1024^4; m["P"]=1024^5;
      printf "%d\n", n * m[u]
    }'
  else
    echo 0
  fi
}

total_before=0
failed=0

echo "=========================================="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Host cleanup (DRY RUN, nothing will be removed)"
else
  echo "Host cleanup"
fi
echo "=========================================="

# ---------------------------------------------------------------- apt cache
if [ "$DO_APT" -eq 1 ]; then
  echo "------------------------------------------"
  echo ">>> APT package cache"
  echo "------------------------------------------"
  before=$(dir_bytes /var/cache/apt/archives)
  count=$(find /var/cache/apt/archives -maxdepth 1 -name '*.deb' 2>/dev/null | wc -l)
  echo "  Cached .deb files: $count"
  echo "  Size before: $(human "$before")"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] Would run 'apt-get clean'."
    total_before=$((total_before + before))
  elif ! output=$(apt-get clean 2>&1); then
    echo "  [ERROR] apt-get clean failed:"
    printf '%s\n' "$output" | sed 's/^/    /'
    failed=$((failed + 1))
  else
    after=$(dir_bytes /var/cache/apt/archives)
    echo "  Size after:  $(human "$after")"
    echo "  [OK] Reclaimed $(human $((before - after)))"
    total_before=$((total_before + before))
  fi
fi

# ----------------------------------------------------------------- kernels
if [ "$DO_KERNELS" -eq 1 ]; then
  echo "------------------------------------------"
  echo ">>> Orphaned kernels"
  echo "------------------------------------------"
  running=$(uname -r)
  echo "  Running kernel: $running"

  # Candidate list without touching anything
  removable=$(apt-get autoremove --dry-run 2>/dev/null \
    | awk '/^Remv /{print $2}' \
    | grep -E '^(proxmox-kernel|pve-kernel)' || true)
  count=$(printf '%s' "$removable" | grep -c '[^[:space:]]')
  count=${count:-0}

  if [ "$count" -eq 0 ]; then
    echo "  [OK] No orphaned kernels."
  else
    printf '%s\n' "$removable" | while read -r pkg; do
      [[ -z "$pkg" ]] && continue
      echo "    - $pkg"
    done

    # Bytes apt reports it will free
    before=$(apt-get autoremove --dry-run 2>/dev/null \
      | sed -n 's/^After this operation, \([0-9,]*\) [kKMGTP]*B disk space will be freed\..*/\1/p' \
      | tr -d ',')
    case "$before" in ''|*[!0-9]*) before=0 ;; esac

    if [ "$DRY_RUN" -eq 1 ]; then
      echo "  [DRY-RUN] Would remove $count kernel package(s), freeing $(human "$before")."
      total_before=$((total_before + before))
    else
      # Never remove the kernel we are currently running
      if printf '%s\n' "$removable" | grep -qF "$running"; then
        echo "  [ERROR] autoremove wants to remove the running kernel ($running). Aborting this step."
        failed=$((failed + 1))
      elif ! output=$(DEBIAN_FRONTEND=noninteractive apt-get autoremove -y 2>&1); then
        echo "  [ERROR] apt-get autoremove failed:"
        printf '%s\n' "$output" | sed 's/^/    /'
        failed=$((failed + 1))
      else
        total_before=$((total_before + before))
        echo "  [OK] Removed $count kernel package(s), freed $(human "$before")"
        if [ -x /usr/sbin/update-grub ]; then
          if update-grub >/dev/null 2>&1; then
            echo "  [OK] GRUB regenerated."
          else
            echo "  [WARN] update-grub failed, check boot entries manually."
          fi
        fi
      fi
    fi
  fi
fi

# ----------------------------------------------------------------- journal
if [ "$DO_JOURNAL" -eq 1 ]; then
  echo "------------------------------------------"
  echo ">>> Systemd journal"
  echo "------------------------------------------"
  before=$(journal_bytes)
  limit=$(systemd-analyze cat-config systemd/journald.conf 2>/dev/null \
    | sed -n 's/^SystemMaxUse=//p' | tail -1)
  echo "  Current size: $(human "$before")"
  echo "  Enforced limit (SystemMaxUse): ${limit:-<unset>}"

  if [ -z "$limit" ]; then
    echo "  [WARN] SystemMaxUse is not configured; journald defaults to 10% of disk."
    echo "         Consider /etc/systemd/journald.conf.d/99-limits.conf"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] Would run 'journalctl --vacuum-size=${limit:-500M}'."
    total_before=$((total_before + before))
  elif ! output=$(journalctl --vacuum-size="${limit:-500M}" 2>&1); then
    echo "  [ERROR] journalctl --vacuum-size failed:"
    printf '%s\n' "$output" | sed 's/^/    /'
    failed=$((failed + 1))
  else
    after=$(journal_bytes)
    freed=$((before - after))
    [ "$freed" -lt 0 ] && freed=0
    echo "  Size after:  $(human "$after")"
    echo "  [OK] Reclaimed $(human "$freed")"
    total_before=$((total_before + before))
  fi
fi

echo ""
echo "=========================================="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN finished. Nothing was removed."
fi
echo "Failed steps: $failed"
echo "Reclaimable:  $(human "$total_before")"
echo "=========================================="

[ "$failed" -gt 0 ] && exit 1
exit 0
