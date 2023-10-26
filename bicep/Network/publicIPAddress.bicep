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

@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Standard'

@allowed([
  'Dynamic'
  'Static'
])
param allocationMethod string = 'Static'

@allowed([
  'IPv4'
  'IPv6'
])
param addressVersion string = 'IPv4'

param dnsLabelPrefix string = ''

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').publicIpAddress}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

var properties = empty(dnsLabelPrefix) ? {
  publicIPAllocationMethod: allocationMethod
  publicIPAddressVersion: addressVersion
 } : {
  publicIPAllocationMethod: allocationMethod
  publicIPAddressVersion: addressVersion
  dnsSettings: {
    domainNameLabel: dnsLabelPrefix
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: resourceName
  location: location
  sku: {
    name: skuName 
  }
  properties: properties
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: publicIP
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = publicIP.id
output name string = publicIP.name
