# HRL Azure Infrastructure

Terraform-managed Azure infrastructure for Healthy Rivers and Landscapes (HRL) data systems and public applications.

This repository contains Azure infrastructure code only. It currently supports the immediate need to deploy production infrastructure for a public restoration map, while leaving room for a larger HRL data system that can manage spatial, tabular, raster, model-output, metadata, and provenance workflows.

## Repository Status

This repository is in early setup. The first implemented component is `infra/bootstrap`, which creates Azure Blob Storage for future Terraform remote state.

The intended progression is:

1. Bootstrap Terraform state storage.
2. Configure separate remote state files for production components.
3. Deploy shared production foundation resources.
4. Deploy durable data storage and serving resources.
5. Deploy public map and application infrastructure.
6. Add ingestion, validation, and processing infrastructure as needed.

Do not apply Terraform from this repository unless you intend to create or modify Azure resources.

## Repository Structure

```text
README.md
.gitignore
LICENSE

infra/
  bootstrap/
    main.tf
    outputs.tf
    providers.tf
    variables.tf
    versions.tf
    terraform.tfvars.example

  environments/
    prod/
      core/
      data/
      pipelines/
      apps/

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

Some directories may start with placeholder README files until their Terraform components are implemented.

## Resource Groups

Production resource groups are organized by lifecycle, security, and operational boundary:

```text
rg-hrl-tfstate-prod-wus3
rg-hrl-core-prod-wus3
rg-hrl-data-prod-wus3
rg-hrl-pipelines-prod-wus3
rg-hrl-apps-prod-wus3
```

Use these boundaries consistently:

```text
rg-hrl-tfstate-prod-wus3
  Terraform state storage only.

rg-hrl-core-prod-wus3
  Shared foundation resources such as Key Vault, Log Analytics, managed identities, and shared diagnostics.

rg-hrl-data-prod-wus3
  Durable data resources such as ADLS Gen2 / Blob Storage, storage containers, and metadata or catalog stores.

rg-hrl-pipelines-prod-wus3
  Processing and ingestion resources such as Container Apps jobs, pipeline identities, queues, or batch resources.

rg-hrl-apps-prod-wus3
  Public and partner-facing applications such as Azure Static Web Apps for the public restoration map.
```

Do not create resource groups per scientific data type such as `spatial`, `tabular`, or `raster`. Data type organization belongs in storage paths, catalogs, metadata, and schemas.

## Naming and Tags

Use `westus3` as the default Azure region unless instructed otherwise.

Resource groups use:

```text
rg-<program>-<workload>-<environment>-<region>
```

Examples:

```text
rg-hrl-core-prod-wus3
rg-hrl-data-prod-wus3
rg-hrl-pipelines-prod-wus3
rg-hrl-apps-prod-wus3
```

Apply common tags consistently:

```hcl
project     = "Healthy Rivers and Landscapes"
environment = "prod"
workload    = "<workload>"
owner       = "HRL Program"
managed_by  = "terraform"
```

## State Strategy

This repository uses one GitHub repo, but it should not use one giant Terraform state.

Each major deployable component should have its own remote state, for example:

```text
prod-core.tfstate
prod-data.tfstate
prod-pipelines.tfstate
prod-apps.tfstate
```

The `infra/bootstrap` component is special. It creates the Azure storage account and blob container that will hold future remote state. Bootstrap may initially use local state, but state files must never be committed.

## Bootstrap

The `infra/bootstrap` component creates:

```text
rg-hrl-tfstate-prod-wus3
  Storage account for Terraform remote state
  Private blob container named tfstate
```

The storage account name includes a random suffix because Azure storage account names must be globally unique and lowercase.

Before running Terraform, install:

* Terraform 1.13 or newer
* Azure CLI
* Git

Confirm Azure CLI access:

```bash
az login
az account show
```

If you have access to multiple subscriptions, select the correct one:

```bash
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

Create a local bootstrap variables file from the committed example:

```bash
cp infra/bootstrap/terraform.tfvars.example infra/bootstrap/terraform.tfvars
```

Then edit `infra/bootstrap/terraform.tfvars` locally:

```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "westus3"
environment     = "prod"
```

The real `terraform.tfvars` file must not be committed.

From the repository root, format the bootstrap configuration:

```bash
terraform -chdir=infra/bootstrap fmt
```

The `-chdir=infra/bootstrap` option means "run Terraform as though the working directory were `infra/bootstrap`."

Initialize and validate:

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap validate
```

Create a plan:

```bash
terraform -chdir=infra/bootstrap plan -out bootstrap.tfplan
```

Review the plan carefully. Apply only when you are ready to create Azure resources:

```bash
terraform -chdir=infra/bootstrap apply bootstrap.tfplan
```

After bootstrap succeeds, record these outputs somewhere appropriate for project maintainers:

* `resource_group_name`
* `storage_account_name`
* `container_name`

Later Terraform components will use those values in an AzureRM backend configuration:

```hcl
backend "azurerm" {
  resource_group_name  = "<resource_group_name>"
  storage_account_name = "<storage_account_name>"
  container_name       = "<container_name>"
  key                  = "<component>.tfstate"
}
```

## Production Components

The first production components should be scaffolded under `infra/environments/prod`.

Suggested implementation order:

1. `prod/core`
   Shared resource group, Log Analytics Workspace, Key Vault, and managed identities if needed.

2. `prod/data`
   Durable ADLS Gen2 / Blob Storage resources and containers for raw submissions, standardized data, validation reports, metadata/catalog files, schema snapshots, and public exports.

3. `prod/apps`
   Azure Static Web Apps infrastructure for the production public restoration map.

4. `prod/pipelines`
   Future ingestion and processing infrastructure.

## Data Storage Concept

The durable data layer should support multiple scientific data types. Avoid naming infrastructure as if it only serves a single type of data.

Expected storage paths include:

```text
raw-submissions/
standardized/
  spatial/
  tabular/
  raster/
  model-outputs/
validation-reports/
metadata/
catalog/
public-exports/
schema-snapshots/
```

## Secrets and Sensitive Files

This repository is public. Do not commit:

* Secrets
* Real `.tfvars` files
* Terraform state
* Terraform plan files
* Azure credentials
* Storage keys
* Database passwords
* API keys
* Certificates or private keys
* Data files

The `.gitignore` should exclude:

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

Commit `terraform.tfvars.example` files when needed, but never commit real `.tfvars` files.

The `.terraform.lock.hcl` file should generally be committed so provider versions are consistent across machines. The `.terraform/` directory is a local cache and should not be committed.

## Pre-Commit Checks

Before committing Terraform changes, run:

```bash
terraform -chdir=infra/bootstrap fmt
terraform -chdir=infra/bootstrap validate
```

If validation fails because Terraform has not been initialized, run:

```bash
terraform -chdir=infra/bootstrap init
terraform -chdir=infra/bootstrap validate
```

Do not commit generated plans, state, real variable files, or local provider caches.

## License

See `LICENSE`.
