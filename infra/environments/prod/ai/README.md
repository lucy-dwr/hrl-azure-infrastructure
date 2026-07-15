# Production AI

This Terraform root manages production LLM inference infrastructure: a Microsoft Foundry (Azure AI Foundry) account, project, and model deployment.

Current resources:

```text
rg-hrl-ai-prod-wus3   Resource group in westus3
Foundry account       Cognitive Services account, kind = AIServices, project management enabled
Foundry project       Project within the account
Model deployment      A single model deployment (currently claude-sonnet-5, GlobalStandard SKU)
Key Vault             Provisioned for this component's secrets; not currently populated
```

This root is for LLM inference resources only. Do not add data lake, database, pipeline, Terraform state, or application hosting resources here.

## Remote State

This root uses the AzureRM remote backend created by `infra/bootstrap`.

The state key for this component is:

```text
prod-ai.tfstate
```

The production backend settings are committed in:

```text
infra/backend-config/prod-ai.tfbackend
```

This file contains Azure resource names only. It does not contain credentials, access keys, deployment tokens, or secrets.

## Providers

This root uses both `azurerm` and `azapi`. `azapi` is required specifically for the model deployment resource: as of writing, `azurerm_cognitive_deployment` has no argument for the `modelProviderData` field that the Azure API requires for third-party (e.g. Anthropic) model deployments. See [hashicorp/terraform-provider-azurerm#31140](https://github.com/hashicorp/terraform-provider-azurerm/issues/31140). The deployment resource in `main.tf` uses `azapi_resource` directly against the underlying ARM API as a workaround; every other resource in this root uses `azurerm`. If that provider gap closes upstream, the deployment resource can move back to `azurerm_cognitive_deployment`.

## Model Provider Data

Third-party model deployments (e.g. Anthropic) require organization identifying information — `organizationName`, `industry`, and `countryCode` — that Azure passes to the model provider for their own marketplace terms. These are set via `model_provider_organization_name`, `model_provider_industry`, and `model_provider_country_code` in `variables.tf`, with defaults matching this repository's existing tag values. Override them in `terraform.tfvars` if a different deployment needs different values.

## Key Vault

A Key Vault is provisioned in this resource group (RBAC-authorized, not access-policy-based) for storing secrets related to this component, such as the Foundry account's API key. It is not currently populated. Populating it and granting read access to consuming applications is a planned follow-up, not yet automated by this root.

## Local Variables

Create a local variable file from the committed example:

```bash
cp infra/environments/prod/ai/terraform.tfvars.example infra/environments/prod/ai/terraform.tfvars
```

Edit `terraform.tfvars` locally with the real subscription ID. Do not commit real `.tfvars` files.

## Initialize

From the repository root, initialize this component with the committed production backend config:

```bash
terraform -chdir=infra/environments/prod/ai init -reconfigure -backend-config=../../../backend-config/prod-ai.tfbackend
```

The `-chdir=infra/environments/prod/ai` option means "run Terraform as though the working directory were `infra/environments/prod/ai`."

## Format and Validate

```bash
terraform -chdir=infra/environments/prod/ai fmt
terraform -chdir=infra/environments/prod/ai validate
```

If you need to validate syntax before configuring the remote backend, you can initialize without the backend:

```bash
terraform -chdir=infra/environments/prod/ai init -backend=false
terraform -chdir=infra/environments/prod/ai validate
```

## Plan

```bash
terraform -chdir=infra/environments/prod/ai plan -out ai.tfplan
```

Review the plan before applying. Do not commit plan files.

## Apply

Apply only when you are ready to create or update Azure resources:

```bash
terraform -chdir=infra/environments/prod/ai apply ai.tfplan
```

## Quota

Model deployments draw from per-model, per-region quota that exists independently of this Terraform config. Before raising `deployment_capacity` in `variables.tf`, check current usage:

```bash
az cognitiveservices usage list --location westus3
```

## Manual Verification

After apply, verify that `rg-hrl-ai-prod-wus3` exists, the Foundry account's `project_management_enabled` is `true`, the model deployment shows `provisioningState: Succeeded` and `deploymentState: Running`, and the Key Vault exists with RBAC authorization enabled.
