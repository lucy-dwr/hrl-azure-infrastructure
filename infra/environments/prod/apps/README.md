# Production Apps

This Terraform root manages production public and partner-facing application infrastructure for HRL.

Current resources:

```text
rg-hrl-apps-prod-wus3           Resource group in westus3
stapp-hrl-restoration-map-prod  Static Web App in westus2
```

This root is for application hosting only. Do not add data lake, database, pipeline, Terraform state, schema, or data artifact resources here.

Azure Static Web Apps is not currently available in every Azure region. The HRL apps resource group remains in `westus3`, while the Static Web App defaults to `westus2`, the nearest supported Azure Static Web Apps region.

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
