param name string

param ipAddresses array

param privateDnsZoneName string

resource record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
    name: name
    parent: privateDnsZone
    properties: {
      ttl: 3600
      aRecords: [for ipAddress in ipAddresses: {
          ipv4Address: ipAddress
      }]
    }
  }

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}
