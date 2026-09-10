# Lambda CI/CD Demo

A minimal, production-shaped example of shipping a Go AWS Lambda function through a full
GitHub Actions CI/CD pipeline with Terraform-managed infrastructure across dev, staging,
and production environments.

## Structure

```
cmd/lambda/            Lambda entrypoint (main.go)
internal/handler/       Business logic + unit tests
infra/bootstrap/        One-time setup of the Terraform remote state backend
infra/modules/lambda-service/   Reusable Terraform module for the Lambda function
infra/environments/     Per-environment Terraform root configs (dev, staging, production)
scripts/build.sh        Compiles and zips the Lambda binary
scripts/smoke-test.sh   Invokes the deployed function and checks for a healthy response
.github/actions/build-lambda/   Composite action wrapping the build+test+package steps
.github/workflows/      CI/CD pipeline definitions
```

## Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `pr-validation.yml` | Pull request | `go vet`/`go test`, `terraform fmt`/`validate` |
| `build-publish.yml` | Push to `main` | Build + package the Lambda artifact, trigger dev deploy |
| `deploy.yml` | Manual / called by other workflows | `terraform apply` + smoke test for a given environment |
| `promote.yml` | Manual | Re-deploy a known-good artifact to the next environment |
| `rollback.yml` | Manual | Repoint the `live` alias to a previous Lambda version |
| `security-scan.yml` | PR, push to `main`, weekly | `gosec`, `trivy`, `tfsec` static analysis |

## Local development

```bash
go test ./...
./scripts/build.sh                 # produces dist/lambda.zip
```

## Deploying infrastructure manually

```bash
# One-time, per AWS account
cd infra/bootstrap
terraform init && terraform apply -var="state_bucket_name=<unique-bucket-name>"

# Per environment (after updating the backend "bucket" value)
cd infra/environments/dev
terraform init
terraform apply -var="artifact_path=../../../dist/lambda.zip" -var="app_version=$(git rev-parse HEAD)"
```

## Required repository configuration

- Secrets (set per GitHub Environment — `dev`, `staging`, `production`): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- Variables: `AWS_REGION` (optional, defaults to `us-east-1`), `ARTIFACT_S3_BUCKET` (optional, defaults to `demo-github-action-artifacts-bucket`)
- GitHub Environments: `dev`, `staging`, `production` — use required reviewers on `staging`/`production` for manual approval gates

> Static access keys are simpler to demo but are long-lived credentials. Rotate them regularly and scope the
> IAM user tightly (S3 put on the artifact bucket, Lambda create/update/get-function-url-config, IAM
> pass-role for the Lambda execution role, and DynamoDB/S3 access for the Terraform backend).
