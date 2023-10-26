param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param name string

param vnetName string

param vnetResourceGroupName string

param subnetName string

param privateLinkServiceId string

param groupIds array

param privateDnsZoneIds array

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').privateEndpoint}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

var privateDnsZoneConfigs = [for id in privateDnsZoneIds: {
  name: replace(substring(id, lastIndexOf(id, '/') + 1), '.', '-')
  properties: {
    privateDnsZoneId: id
  }
}]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: resourceName
  location: location
  properties: {
    subnet: {
      id: vnet::subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: resourceName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
  resource privateEndpointZoneGroup 'privateDnsZoneGroups' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: privateDnsZoneConfigs
    }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
  resource subnet 'subnets' existing = {
    name: subnetName
  }
}
