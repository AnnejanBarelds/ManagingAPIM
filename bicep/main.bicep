targetScope = 'subscription'

param location string = deployment().location

@allowed([
  'dev'
  'tst'
])
param environment string

param name string = 'apimdemo'

@allowed([
  '1'
  '0'
])
param vnetExistsResult string = '1'

param addressSpacePrefix string

param appGatewaySslCertSecretName string = 'agw-ssl-cert'

param appGatewayPublicDomainName string = 'example.com'

var rgNamePrefix = '${loadJsonContent('azResourceAbbreviations.json').resourceGroup}-'

var rgNameSuffix = '-${environment}'

var rgName = startsWith(name, rgNamePrefix) ? (endsWith(name, rgNameSuffix) ? name : '${name}${rgNameSuffix}') : (endsWith(name, rgNameSuffix) ? '${rgNamePrefix}${name}' : '${rgNamePrefix}${name}${rgNameSuffix}')

var apimSubnetName = 'apim-${name}'

var privateEndpointSubnetName = 'pe-${name}'

var aspSubnetName = 'asp-${name}'

var appGatewaySubnetName = 'agw-${name}'

var vnetExists = vnetExistsResult == '1'

var deploymentKvName = 'kv-core-example'

var deploymentKvResourceGroupName = 'Core'

var apimNsgSecurityRules = [
  {
    name: 'Management_endpoint_for_Azure_portal_and_Powershell'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3443'
      sourceAddressPrefix: 'ApiManagement'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'Dependency_on_Redis_Cache'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '6380-6383'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
  {
    name: 'Dependency_to_sync_Rate_Limit_Inbound'
    properties: {
      protocol: 'Udp'
      sourcePortRange: '*'
      destinationPortRange: '4290'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 120
      direction: 'Inbound'
    }
  }
  {
    name: 'Azure_Infrastucture_Load_Balancer'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '6390'
      sourceAddressPrefix: 'AzureLoadBalancer'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 130
      direction: 'Inbound'
    }
  }
  {
    name: 'Dependency_on_Azure_SQL'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '1433'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Sql'
      access: 'Allow'
      priority: 100
      direction: 'Outbound'
    }
  }
  {
    name: 'Dependency_for_Log_to_event_Hub_policy'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRanges: [
        '5671'
        '5672'
        '443'
      ]
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'EventHub'
      access: 'Allow'
      priority: 110
      direction: 'Outbound'
    }
  }
  {
    name: 'Dependency_on_Redis_Cache_outbound'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '6380-6383'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 120
      direction: 'Outbound'
    }
  }
  {
    name: 'Dependency_To_sync_RateLimit_Outbound'
    properties: {
      protocol: 'Udp'
      sourcePortRange: '*'
      destinationPortRange: '4290'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 130
      direction: 'Outbound'
    }
  }
  {
    name: 'Dependency_on_Azure_File_Share_for_GIT'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '445'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Storage'
      access: 'Allow'
      priority: 140
      direction: 'Outbound'
    }
  }
  {
    name: 'Publish_DiagnosticLogs_And_Metrics'
    properties: {
      description: 'API Management logs and metrics for consumption by admins and your IT team are all part of the management plane'
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureMonitor'
      access: 'Allow'
      priority: 150
      direction: 'Outbound'
      destinationPortRanges: [
        '443'
        '1886'
      ]
    }
  }
  {
    name: 'Authenticate_To_Azure_Active_Directory'
    properties: {
      description: 'Connect to Azure Active Directory for developer portal authentication or for OAuth 2 flow during any proxy authentication'
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureActiveDirectory'
      access: 'Allow'
      priority: 160
      direction: 'Outbound'
      destinationPortRange: '443'
    }
  }
  {
    name: 'Dependency_on_Azure_Storage'
    properties: {
      description: 'APIM service dependency on Azure blob and Azure table storage'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Storage'
      access: 'Allow'
      priority: 170
      direction: 'Outbound'
    }
  }
  {
    name: 'Access_KeyVault'
    properties: {
      description: 'Allow API Management service control plane access to Azure Key Vault to refresh secrets'
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureKeyVault'
      access: 'Allow'
      priority: 180
      direction: 'Outbound'
      destinationPortRange: '443'
    }
  }
  {
    name: 'Authorizations_dependency'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureConnectors'
      access: 'Allow'
      priority: 190
      direction: 'Outbound'
      destinationPortRange: '443'
    }
  }
  {
    name: 'Deny_All_Internet_Outbound'
    properties: {
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Internet'
      access: 'Deny'
      priority: 999
      direction: 'Outbound'
    }
  }
]

