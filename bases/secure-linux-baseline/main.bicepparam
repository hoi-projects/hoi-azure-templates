using './main.bicep'

// azd reads this file. Set your values here before running azd up.
// adminPassword is read from the environment variable to avoid storing secrets in files.

param location = readEnvironmentVariable('AZURE_LOCATION', 'uksouth')
param prefix = 'hoi'
param ubuntuSku = '24_04-lts-gen2'
param vmSize = 'Standard_B2s_v2'
param adminUsername = 'azureuser'
param adminPassword = readEnvironmentVariable('VM_ADMIN_PASSWORD', '')
param enablePurgeProtection = false
