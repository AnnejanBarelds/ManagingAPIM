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

param capacity int = 1

param vnetName string

param subnetName string

param vnetResourceGroupName string

param sslCertSecretName string

param apiManagementGatewayUrl string

param domainName string

param userAssignedIdentityId string

var apimHostName = environment == 'prd' ? 'api.${domainName}' : 'api-${environment}.${domainName}'

var keyVaultName = 'kv-core-example'

var keyVaultResourceGroupName = 'Core'

var namePrefix = '${loadJsonContent('../azResourceAbbreviations.json').applicationGateway}-'

var nameSuffix = '-${environment}'

var resourceName = startsWith(name, namePrefix) ? (endsWith(name, nameSuffix) ? name : '${name}${nameSuffix}') : (endsWith(name, nameSuffix) ? '${namePrefix}${name}' : '${namePrefix}${name}${nameSuffix}')

resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: resourceName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {
      }
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: capacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: vnet::subnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: ipAddress.outputs.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apimPool'
        properties: {
          backendAddresses: [
            {
              fqdn: replace(apiManagementGatewayUrl, 'https://', '')
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'apimHttpsSetting'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', resourceName, 'apimHealthProbe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'apimHealthProbe'
        properties: {
          pickHostNameFromBackendHttpSettings: true
          path: '/status-0123456789abcdef'
          port: 443
          protocol: 'Https'
          timeout: 30
          interval: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'apiListener'
        properties: {
          hostName: apimHostName
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', resourceName, 'appGatewayPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', resourceName, 'port_443')
          }
          protocol: 'Https'
          requireServerNameIndication: true
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', resourceName, 'agw-ssl-cert')
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'agw-ssl-cert'
        properties: {
          keyVaultSecretId: keyvault::sslCert.properties.secretUri
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'apimRoutingRule'
        properties: {
          ruleType: 'Basic'
          priority: 10
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', resourceName, 'apiListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', resourceName, 'apimPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', resourceName, 'apimHttpsSetting')
          }
        }
      }
    ]
    enableHttp2: true
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${resourceName}-diagnostic-setting'
  scope: appGateway
  properties: {
    workspaceId: logAnalyticsWorkspaceResourceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

module ipAddress 'publicIPAddress.bicep' = {
  name: '${deployment().name}-publicIp'
  params: {
    environment: environment
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    name: name
    location: location
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroupName)
  resource subnet 'subnets' existing = {
    name: subnetName
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
  scope: resourceGroup(keyVaultResourceGroupName)
  resource sslCert 'secrets@2023-02-01' existing = {
    name: sslCertSecretName
  }
}

output id string = appGateway.id
output name string = appGateway.name
