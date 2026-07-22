# Production Apps

This Terraform root manages production public and partner-facing application infrastructure for HRL.

Current resources:

```text
rg-hrl-apps-prod-wus3           Resource group in westus3
stapp-hrl-restoration-map-prod  Static Web App in westus2
afd-hrl-prod                    Shared Azure Front Door Standard/Premium profile
fde-hrl-prod                    Azure Front Door endpoint
waf-hrl-prod                    Azure Front Door WAF policy
```

This root is for application hosting only. Do not add data lake, database, pipeline, Terraform state, schema, or data artifact resources here.

Azure Static Web Apps is not currently available in every Azure region. The HRL apps resource group remains in `westus3`, while the Static Web App defaults to `westus2`, the nearest supported Azure Static Web Apps region.

## Public Routing

Azure Front Door is the shared public entry layer for independently deployed HRL applications. The initial route serves the restoration map:

| Public path | Origin | Origin request path |
| --- | --- | --- |
| `/restoration-map` | restoration map Static Web App | Redirects to `/restoration-map/` |
| `/restoration-map/` | restoration map Static Web App | `/` |
| `/restoration-map/assets/app.js` | restoration map Static Web App | `/assets/app.js` |
| `/restoration-map/data/projects.geojson` | restoration map Static Web App | `/data/projects.geojson` |

The route preserves query strings, so map state such as `?selected=<project-id>` continues to reach the application. It uses HTTPS to the origin and redirects HTTP requests to HTTPS. No Front Door cache block is configured initially; origin response headers determine caching behavior.

The endpoint does not route `/*` to the map. A future root landing page and independent routes such as `/science/*` can be added without changing the Front Door profile.

The WAF policy uses Microsoft managed default rules. Its SKU and enforcement mode are variables because DTS must confirm any required policy, logging, retention, bot-protection, and origin-bypass controls before public launch.

## Custom Domain and DTS Coordination

`hrl.water.ca.gov` is a DTS-managed DNS hostname. This root never manages the `water.ca.gov` zone or commits DNS validation values.

The initial configuration leaves `custom_domain_enabled = false`, allowing the Azure-generated `azurefd.net` hostname to be deployed and tested first. After DTS is ready to create records:

1. Set `custom_domain_enabled = true` in the local, ignored `terraform.tfvars` file and apply the change.
2. Retrieve the sensitive `custom_domain_validation_token` output and provide it to DTS with the TXT record name from `custom_domain_dns_validation_record_name`.
3. Ask DTS to create the DNS validation TXT record and CNAME record from `hrl.water.ca.gov` to `front_door_endpoint_hostname`.
4. Wait for Azure Front Door domain validation and managed certificate activation, then re-run Terraform if necessary.
5. Test `https://hrl.water.ca.gov/restoration-map/` after the Azure-generated endpoint works.

Do not enable the custom domain until DTS confirms that Azure Front Door, the selected WAF configuration, and public access are approved. The current default is Front Door Standard with the WAF in Prevention mode; change only after DTS guidance.

## Test Sequence

Before requesting DNS changes, test the generated endpoint output:

```text
https://<front-door-endpoint>.azurefd.net/restoration-map/
https://<front-door-endpoint>.azurefd.net/restoration-map/?selected=<valid-project>
https://<front-door-endpoint>.azurefd.net/restoration-map/data/hrl_restoration_projects.geojson
```

Confirm the map HTML, scripts, styles, data, boundaries, PMTiles resources, query-string state, and the no-trailing-slash redirect all work. The map application must first be deployed with the `/restoration-map/` public base path as tracked in `lucy-dwr/hrl-restoration-map` issue #2.

When adding another application, create a dedicated origin group, origin, route, and narrowly scoped rewrite rules in this root. Do not make the restoration map the permanent fallback for unmatched paths.

## Remote State

This root uses the AzureRM remote backend created by `infra/bootstrap`.

The state key for this component is:

```text
prod-apps.tfstate
```

The production backend settings are committed in:

```text
infra/backend-config/prod-apps.tfbackend
```

This file contains Azure resource names only. It does not contain credentials, access keys, deployment tokens, or secrets.

## Local Variables

Create a local variable file from the committed example:

```bash
cp infra/environments/prod/apps/terraform.tfvars.example infra/environments/prod/apps/terraform.tfvars
```

Edit `terraform.tfvars` locally with the real subscription ID. Do not commit real `.tfvars` files.

## Initialize

From the repository root, initialize this component with the committed production backend config:

```bash
terraform -chdir=infra/environments/prod/apps init -reconfigure -backend-config=../../../backend-config/prod-apps.tfbackend
```

The `-chdir=infra/environments/prod/apps` option means "run Terraform as though the working directory were `infra/environments/prod/apps`."

## Format and Validate

```bash
terraform -chdir=infra/environments/prod/apps fmt
terraform -chdir=infra/environments/prod/apps validate
```

If you need to validate syntax before configuring the remote backend, you can initialize without the backend:

```bash
terraform -chdir=infra/environments/prod/apps init -backend=false
terraform -chdir=infra/environments/prod/apps validate
```

## Plan

```bash
terraform -chdir=infra/environments/prod/apps plan -out prod-apps.tfplan
```

Review the plan before applying. Do not commit plan files.

## Apply

Apply only when you are ready to create or update Azure resources:

```bash
terraform -chdir=infra/environments/prod/apps apply prod-apps.tfplan
```

## Deployment Token

Do not output or commit the Azure Static Web Apps deployment token. When the map application repository is ready to deploy, store the deployment token as a GitHub Actions secret in the production application code repository.
