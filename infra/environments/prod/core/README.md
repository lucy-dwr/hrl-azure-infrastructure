# Production Core

This Terraform root manages the minimal shared production foundation for Healthy Rivers and Landscapes (HRL).

Current resources:

```text
rg-hrl-core-prod-wus3    Resource group in westus3
Log Analytics workspace  Shared operational log destination with 30-day retention
```

This root intentionally does not create Key Vaults, managed identities, role assignments, or diagnostic settings. Those resources require an agreed access model and the Azure permissions to administer it. Add diagnostics settings only when a specific resource has defined logging and retention requirements.

## Remote State

This root uses the AzureRM remote backend created by `infra/bootstrap`.

The state key for this component is:

```text
prod-core.tfstate
```

The production backend settings are committed in:

```text
infra/backend-config/prod-core.tfbackend
```

This file contains Azure resource names only. It does not contain credentials, access keys, deployment tokens, or secrets.

## Local Variables

Create a local variables file from the committed example:

```bash
cp infra/environments/prod/core/terraform.tfvars.example infra/environments/prod/core/terraform.tfvars
```

Edit `terraform.tfvars` locally with the real subscription ID. Do not commit real `.tfvars` files.

## Initialize and Validate

From the repository root, initialize this component with the committed production backend config:

```bash
terraform -chdir=infra/environments/prod/core init -reconfigure -backend-config=../../../backend-config/prod-core.tfbackend
terraform -chdir=infra/environments/prod/core validate
```

To validate syntax before configuring the remote backend:

```bash
terraform -chdir=infra/environments/prod/core init -backend=false
terraform -chdir=infra/environments/prod/core validate
```

## Plan and Apply

```bash
terraform -chdir=infra/environments/prod/core fmt
terraform -chdir=infra/environments/prod/core plan -out prod-core.tfplan
```

Review the plan carefully. Apply only when you are ready to create or update Azure resources:

```bash
terraform -chdir=infra/environments/prod/core apply prod-core.tfplan
```
