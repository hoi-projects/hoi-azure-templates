@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Short prefix used to name all resources. 2–10 lowercase characters.')
@minLength(2)
@maxLength(10)
param prefix string = 'hoi'

@description('Windows SKU to deploy. Server editions for workloads; Windows 11 editions for desktop/developer use.')
@allowed([
  '2022-datacenter-azure-edition'
  '2025-datacenter-azure-edition'
  'win11-24h2-pro'
  'win11-24h2-ent'
])
param windowsSku string = '2025-datacenter-azure-edition'

@description('Azure VM size SKU. Must be available in the target region. Example: Standard_B2s_v2, Standard_D4s_v5.')
@minLength(1)
param vmSize string = 'Standard_B2s_v2'

@description('Administrator username for the Windows VM. Cannot be reserved words such as administrator, admin, or guest.')
@minLength(1)
@maxLength(20)
param adminUsername string = 'azureuser'

@description('Administrator password for the Windows VM. Must be 12–123 characters and meet Azure complexity requirements.')
@secure()
@minLength(12)
@maxLength(123)
param adminPassword string

@description('Enable Key Vault purge protection. Must be true for production workloads (MCSB DP-8). Set false only for testing — allows Key Vault deletion without waiting 90 days.')
param enablePurgeProtection bool = true

var addressPrefix = '10.0.0.0/16'
var resourcePrefix = toLower(prefix)

// Windows Desktop SKUs use a different publisher/offer than Server
var isDesktop = contains(windowsSku, 'win11')
var imageReference = isDesktop ? {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'windows-11'
  sku: windowsSku
  version: 'latest'
} : {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsSku
  version: 'latest'
}

// ── Diagnostics anchor ──────────────────────────────────────────────────────
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.11.1' = {
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    name: '${resourcePrefix}-law'
    location: location
    enableTelemetry: false
  }
}

// ── Outbound-only NAT Gateway (VM has no public IP) ─────────────────────────
module natGwPublicIp 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  name: 'natGwPublicIpDeployment'
  params: {
    name: '${resourcePrefix}-natgw-pip'
    location: location
    enableTelemetry: false
    diagnosticSettings: [
      {
        name: 'natGwPipDiagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
  }
}

module natGateway 'br/public:avm/res/network/nat-gateway:1.2.2' = {
  name: 'natGatewayDeployment'
  params: {
    name: '${resourcePrefix}-natgw'
    zone: 1
    enableTelemetry: false
    publicIpResourceIds: [
      natGwPublicIp.outputs.resourceId
    ]
  }
}

// ── NSG: RDP only from Bastion ───────────────────────────────────────────────
module nsgVM 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: 'nsgVmDeployment'
  params: {
    name: '${resourcePrefix}-nsg-vm'
    location: location
    enableTelemetry: false
    diagnosticSettings: [
      {
        name: 'nsgVmDiagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
    securityRules: [
      {
        name: 'AllowBastionRDP'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 100
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          access: 'Deny'
          direction: 'Inbound'
          priority: 4096
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// ── Virtual Network: 3 subnets ───────────────────────────────────────────────
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: 'virtualNetworkDeployment'
  params: {
    name: '${resourcePrefix}-vnet'
    location: location
    enableTelemetry: false
    addressPrefixes: [
      addressPrefix
    ]
    diagnosticSettings: [
      {
        name: 'vNetDiagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
    subnets: [
      {
        name: 'VMSubnet'
        addressPrefix: cidrSubnet(addressPrefix, 24, 0)
        natGatewayResourceId: natGateway.outputs.resourceId
        networkSecurityGroupResourceId: nsgVM.outputs.resourceId
      }
      {
        name: 'PrivateEndpointSubnet'
        addressPrefix: cidrSubnet(addressPrefix, 24, 1)
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: cidrSubnet(addressPrefix, 24, 2)
      }
    ]
  }
}

// ── Windows VM: no public IP, system-assigned managed identity ───────────────
module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.14.0' = {
  name: 'windowsVirtualMachineDeployment'
  params: {
    name: '${resourcePrefix}-vm'
    location: location
    enableTelemetry: false
    adminUsername: adminUsername
    adminPassword: adminPassword
    osType: 'Windows'
    vmSize: vmSize
    zone: 0
    imageReference: imageReference
    nicConfigurations: [
      {
        nicSuffix: '-nic-01'
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
          }
        ]
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ── Key Vault: RBAC model, VM identity can read secrets ─────────────────────
module keyVault 'br/public:avm/res/key-vault/vault:0.12.1' = {
  name: 'keyVaultDeployment'
  params: {
    name: '${uniqueString(resourceGroup().id)}-kv'
    location: location
    enableTelemetry: false
    enablePurgeProtection: enablePurgeProtection
    diagnosticSettings: [
      {
        name: 'keyVaultDiagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
    secrets: [
      {
        name: 'vmAdminPassword'
        value: adminPassword
      }
    ]
    roleAssignments: [
      {
        principalId: virtualMachine.outputs.systemAssignedMIPrincipalId!
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Key Vault Secrets User'
      }
    ]
  }
}

// ── Private DNS zone for blob storage ───────────────────────────────────────
module privateDnsBlob 'br/public:avm/res/network/private-dns-zone:0.7.1' = {
  name: 'privateDnsBlobDeployment'
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    location: 'global'
    enableTelemetry: false
    virtualNetworkLinks: [
      {
        name: '${virtualNetwork.outputs.name}-vnetlink'
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
      }
    ]
  }
}

// ── Storage Account: private endpoint, no public access, RBAC to VM ─────────
module storageAccount 'br/public:avm/res/storage/storage-account:0.19.0' = {
  name: 'storageAccountDeployment'
  params: {
    name: '${uniqueString(resourceGroup().id)}sa'
    location: location
    enableTelemetry: false
    skuName: 'Standard_LRS'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    diagnosticSettings: [
      {
        name: 'storageAccountDiagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
    blobServices: {
      containers: [
        {
          name: 'vmstorage'
          publicAccess: 'None'
        }
      ]
      roleAssignments: [
        {
          principalId: virtualMachine.outputs.systemAssignedMIPrincipalId!
          principalType: 'ServicePrincipal'
          roleDefinitionIdOrName: 'Storage Blob Data Contributor'
        }
      ]
    }
    privateEndpoints: [
      {
        service: 'blob'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[1]
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: privateDnsBlob.outputs.resourceId
            }
          ]
        }
      }
    ]
  }
}

// ── Bastion Host: secure inbound access, no exposed ports ───────────────────
module bastion 'br/public:avm/res/network/bastion-host:0.6.1' = {
  name: 'bastionDeployment'
  params: {
    name: '${resourcePrefix}-bastion'
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    skuName: 'Basic'
    location: location
    enableTelemetry: false
    diagnosticSettings: [
      {
        name: 'bastionDiagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
      }
    ]
  }
}

// ── Outputs ──────────────────────────────────────────────────────────────────
output vmResourceId string = virtualMachine.outputs.resourceId
output keyVaultResourceId string = keyVault.outputs.resourceId
output storageAccountResourceId string = storageAccount.outputs.resourceId
output vnetResourceId string = virtualNetwork.outputs.resourceId
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
