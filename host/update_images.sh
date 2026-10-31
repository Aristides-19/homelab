#!/bin/bash

# Apply pending image updates of a homelab service, on demand.
#
# WUD (or Diun, if you still run it) tells you that an image changed; this script is
# what you run to apply it:
#   pull -> restart the Quadlet unit -> remove the previous image.
#
# Nothing here is scheduled. The old image is only removed when the unit came back
# active, so a failed restart always leaves the previous image available to roll back.
#
# The LXCs running a service are resolved from the mountpoints in host/config/[id].conf,
# so shared services (dozzle-agent) are handled in every LXC where they are mounted.
#
# Usage:
#   ./update_images.sh --all
#   ./update_images.sh --service jellyfin
#   ./update_images.sh --service dozzle-agent
#   ./update_images.sh -n --all

set -uo pipefail

REPO="/opt/homelab"
DRY_RUN=0
KEEP_OLD=0
ALL=0
SERVICES=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [-n|--dry-run] [--keep-old] (-a|--all | -s|--service NAME ...)

Pull the latest version of a service image, restart its Quadlet unit and remove
the previous image.

  -s, --service NAME  Service folder name (e.g. jellyfin, paperless). Repeatable.
  -a, --all           Every service with a pod.yaml in the repo.
  -n, --dry-run       Show the plan. Does not contact registries, pull or restart.
      --keep-old      Keep the previous image (rollback stays possible).
  -h, --help          Show this help.

