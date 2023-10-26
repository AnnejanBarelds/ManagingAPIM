param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
])
param environment string

param name string

param addressPrefixes array

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').virtualNetwork}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: resourceName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

output id string = vnet.id
output name string = vnet.name
