You are helping build the `hrl-azure-infrastructure` repository.

This repo is public and will contain Terraform-managed Azure infrastructure for Healthy Rivers and Landscapes (HRL) data systems and public applications. The infrastructure should support the immediate need of deploying production infrastructure for a public restoration map, while leaving room for a larger scientific data system that can eventually handle spatial, tabular, raster, model-output, metadata, and provenance workflows.

Do not commit secrets, real `.tfvars` files, Terraform state, Terraform plan files, Azure credentials, storage keys, database passwords, API keys, certificates, private keys, or data files.

## Overall goal

Create a clean, production-oriented Terraform repository structure for Azure infrastructure.

This should support:

1. Terraform bootstrap state storage.
2. Shared production foundation resources.
3. Durable HRL data storage and serving.
4. Public application/map infrastructure.
5. Future ingestion/validation/data-processing pipelines.
6. LLM inference infrastructure (Microsoft Foundry / Azure AI Foundry).

Use Terraform, not Bicep.

## Resource group strategy

Organize Azure resource groups by lifecycle/security/operational boundary, not by scientific data type.

Use this target production structure:

```text
rg-hrl-tfstate-prod-wus3
rg-hrl-core-prod-wus3
rg-hrl-data-prod-wus3
rg-hrl-pipelines-prod-wus3
rg-hrl-apps-prod-wus3
rg-hrl-ai-prod-wus3
```

Meaning:

```text
rg-hrl-tfstate-prod-wus3
  Terraform state storage only.
  This is bootstrap/admin infrastructure.

rg-hrl-core-prod-wus3
  Shared foundation resources:
  - Key Vault
  - Log Analytics Workspace
  - Managed identities
  - Possibly Azure Container Registry later
  - Shared monitoring/diagnostic settings

rg-hrl-data-prod-wus3
  Durable data resources:
  - ADLS Gen2 / Blob Storage
  - Storage containers
  - Later: PostgreSQL Flexible Server + PostGIS
  - Later: metadata/catalog stores
  - Later: private endpoints/networking if needed

rg-hrl-pipelines-prod-wus3
  Processing/ingestion resources:
  - Azure Container Apps Jobs
  - Container Apps Environment
  - Pipeline managed identities
  - Later: queues/events/batch resources if needed

rg-hrl-apps-prod-wus3
  Public and partner-facing applications:
  - Azure Static Web Apps for the public map
  - Later: API hosting via Container Apps or App Service
  - Later: dashboards/catalog applications

rg-hrl-ai-prod-wus3
  LLM inference resources:
  - Microsoft Foundry (Azure AI Foundry) account
  - Foundry project(s)
  - Model deployment(s)
  - Dedicated Key Vault for this component's secrets
```

Do not create resource groups per data type such as `spatial`, `tabular`, or `raster`. Scientific data type organization should happen inside storage paths, catalogs, metadata, and schemas, not through Azure resource group boundaries.

## Naming convention

Use:

```text
rg-<program>-<workload>-<environment>-<region>
```

Examples:

```text
rg-hrl-core-prod-wus3
rg-hrl-data-prod-wus3
rg-hrl-pipelines-prod-wus3
rg-hrl-apps-prod-wus3
rg-hrl-ai-prod-wus3
```

Use tags consistently:

```hcl
project     = "Healthy Rivers and Landscapes"
environment = "prod"
workload    = "<workload>"
owner       = "HRL Program"
managed_by  = "terraform"
```

Use `westus3` as the default Azure region unless otherwise instructed.

## Repository structure

Create or update the repo to use this structure:

```text
README.md
.gitignore
LICENSE

infra/
  bootstrap/

  backend-config/
    prod-data.tfbackend
    prod-apps.tfbackend
    prod-ai.tfbackend

  environments/
    prod/
      core/
      data/
      pipelines/
      apps/
      ai/

    dev/
      core/
      data/
      pipelines/
      apps/

  modules/
    storage-account/
    key-vault/
    log-analytics/
    static-web-app/
    container-app-job/
    postgresql/

docs/
  deployment.md
  naming.md
  secrets-management.md
  environments.md
```

It is okay for some directories to contain placeholder README files if implementation will come later.

## Terraform state strategy

Use one GitHub repo, but avoid one giant Terraform state.

Each major deployable component should eventually have its own remote state, for example:

```text
prod-core.tfstate
prod-data.tfstate
prod-pipelines.tfstate
prod-apps.tfstate
prod-ai.tfstate
```

The `infra/bootstrap` component is special: it creates the Azure storage account/container that will hold future Terraform remote state. Bootstrap may initially use local state, but state files must not be committed.

## Important Git rules

