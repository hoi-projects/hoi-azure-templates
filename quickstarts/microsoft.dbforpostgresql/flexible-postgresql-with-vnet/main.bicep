@description('Server Name for Azure database for PostgreSQL Flexible Server')
@minLength(3)
@maxLength(63)
param serverName string

@description('Database administrator login name')
@minLength(1)
param administratorLogin string

@description('Database administrator password')
@minLength(12)
@secure()
param administratorLoginPassword string

@description('Azure database for PostgreSQL SKU name')
@allowed([
  'Standard_B1ms'
  'Standard_B2s'
  'Standard_B2ms'
  'Standard_B4ms'
  'Standard_D2ds_v4'
  'Standard_D4ds_v4'
  'Standard_D8ds_v4'
  'Standard_E2ds_v4'
  'Standard_E4ds_v4'
  'Standard_E8ds_v4'
])
param skuName string = 'Standard_D2ds_v4'

@description('Azure database for PostgreSQL storage size (GB)')
param storageSizeGB int = 32

@description('PostgreSQL version')
@allowed([
  '14'
  '15'
  '16'
])
param postgresqlVersion string = '16'

@description('Location for all resources')
param location string = resourceGroup().location

@description('PostgreSQL Server backup retention days')
@minValue(7)
@maxValue(35)
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string = 'Disabled'

@description('High availability mode for PostgreSQL Flexible Server')
@allowed([
  'Disabled'
  'ZoneRedundant'
  'SameZone'
])
param highAvailability string = 'Disabled'

@description('Virtual Network Name')
param virtualNetworkName string = 'vnet-postgresql'

@description('Subnet Name')
param subnetName string = 'snet-postgresql'

@description('Virtual Network Address Prefix')
param vnetAddressPrefix string = '10.0.0.0/24'

@description('Subnet Address Prefix')
param postgresqlSubnetPrefix string = '10.0.0.0/28'

// Derive SKU tier from SKU name — prevents user from choosing incompatible pairs
var skuTierMap = {
  Standard_B1ms: 'Burstable'
  Standard_B2s: 'Burstable'
  Standard_B2ms: 'Burstable'
  Standard_B4ms: 'Burstable'
  Standard_D2ds_v4: 'GeneralPurpose'
  Standard_D4ds_v4: 'GeneralPurpose'
  Standard_D8ds_v4: 'GeneralPurpose'
  Standard_E2ds_v4: 'MemoryOptimized'
  Standard_E4ds_v4: 'MemoryOptimized'
  Standard_E8ds_v4: 'MemoryOptimized'
}
var skuTier = skuTierMap[skuName]

// Auto-derive private DNS zone name from server name
var dnsZoneFqdn = '${serverName}.private.postgres.database.azure.com'

resource vnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }

  resource subnet 'subnets' = {
    name: subnetName
    properties: {
      addressPrefix: postgresqlSubnetPrefix
      delegations: [
        {
          name: 'dlg-Microsoft.DBforPostgreSQL-flexibleServers'
          properties: {
            serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
          }
        }
      ]
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
    }
  }
}

resource dnszone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneFqdn
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: virtualNetworkName
  parent: dnszone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource postgresqlDbServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGB
    }
    createMode: 'Default'
    version: postgresqlVersion
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: highAvailability
    }
    network: {
      delegatedSubnetResourceId: vnet::subnet.id
      privateDnsZoneArmResourceId: dnszone.id
    }
  }
  dependsOn: [
    vnetLink
  ]
}

output postgreSQLHostname string = '${serverName}.${dnszone.name}'
output postgreSQLSubnetId string = vnet::subnet.id
output vnetId string = vnet.id
output privateDnsId string = dnszone.id
output privateDnsName string = dnszone.name