var appGatewayNsgSecurityRules = [
  {
    name: 'Gateway_Manager_Required_Ports'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '65200-65535'
      sourceAddressPrefix: 'GatewayManager'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 100
      direction: 'Inbound'
    }
  }
  {
    name: 'Web_Traffic'
    properties: {
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRanges: [
        '80'
        '443'
      ]
      sourceAddressPrefix: '*'
      destinationAddressPrefix: '*'
      access: 'Allow'
      priority: 110
      direction: 'Inbound'
    }
  }
]

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

module vnet 'Network/virtualNetwork.bicep' = if(!vnetExists) {
  scope: resourceGroup
  name: '${deployment().name}-vnet'
  params: {
    environment: environment
    location: location
    name: name
    addressPrefixes: [
      '${addressSpacePrefix}.0.0/16'
    ]
  }
}

resource existingVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = if (vnetExists) {
  scope: resourceGroup
  name: 'vnet-${name}-${environment}'
}

module law 'OperationalInsights/workspaces.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-law'
  params: {
    environment: environment
    location: location
    name: name
  }
}

module apimRouteTable 'Network/routeTable.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-apimRouteTable'
  params: {
    name: 'apim'
    location: location
    environment: environment
    routes: [
      {
        name: 'ApiManagement'
        properties: {
          nextHopType: 'Internet'
          addressPrefix: 'ApiManagement'
        }
      }
    ]
  }
}

module apimSubnet 'Network/virtualNetworks/subnet.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-apimSubnet'
  params: {
    location: location
    addressPrefix: '${addressSpacePrefix}.0.0/24'
    environment: environment
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: apimSubnetName
    vnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    routeTableName: apimRouteTable.outputs.name
    privateEndpointNetworkPolicies: 'Enabled'
    nsgSecurityRules: apimNsgSecurityRules
    serviceEndpoints: [
      'Microsoft.Storage'
      'Microsoft.Sql'
      'Microsoft.EventHub'
      'Microsoft.KeyVault'
    ]
  }
}

module privateEndpointSubnet 'Network/virtualNetworks/subnet.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-privateEndpointSubnet'
  params: {
    environment: environment
    addressPrefix: '${addressSpacePrefix}.1.0/24'
    name: privateEndpointSubnetName
    vnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    privateEndpointNetworkPolicies: 'Enabled'
    logAnalyticsWorkspaceResourceId: law.outputs.id
    location: location

  }
  dependsOn: [
    apimSubnet
  ]
}

module appServiceSubnet 'Network/virtualNetworks/subnet.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-appServiceSubnet'
  params: {
    environment: environment
    addressPrefix: '${addressSpacePrefix}.2.0/24'
    name: aspSubnetName
    vnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    delegations: [
      {
        name: 'Microsoft.Web.serverFarms'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    serviceEndpoints: [
      'Microsoft.Storage'
      'Microsoft.ServiceBus'
      'Microsoft.KeyVault'
      'Microsoft.Web'
    ]
    logAnalyticsWorkspaceResourceId: law.outputs.id
    location: location
  }
  dependsOn: [
    privateEndpointSubnet
  ]
}

module appGwSubnet 'Network/virtualNetworks/subnet.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-agwSubnet'
  params: {
    environment: environment
    addressPrefix: '${addressSpacePrefix}.3.0/24'
    name: appGatewaySubnetName
    vnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    routeTableName: appGatewayRouteTable.outputs.name
    logAnalyticsWorkspaceResourceId: law.outputs.id
    nsgSecurityRules: appGatewayNsgSecurityRules
    location: location
  }
  dependsOn: [
    appServiceSubnet
  ]
}

