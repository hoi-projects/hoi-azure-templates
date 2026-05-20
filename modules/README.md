# HOI Reusable Modules

Reusable resource modules for composing larger templates. All modules use plain JSON/Bicep — no nested deployments, no registry references. Safe for Azure Marketplace (Partner Center CUA auto-injection compatible).

## Available Modules

| Module | Version | Description |
|--------|---------|-------------|
| [Microsoft.Compute/galleries/create](./Microsoft.Compute/galleries/create/1.0/) | 1.0 | Azure Compute Gallery (image factory) |
| [Microsoft.KeyVault/vaults](./Microsoft.KeyVault/vaults/1.0/) | 1.0 | Key Vault with access policies |
| [Microsoft.ManagedIdentity/user-assigned-identity-role-assignment](./Microsoft.ManagedIdentity/user-assigned-identity-role-assignment/1.0/) | 1.0 | User-assigned managed identity role assignment |

## Usage

Reference modules via relative path or raw GitHub URL:

```bicep
module gallery '../../modules/Microsoft.Compute/galleries/create/1.0/azuredeploy.json' = {
  name: 'gallery'
  params: { ... }
}
```

Or via raw GitHub URL (for Deploy to Azure button templates):
```
https://raw.githubusercontent.com/hoi-projects/hoi-azure-templates/main/modules/Microsoft.Compute/galleries/create/1.0/azuredeploy.json
```
