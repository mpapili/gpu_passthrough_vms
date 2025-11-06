#! /bin/bash

# NOTE - these were the ID's I found on my GPU's on my board, update them every time
echo "applying iommu soft split.."
sudo grubby --update-kernel=ALL --args='pcie_acs_override=downstream,multifunction,ids=1022:1483,1002:1478,1002:1479'