module serverFarm 'Web/serverFarm.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-serverFarm'
  params: {
    name: name
    location: location
    environment: environment
    logAnalyticsWorkspaceResourceId: law.outputs.id
  }
}

module websitesPrivateDnsZone 'Network/privateDnsZone.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-websitesPrivateDnsZone'
  params: {
    name: 'privatelink.azurewebsites.net'
    vnetsToLink: [
      {
        name: vnetExists ? existingVnet.name : vnet.outputs.name
        resourceGroupName: resourceGroup.name
        subscriptionId: subscription().subscriptionId
      }
    ]
  }
}

module kvPrivateDnsZone 'Network/privateDnsZone.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-kvPrivateDnsZone'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    vnetsToLink: [
      {
        name: vnetExists ? existingVnet.name : vnet.outputs.name
        resourceGroupName: resourceGroup.name
        subscriptionId: subscription().subscriptionId
      }
    ]
  }
}

module keyVault 'KeyVault/keyVault.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-keyVault'
  params: {
    name: name
    location: location
    environment: environment
    logAnalyticsWorkspaceResourceId: law.outputs.id
    dnsZoneId: kvPrivateDnsZone.outputs.id
    privateEndpointVnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    privateEndpointSubnetName: privateEndpointSubnet.outputs.name
    privateEndpointVnetResourceGroupName: resourceGroup.name
  }
}

module apim 'ApiManagement/service.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-apim'
  params: {
    environment: environment
    location: location
    keyVaultName: keyVault.outputs.name
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: name
    privateDnsZonesResourceGroupName: resourceGroup.name
    privateDnsZonesSubscriptionId: subscription().subscriptionId
    subnetName: apimSubnet.outputs.name
    vnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    vnetResourceGroupName: resourceGroup.name
  }
}

module appGateway 'Network/applicationGateway.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-agw'
  params: {
    environment: environment
    logAnalyticsWorkspaceResourceId: law.outputs.id
    name: name
    subnetName: appGwSubnet.outputs.name
    vnetName: vnetExists ? existingVnet.name : vnet.outputs.name
    vnetResourceGroupName: resourceGroup.name
    location: location
    apiManagementGatewayUrl: replace(apim.outputs.gatewayUrl, 'https://', '')
    sslCertSecretName: appGatewaySslCertSecretName
    userAssignedIdentityId: appGatewayUserAssignedIdentity.outputs.id
    domainName: appGatewayPublicDomainName
  }
  dependsOn: [
    certPermission
  ]
}

module appGatewayUserAssignedIdentity 'ManagedIdentity/userAssignedIdentity.bicep' = {
  name: '${deployment().name}-id'
  scope: resourceGroup
  params: {
    environment: environment
    location: location
    name: 'agw-${name}-${environment}'
  }
}

module certPermission 'Authorization/roleAssignmentKeyVaultSecret.bicep' = {
  name: '${deployment().name}-certPermission'
  scope: az.resourceGroup(deploymentKvResourceGroupName)
  params: {
    keyVaultName: deploymentKvName
    principalId: appGatewayUserAssignedIdentity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleName: 'KeyVaultSecretsUser'
    secretName: appGatewaySslCertSecretName
  }
}

module appGatewayRouteTable 'Network/routeTable.bicep' = {
  scope: resourceGroup
  name: '${deployment().name}-agwrt'
  params: {
    name: 'appGatewayRouteTable'
    location: location
    environment: environment
    routes: [
      {
        name: 'ApplicationGateway'
        properties: {
          nextHopType: 'Internet'
          addressPrefix: '0.0.0.0/0'
        }
      }
    ]
  }
}
