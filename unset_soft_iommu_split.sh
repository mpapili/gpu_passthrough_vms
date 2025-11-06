#! /bin/bash

echo "unsetting soft iommu split.."
sudo grubby --update-kernel=ALL --remove-args="pcie_acs_override"