Ensure `.gitignore` excludes:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfplan
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
```

Do not ignore `.terraform.lock.hcl`. That file should generally be committed.

Include `terraform.tfvars.example` files where needed, but never commit real `.tfvars`.

## Bootstrap component

The first implemented Terraform component should be `infra/bootstrap`.

It should create:

```text
rg-hrl-tfstate-prod-wus3
  Storage account for Terraform remote state
  Private blob container named tfstate
```

Use a random suffix for the storage account name because Azure storage account names must be globally unique and lowercase.

Expected files:

```text
infra/bootstrap/
  versions.tf
  providers.tf
  variables.tf
  main.tf
  outputs.tf
  terraform.tfvars.example
```

The AzureRM provider should accept the subscription ID as a variable:

```hcl
provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
```

`terraform.tfvars.example` should include a placeholder subscription ID:

```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "westus3"
environment     = "prod"
```

The real `terraform.tfvars` file should be created locally by the user and must not be committed.

## Initial production components

After bootstrap, the first production components should be scaffolded but not necessarily fully implemented.

Use these folders:

```text
infra/environments/prod/core/
infra/environments/prod/data/
infra/environments/prod/apps/
infra/environments/prod/pipelines/
infra/environments/prod/ai/
```

Suggested implementation order:

1. `prod/core`

   * Resource group
   * Log Analytics Workspace
   * Key Vault
   * Managed identities, if needed

2. `prod/data`

   * Resource group
   * ADLS Gen2 storage account
   * Storage containers for raw, standardized, validation reports, metadata/catalog, and public exports

3. `prod/apps`

   * Resource group
   * Azure Static Web App for the production public restoration map

4. `prod/pipelines`

   * Resource group
   * Later: Container Apps Environment
   * Later: Container Apps Jobs for validation/transformation

5. `prod/ai`

   * Resource group
   * Microsoft Foundry (Azure AI Foundry) account, project, and model deployment(s)
   * Dedicated Key Vault for this component's secrets

Do not implement PostGIS yet unless explicitly asked. Do not implement Container Apps pipeline jobs yet unless explicitly asked.

## Data storage concept

The durable data layer should eventually support multiple scientific data types.

Do not design storage solely around spatial data. Use storage paths like:

```text
raw-submissions/
standardized/
  vector/
  tabular/
  raster/
  model-outputs/
validation-reports/
metadata/
catalog/
public-exports/
schema-snapshots/
```

The immediate prototype will likely use a high-quality DWR GeoPackage, but the infrastructure should not be named as if it only supports spatial data.

## Public map context

There is an existing map application repo:

```text
https://github.com/lucy-dwr/hrl-restoration-map-prototype
```

Eventually this needs production Azure hosting. The likely first production app resource is Azure Static Web Apps, managed under:

```text
rg-hrl-apps-prod-wus3
```

Do not mix map application source code into this infrastructure repo. This repo should only contain infrastructure code and docs.

## Related repos

Existing related repos include:

```text
https://github.com/lucy-dwr/misc-restoration-spatial-data
https://github.com/lucy-dwr/hrl-restoration-map-prototype
https://github.com/lucy-dwr/hrl-restoration-schema
```

Keep responsibilities separate:

```text
hrl-restoration-schema
  Authoritative schema/model/vocabularies/docs.

misc-restoration-spatial-data
  First authoritative cleaned/validated restoration spatial dataset from provider submissions.

hrl-restoration-map-prototype
  Public React/TypeScript map application.

hrl-azure-infrastructure
  Azure infrastructure only.
```

## What not to do

Do not apply Terraform unless explicitly asked.

Do not create Azure resources unless explicitly asked.

Do not add secrets.

Do not commit `.tfvars`, `.tfstate`, or `.tfplan` files.

Do not put data files in this repo.

Do not over-specialize names around spatial data only.

Do not create many separate IaC repos. Use one repo with separate root Terraform configurations and separate states.

## Commands to document

The README or deployment docs should include examples like:

```bash
az login
az account show
```

For formatting:

```bash
terraform -chdir=infra/bootstrap fmt
```

For initialization and validation:

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap validate
```

For planning:

```bash
terraform -chdir=infra/bootstrap plan -out bootstrap.tfplan
```

For applying, only when the user is ready:

```bash
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
```

Also explain that `terraform -chdir=infra/bootstrap fmt` means “run Terraform as though the working directory were `infra/bootstrap`.”

## Deliverables for this coding task

Make a small, clean first commit-ready repo update that includes:

1. Correct folder structure.
2. Terraform-safe `.gitignore`.
3. Bootstrap Terraform files.
4. `terraform.tfvars.example`.
5. README updates explaining repo purpose, structure, secrets policy, and bootstrap workflow.
6. Basic docs stubs for naming, deployment, secrets management, and environments.
7. No secrets and no real local environment values.

Before finishing, run:

```bash
terraform -chdir=infra/bootstrap fmt
terraform -chdir=infra/bootstrap validate
```

If `validate` cannot run because Terraform is not initialized, report that clearly and do not fake success.
