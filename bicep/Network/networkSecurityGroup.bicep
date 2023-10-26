param location string = resourceGroup().location

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param name string

param logAnalyticsWorkspaceResourceId string

param securityRules array = []

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').networkSecurityGroup}-'

var ruleNamePrefix = '${loadJsonContent('../azResourceAbbreviations.json').nsgSecurityRules}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: resourceName
  location: location
  properties: {
    securityRules: [for rule in securityRules: {
      name: startsWith(rule.name, ruleNamePrefix) ? (endsWith(rule.name, nameSuffix) ? name : '${rule.name}${nameSuffix}') : (endsWith(rule.name, nameSuffix) ? '${ruleNamePrefix}${rule.name}' : '${ruleNamePrefix}${rule.name}${nameSuffix}')
      properties: rule.properties
    }]
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: nsg
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output id string = nsg.id
output name string = nsg.name
