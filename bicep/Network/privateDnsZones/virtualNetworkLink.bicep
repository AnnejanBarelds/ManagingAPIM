param privateDnsZoneName string

param vnetName string

param vnetResourceGroupName string

param vnetSubscriptionId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
  resource link 'virtualNetworkLinks@2020-06-01' = {
    name: 'vnl-${vnet.name}'
    location: 'global'
    properties: {
      virtualNetwork: {
        id: vnet.id
      }
      registrationEnabled: false
    }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetSubscriptionId, vnetResourceGroupName)
}
