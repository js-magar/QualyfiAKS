param RGLocation string
param bastionSubnetName string
param vnetName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {name: vnetName}
resource BastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {name: bastionSubnetName,parent: virtualNetwork}
