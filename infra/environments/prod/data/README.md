# Production Data

This Terraform root manages production durable data storage and serving infrastructure for HRL data artifacts.

Current resources:

```text
rg-hrl-data-prod-wus3  Resource group in westus3
ADLS Gen2 storage      Globally unique StorageV2 account with hierarchical namespace enabled
```

This root is for durable data resources only. Do not add public application hosting, Terraform state storage, or processing jobs here.

## Remote State

This root uses the AzureRM remote backend created by `infra/bootstrap`.

The state key for this component is:

```text
prod-data.tfstate
```

The production backend settings are committed in:

```text
infra/backend-config/prod-data.tfbackend
```

This file contains Azure resource names only. It does not contain credentials, access keys, deployment tokens, or secrets.

## Containers

The storage account creates these containers:

```text
raw-submissions      Private original submitted data files
standardized         Private curated analysis-ready data products
validation-reports   Private validation and QA/QC outputs
schema-snapshots     Private schema versions, validation profiles, and metadata snapshots
public-exports       Approved public-facing artifacts for browser and download access
```

The `standardized` container may hold vector, tabular, raster, model-output, and other data products. Do not create Azure resource groups or storage accounts per scientific data type.

## Public Exports

The initial public map convention inside `public-exports` is:

```text
restoration-map/
  restoration-projects/
    current/
      manifest.json

    v0.1.0/
      manifest.json
      hrl_restoration_projects.geojson
      hrl_restoration_projects.gpkg
      hrl_restoration_projects.csv
      validation_report.html
      validation_report.json
```

The map should load:

```text
https://<storage-account>.blob.core.windows.net/public-exports/restoration-map/restoration-projects/current/manifest.json
```

Versioned files should be treated as immutable. The `current/manifest.json` file is the mutable pointer to the latest approved bundle.

## Public Access

The default configuration sets `public_exports_access_type = "blob"` so approved blobs in `public-exports` can be fetched by browser code without secrets.

If policy does not allow anonymous blob access, set:

```hcl
public_exports_access_type = "private"
```

With private public exports, the map cannot fetch storage blobs directly from browser code. A later API or proxy layer will be required. Do not put storage account keys, SAS tokens, or other secrets in browser code.

## CORS

Set `allowed_cors_origins` to the production Static Web App origin and later the custom domain:

```hcl
allowed_cors_origins = [
  "https://<azure-static-web-app-default-hostname>",
]
```

CORS allows `GET`, `HEAD`, and `OPTIONS` with the headers needed for normal file fetches and ranged reads. Do not use `*` unless there is a documented reason.

## Cache Control

Terraform does not upload data artifacts in this component. Future upload workflows should set cache headers as follows:

```text
versioned files:
  public, max-age=31536000, immutable

current/manifest.json:
  no-cache
```

## Local Variables

Create a local variable file from the committed example:

```bash
cp infra/environments/prod/data/terraform.tfvars.example infra/environments/prod/data/terraform.tfvars
```

Edit `terraform.tfvars` locally with the real subscription ID and production map origin. Do not commit real `.tfvars` files.

## Initialize

From the repository root, initialize this component with the committed production backend config:

```bash
terraform -chdir=infra/environments/prod/data init -reconfigure -backend-config=../../../backend-config/prod-data.tfbackend
```

The `-chdir=infra/environments/prod/data` option means "run Terraform as though the working directory were `infra/environments/prod/data`."

## Format and Validate

```bash
terraform -chdir=infra/environments/prod/data fmt
terraform -chdir=infra/environments/prod/data validate
```

If you need to validate syntax before configuring the remote backend, you can initialize without the backend:

```bash
terraform -chdir=infra/environments/prod/data init -backend=false
terraform -chdir=infra/environments/prod/data validate
```

## Plan

```bash
terraform -chdir=infra/environments/prod/data plan -out prod-data.tfplan
```

Review the plan before applying. Do not commit plan files.

## Apply

Apply only when you are ready to create or update Azure resources:

```bash
terraform -chdir=infra/environments/prod/data apply prod-data.tfplan
```

## Manual Verification

After apply, verify that `rg-hrl-data-prod-wus3` exists, hierarchical namespace is enabled on the storage account, all expected containers exist, private containers are private, `public-exports` uses the selected access setting, and Blob service CORS includes the production map origin.