Examples:
  $(basename "$0") --service jellyfin
  $(basename "$0") -n --all
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    --keep-old) KEEP_OLD=1; shift ;;
    -a|--all) ALL=1; shift ;;
    -s|--service)
      [ $# -lt 2 ] && { echo "Error: --service needs a NAME."; usage; exit 1; }
      SERVICES+=("$2"); shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown argument '$1'."; usage; exit 1 ;;
  esac
done

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root."
  exit 1
fi

if [ "$ALL" -eq 0 ] && [ ${#SERVICES[@]} -eq 0 ]; then
  echo "Error: nothing to do. Use --all or --service NAME."
  usage
  exit 1
fi

human() {
  if [ -z "${1:-}" ] || [ "$1" -le 0 ] 2>/dev/null; then
    echo "0B"
  else
    numfmt --to=iec --suffix=B --format="%.1f" "$1"
  fi
}

# Every [id]-[hostname]/[service]/ folder that has a pod.yaml
list_services() {
  local dir
  for dir in "$REPO"/[0-9]*-*/[a-z0-9]*/; do
    dir=${dir%/}
    [ -f "$dir/pod.yaml" ] || continue
    echo "$(basename "$dir")|$dir"
  done
}

# LXCs that mount $1 as a service folder, straight from the config snapshots
resolve_lxcs() {
  local dir="$1" conf id
  for conf in "$REPO"/host/config/[0-9]*.conf; do
    [ -f "$conf" ] || continue
    id=$(basename "$conf" .conf)
    grep -qF "$dir,mp=" "$conf" && echo "$id"
  done
}

total_updated=0
total_removed=0
total_freed=0
failed=0

# update_in_lxc LXC UNIT IMAGE...
update_in_lxc() {
  local lxc="$1" unit="$2"
  shift 2
  local image old_id new_id changed=0
  local -a old_ids=()

  echo "  --- LXC $lxc (unit $unit)"

  if ! pct status "$lxc" 2>/dev/null | grep -q "status: running"; then
    echo "  [SKIP] LXC $lxc is not running."
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [DRY-RUN] would pull and compare:"
    printf '      - %s\n' "$@"
    echo "  [DRY-RUN] would restart: systemctl restart $unit"
    [ "$KEEP_OLD" -eq 0 ] && echo "  [DRY-RUN] would remove the previous image(s) after a successful restart"
    return 0
  fi

  for image in "$@"; do
    old_id=$(pct exec "$lxc" -- podman image inspect --format '{{.Id}}' "$image" 2>/dev/null)
    old_id=${old_id//[[:space:]]/}

    if ! out=$(pct exec "$lxc" -- podman pull "$image" 2>&1); then
      echo "  [ERROR] pull failed: $image"
      printf '%s\n' "$out" | tail -3 | sed 's/^/      /'
      failed=$((failed + 1))
      continue
    fi

    new_id=$(pct exec "$lxc" -- podman image inspect --format '{{.Id}}' "$image" 2>/dev/null)
    new_id=${new_id//[[:space:]]/}

    if [ -z "$old_id" ]; then
      echo "  [NEW]  $image"
      changed=1
    elif [ "$old_id" = "$new_id" ]; then
      echo "  [OK]   $image (already up to date)"
    else
      echo "  [UPD]  $image"
      echo "         ${old_id:0:12} -> ${new_id:0:12}"
      changed=1
      old_ids+=("$old_id")
    fi
  done

  if [ "$changed" -eq 0 ]; then
    echo "  [OK] nothing changed, unit not restarted."
    return 0
  fi

  if ! pct exec "$lxc" -- systemctl restart "$unit" >/dev/null 2>&1; then
    echo "  [ERROR] systemctl restart $unit failed -> previous image KEPT for rollback."
    failed=$((failed + 1))
    return 1
  fi
  if [ "$(pct exec "$lxc" -- systemctl is-active "$unit" 2>/dev/null)" != "active" ]; then
    echo "  [ERROR] $unit is not active after restart -> previous image KEPT for rollback."
    failed=$((failed + 1))
    return 1
  fi
  echo "  [OK] $unit restarted and active."

  total_updated=$((total_updated + 1))

  if [ "$KEEP_OLD" -eq 1 ]; then
    echo "  [KEEP] --keep-old: previous image(s) left in place."
    return 0
  fi

  local in_use id size
  in_use=$(pct exec "$lxc" -- podman ps -a --format '{{.ImageID}}' 2>/dev/null)
  for id in "${old_ids[@]}"; do
    # Skip if any container still uses it
    if grep -qF "${id:0:12}" <<<"$in_use"; then
      echo "  [SKIP] previous image still in use by a container: ${id:0:12}"
      continue
    fi
    size=$(pct exec "$lxc" -- podman image inspect "$id" --format '{{.Size}}' 2>/dev/null)
    size=${size//[[:space:]]/}
    if pct exec "$lxc" -- podman rmi "$id" >/dev/null 2>&1; then
      echo "  [OK] removed previous image ${id:0:12} ($(human "${size:-0}"))"
      total_removed=$((total_removed + 1))
      total_freed=$((total_freed + ${size:-0}))
    else
      echo "  [ERROR] could not remove previous image ${id:0:12}"
      failed=$((failed + 1))
    fi
  done
  return 0
}

process_service() {
  local name="$1" entry dir unit image lxc
  local -a images=() pending=() lxcs=()

  entry=$(list_services | awk -F'|' -v n="$name" '$1==n {print; exit}')
  if [ -z "$entry" ]; then
    echo "------------------------------------------"
    echo ">>> $name"
    echo "------------------------------------------"
    echo "  [ERROR] service '$name' not found (no $REPO/[id]-*/$name/pod.yaml)."
    failed=$((failed + 1))
    return 1
  fi

  dir=${entry#*|}
  unit=$(basename "$dir")

  echo "------------------------------------------"
  echo ">>> $name  (unit $unit)"
  echo "------------------------------------------"

  mapfile -t lxcs < <(resolve_lxcs "$dir")
  if [ ${#lxcs[@]} -eq 0 ]; then
    echo "  [SKIP] $dir is not mounted in any host/config/*.conf (service not deployed)."
    return 0
  fi

  mapfile -t images < <(awk '/^[[:space:]]*image:/ {print $2}' "$dir/pod.yaml")
  if [ ${#images[@]} -eq 0 ]; then
    echo "  [SKIP] no images in pod.yaml."
    return 0
  fi

  for image in "${images[@]}"; do
    case "$image" in
      localhost/*) echo "  [SKIP] $image (locally built, no registry)" ;;
      *@sha256:*)  echo "  [SKIP] $image (digest pinned)" ;;
      *)           pending+=("$image") ;;
    esac
  done

  if [ ${#pending[@]} -eq 0 ]; then
    echo "  [SKIP] nothing updatable."
    return 0
  fi

  for lxc in "${lxcs[@]}"; do
    update_in_lxc "$lxc" "$unit" "${pending[@]}"
  done
  return 0
}

if [ "$DRY_RUN" -eq 1 ]; then
  echo "=== Image update plan (DRY RUN, nothing will be pulled or restarted) ==="
else
  echo "=== Applying image updates ==="
fi

if [ "$ALL" -eq 1 ]; then
  while IFS='|' read -r name _; do
    process_service "$name"
  done < <(list_services)
else
  for name in "${SERVICES[@]}"; do
    process_service "$name"
  done
fi

echo ""
echo "=========================================="
if [ "$DRY_RUN" -eq 1 ]; then
  echo "DRY RUN finished. Nothing was changed."
fi
echo "Services updated: $total_updated"
echo "Images removed:   $total_removed ($(human "$total_freed") freed)"
echo "Errors:           $failed"
echo "=========================================="

[ "$failed" -gt 0 ] && exit 1
exit 0
