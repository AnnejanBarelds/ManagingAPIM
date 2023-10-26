param vnetRouteAllEnabled bool = true

param linuxFxVersion string

param siteName string

@description('''
A `subnetsToWhitelist` object contains a `resourceGroup`, `vnet`, `subnet`
''')
param subnetsToWhitelist array

@description('''
Contains IP addresses in CIDR notation. Single IP addresses should be represented as a /32 CIDR
''')
param ipAddressesToWhitelist array

var virtualNetworkRestrictions = [for (subnet, i) in subnetsToWhitelist: {
  action: 'Allow'
  name: take('Allow_${i + 1}_${replace(subnet.subnet, '-', '')}', 32)
  priority: (i + 1) * 100
  vnetSubnetResourceId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${subnet.resourceGroup}/providers/Microsoft.Network/virtualNetworks/${subnet.vnet}/subnets/${subnet.subnet}'
}]

var ipRestrictions = [for (ip, i) in ipAddressesToWhitelist: {
  action: 'Allow'
  name: take('Allow_${i + 1}_${replace(replace(ip, '.', ''), '/', '')}', 32)
  priority: (i + 100) * 100
  ipaddress: ip
}]

resource ipWhitelist 'Microsoft.Web/sites/config@2022-09-01' = {
  name: '${siteName}/web'
  properties: {
    alwaysOn: true
    ipSecurityRestrictions: union(virtualNetworkRestrictions, ipRestrictions)
    scmIpSecurityRestrictionsUseMain: true
    linuxFxVersion: linuxFxVersion
    vnetRouteAllEnabled: vnetRouteAllEnabled
    http20Enabled: true
  }
}
