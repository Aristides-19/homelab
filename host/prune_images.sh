#!/bin/bash

# Reclaim disk from dangling (untagged) Podman images left behind by pulls/updates.
# Only removes <none>:<none> images: tagged images and images in use are never touched,
# so this is safe for rollback of the current generation and for stopped pods.
#
# Usage: ./prune_images.sh [-n|--dry-run] [-h|--help] [LXC_ID...]
#   No LXC_ID given -> all running LXC containers.
#   -n, --dry-run  -> report only, remove nothing.
#
# Run from the Proxmox host as root.

set -uo pipefail

DRY_RUN=0
TARGETS=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [-h|--help] [LXC_ID...]

Prune dangling Podman images (<none>:<none>) inside LXC containers.

  (no LXC_ID)   All running LXC containers
  -n, --dry-run Report only, remove nothing
  -h, --help    Show this help

Examples:
  $(basename "$0")              # prune dangling images in every running LXC
  $(basename "$0") -n           # see what would be reclaimed, change nothing
  $(basename "$0") 200 401      # only LXCs 200 and 401
EOF
}

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    ''|*[!0-9]*)
      echo "Error: invalid argument '$arg'."
      usage
      exit 1
      ;;
    *) TARGETS+=("$arg") ;;
  esac
done

# Ensure script is run as root
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

if [ ${#TARGETS[@]} -eq 0 ]; then
  mapfile -t ids < <(pct list | awk 'NR>1 && $2=="running" {print $1}')
else
  ids=("${TARGETS[@]}")
fi

if [ ${#ids[@]} -eq 0 ]; then
  echo "No running LXC containers found."
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo "=== Dangling image report (DRY RUN, nothing will be removed) ==="
else
  echo "=== Pruning dangling images across LXC containers ==="
fi

total_before=0
total_after=0
total_dangling=0
touched=0
skipped=0
failed=0

for vmid in "${ids[@]}"; do
  name=$(pct config "$vmid" 2>/dev/null | awk '/^hostname:/ {print $2}')
  [[ -z "$name" ]] && name="unknown"
  echo "------------------------------------------"
  echo ">>> LXC $vmid - $name"
  echo "------------------------------------------"

  status=$(pct status "$vmid" 2>/dev/null)
  if [[ -z "$status" ]]; then
    echo "  [SKIP] LXC $vmid does not exist."
    skipped=$((skipped + 1))
    continue
  fi
  if [[ "$status" != *"status: running"* ]]; then
    echo "  [SKIP] LXC $vmid is not running (status: ${status:-offline})"
    skipped=$((skipped + 1))
    continue
  fi
  if ! pct exec "$vmid" -- sh -c 'command -v podman >/dev/null 2>&1'; then
    echo "  [SKIP] podman is not installed (bare-metal LXC)."
    skipped=$((skipped + 1))
    continue
  fi

  # Reclaimable bytes accounted by podman for images (includes shared-layer math)
  before=$(pct exec "$vmid" -- podman system df --format '{{.Type}}|{{.RawReclaimable}}' 2>/dev/null \
    | awk -F'|' '$1=="Images" {print $2}')
  before=${before:-0}

  # Detail of what is actually dangling
  dangling=$(pct exec "$vmid" -- podman images --filter dangling=true --format '{{.ID}}|{{.Size}}|{{.CreatedAt}}' 2>/dev/null)
  count=$(printf '%s' "$dangling" | grep -c '[^[:space:]]')
  count=${count:-0}

  if [ "$count" -eq 0 ]; then
    echo "  [OK] No dangling images. Reclaimable (images): $(human "$before")"
    total_before=$((total_before + before))
    total_after=$((total_after + before))
    continue
  fi

  total_dangling=$((total_dangling + count))
  echo "  Dangling images: $count"
  printf '%s\n' "$dangling" | while IFS='|' read -r id size created; do
    [[ -z "$id" ]] && continue
    echo "    - $id  $size  ($created)"
  done
  echo "  Reclaimable (images) before: $(human "$before")"

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] Would prune $count dangling image(s)."
    total_before=$((total_before + before))
    total_after=$((total_after + before))
    continue
  fi

  if ! output=$(pct exec "$vmid" -- podman image prune -f 2>&1); then
    echo "  [ERROR] podman image prune failed:"
    printf '%s\n' "$output" | sed 's/^/    /'
    failed=$((failed + 1))
    total_before=$((total_before + before))
    total_after=$((total_after + before))
    continue
  fi

  after=$(pct exec "$vmid" -- podman system df --format '{{.Type}}|{{.RawReclaimable}}' 2>/dev/null \
    | awk -F'|' '$1=="Images" {print $2}')
  after=${after:-0}

  reclaimed=$((before - after))
  [ "$reclaimed" -lt 0 ] && reclaimed=0

  echo "  Reclaimable (images) after:  $(human "$after")"
  echo "  [OK] Pruned $count dangling image(s), reclaimed $(human "$reclaimed")"

  total_before=$((total_before + before))
  total_after=$((total_after + after))
  touched=$((touched + 1))
done

echo ""
echo "=========================================="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN finished. Nothing was removed."
fi
echo "LXCs scanned:   ${#ids[@]}"
echo "LXCs pruned:    $touched"
echo "LXCs skipped:   $skipped"
echo "LXCs failed:    $failed"
echo "Dangling found: $total_dangling image(s)"
echo "Reclaimable:    $(human "$total_before") -> $(human "$total_after") ($(human $((total_before - total_after))) reclaimed)"
echo "=========================================="

[ "$failed" -gt 0 ] && exit 1
exit 0
