param name string

@allowed([
  'dev'
  'tst'
  'acc'
  'prd'
])
param environment string

param networkSecurityGroupName string

@description('''
Object holding the properties for the security rule; see https://learn.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?pivots=deployment-language-bicep for details
''')
param securityRuleProperties object

var namePrefix = '${loadJsonContent('../../azResourceAbbreviations.json').nsgSecurityRules}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource securityRule 'Microsoft.Network/networkSecurityGroups/securityRules@2022-11-01' = {
  name: resourceName
  parent: nsg
  properties: securityRuleProperties
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' existing = {
  name: networkSecurityGroupName
}
