param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param name string

param routes array = []

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').routeTable}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource routeTable 'Microsoft.Network/routeTables@2022-11-01' = {
  name: resourceName
  location: location
  properties: {
    routes: routes
  }
}

output name string = routeTable.name
output id string = routeTable.id
