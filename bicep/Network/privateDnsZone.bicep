param name string

param vnetsToLink array = []

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
}

module links 'privateDnsZones/virtualNetworkLink.bicep' = [for (vnet, i) in vnetsToLink: {
  name: take('${i}-${deployment().name}-vnl-${vnet.name}', 64)
  params: {
    privateDnsZoneName: privateDnsZone.name
    vnetName: vnet.name
    vnetResourceGroupName: vnet.resourceGroupName
    vnetSubscriptionId: vnet.subscriptionId
  }
}]

output id string = privateDnsZone.id
output name string = privateDnsZone.name
