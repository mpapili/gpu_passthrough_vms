#!/usr/bin/env bash
# Show IOMMU groups with IDs + human-readable names;
# then list video devices (GPU functions) and everything sharing their group.
# Fedora-ready (requires: pciutils for lspci)

set -euo pipefail

ROOT="/sys/kernel/iommu_groups"

hr_name() {
  # Human-readable name from lspci; strip the leading BDF it echoes
  lspci -s "$1" | sed -E 's/^[0-9a-fA-F:.]+[[:space:]]+//'
}

is_video() {
  # Detect VGA/3D/Display controllers via class text
  lspci -D -s "$1" | grep -qiE 'VGA compatible controller|3D controller|Display controller'
}

if [[ ! -d "$ROOT" ]]; then
  echo "No IOMMU groups at $ROOT."
  echo "Tip: enable IOMMU in BIOS and add kernel args: amd_iommu=on iommu=pt"
  exit 1
fi

echo "=== All IOMMU Groups ==="
for gpath in "$ROOT"/*; do
  g=$(basename "$gpath")
  echo "IOMMU Group $g:"
  for dpath in "$gpath"/devices/*; do
    dev=$(basename "$dpath")                                # 0000:BB:DD.F
    ids="$(lspci -ns "$dev")"                               # numeric IDs/class
    name="$(hr_name "$dev")"                                # human-readable
    printf "  %s  %-45s | %s\n" "$dev" "$ids" "$name"
  done
done

echo
echo "=== Video Devices (VGA/3D/Display) and Everything Sharing Their Group ==="

# Helper: return IOMMU group number for a given PCI BDF
group_of() {
  readlink -f "/sys/bus/pci/devices/$1/iommu_group" | awk -F/ '{print $NF}'
}

# Find video-class devices by lspci class description
mapfile -t VIDEO_BDFS < <(lspci -D | grep -Ei 'VGA compatible controller|3D controller|Display controller' | awk '{print $1}')

if ((${#VIDEO_BDFS[@]}==0)); then
  echo "No video-class devices detected by lspci."
  exit 0
fi

# Deduplicate groups tied to video devices
declare -A VID_GROUPS=()
for bdf in "${VIDEO_BDFS[@]}"; do
  g="$(group_of "$bdf" 2>/dev/null || true)"
  [[ -n "$g" ]] && VID_GROUPS["$g"]=1
done

for g in "${!VID_GROUPS[@]}"; do
  echo
  echo "IOMMU Group $g (contains video device):"
  for dpath in "$ROOT"/"$g"/devices/*; do
    dev=$(basename "$dpath")
    ids="$(lspci -ns "$dev")"
    name="$(hr_name "$dev")"
    if is_video "$dev"; then
      printf "  * %s  %-45s | %s  <= VIDEO\n" "$dev" "$ids" "$name"
    else
      printf "    %s  %-45s | %s\n" "$dev" "$ids" "$name"
    fi
  done
done

