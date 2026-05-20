# PostgreSQL Flexible Server with Private VNet Integration

Deploys Azure Database for PostgreSQL Flexible Server with private VNet integration and a private DNS zone.

## Resources Deployed

- **Microsoft.Network/virtualNetworks** — VNet with subnet delegated to PostgreSQL
- **Microsoft.Network/privateDnsZones** — Private DNS zone auto-derived from server name
- **Microsoft.Network/privateDnsZones/virtualNetworkLinks** — Links DNS zone to VNet
- **Microsoft.DBforPostgreSQL/flexibleServers** — PostgreSQL Flexible Server (versions 14, 15, 16)

## Deploy to Azure

[![Deploy to Azure](https://raw.githubusercontent.com/hoi-projects/hoi-azure-templates/main/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fhoi-projects%2Fhoi-azure-templates%2Fmain%2Fquickstarts%2Fmicrosoft.dbforpostgresql%2Fflexible-postgresql-with-vnet%2Fazuredeploy.json)

## Key Design Decisions

- SKU tier is auto-derived from SKU name — users cannot choose an incompatible pair
- DNS zone name is auto-derived from server name — no manual input needed
- Password minimum 12 characters (arm-ttk requirement)
- PostgreSQL versions 14, 15, 16 only (version 17+ not yet generally available)
- No AVM modules — plain Bicep resources only (required for Partner Center CUA auto-injection)

## Source of Truth

`main.bicep` is the source of truth. `azuredeploy.json` is a compiled output — do not edit it directly.

To rebuild:
```bash
az bicep build --file main.bicep --outfile azuredeploy.json
```

## Also Published On

This template is also listed on the Azure Marketplace:
- **hoiltd** Partner Center listing
- **alsourillc** Partner Center listing
