param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
])
param environment string

param name string

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').logAnalyticsWorkspace}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: resourceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = law.id
output name string = law.name
