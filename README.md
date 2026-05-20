# HOI Azure Templates

Public library of Azure ARM/Bicep templates maintained by **Hoi Ltd** and **Al-Souri LLC**.

> **Source of truth is always Bicep.** JSON files are compiled outputs — never edit them directly.

## Deploy to Azure

Each quickstart folder contains a **Deploy to Azure** button that launches the template directly in the Azure Portal. This allows one-click deployments from this repo, independent of Marketplace listings.

---

## Repository Structure

```
├── modules/                        # Reusable resource modules (plain JSON + Bicep)
│   ├── Microsoft.Compute/
│   │   └── galleries/create/1.0/
│   ├── Microsoft.KeyVault/
│   │   └── vaults/1.0/
│   └── Microsoft.ManagedIdentity/
│       └── user-assigned-identity-role-assignment/1.0/
│
└── quickstarts/                    # End-to-end deployment templates
    └── microsoft.dbforpostgresql/
        └── flexible-postgresql-with-vnet/
```

---

## Quickstarts

| Template | Description | Deploy |
|----------|-------------|--------|
| [PostgreSQL Flexible + VNet](./quickstarts/microsoft.dbforpostgresql/flexible-postgresql-with-vnet/) | PostgreSQL Flexible Server with private VNet integration | [![Deploy to Azure](https://raw.githubusercontent.com/hoi-projects/hoi-azure-templates/main/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhoi-projects%2Fhoi-azure-templates%2Fmain%2Fquickstarts%2Fmicrosoft.dbforpostgresql%2Fflexible-postgresql-with-vnet%2Fazuredeploy.json) |

---

## Engineering Rules

1. **Never start from scratch** — always adapt from an existing template.
2. **Source of truth is Bicep** — always compile `main.bicep` → `azuredeploy.json` + `mainTemplate.json`.
3. **Never create `createUiDefinition.json` from scratch** — use the quickstart version as guidance.
4. **Never edit JSON directly** — decompile to Bicep first, work on Bicep, then compile.
5. **Validate `createUiDefinition.json` before every upload** — use the portal sandbox or `sideload-createuidef.sh`.

---

## Partner Center Notes

- These templates are also used as Azure Marketplace listings.
- **hoiltd** pid: `pid-e43bacc0-e222-4e70-8f0c-153a6ce2fb28-partnercenter`
- **alsourillc** pid: `pid-aedd40b0-502e-41a1-bc17-3ca137d5cb22-partnercenter`
- Do **not** use AVM registry modules (`br/public:avm/...`) in Marketplace templates — they produce nested deployments that break CUA auto-injection.
- Use plain Bicep resource declarations only.

---

## Contributing

Maintained by the HOI engineering team. All templates follow the [Azure Quickstart Templates contribution guide](https://github.com/Azure/azure-quickstart-templates/blob/master/1-CONTRIBUTION-GUIDE/README.md) conventions.
