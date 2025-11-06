#! /bin/bash

echo "applying iommu soft split.."
sudo grubby --update-kernel=ALL --args="amd_iommu=on iommu=pt pcie_acs_override=downstream,multifunction"
