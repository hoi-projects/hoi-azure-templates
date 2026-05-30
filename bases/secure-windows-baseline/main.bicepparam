using './main.bicep'

// azd reads this file. Set your values here before running azd up.
// adminPassword is read from the environment variable to avoid storing secrets in files.

param location = readEnvironmentVariable('AZURE_LOCATION', 'uksouth')
param prefix = 'hoi'
param windowsSku = '2025-datacenter-azure-edition'
param vmSize = 'Standard_B2s'
param adminUsername = 'azureuser'
param adminPassword = readEnvironmentVariable('VM_ADMIN_PASSWORD', '')
param enablePurgeProtection = false
