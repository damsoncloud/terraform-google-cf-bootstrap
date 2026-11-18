# GitHub Actions integration

Submodule of [cf-bootstrap](../../README.md) setting up Workload Identity Federation for GitHub Actions in the bootstrap project:

* a pool and an OIDC provider trusting only the given GitHub organisation, by its immutable ID,
* the Cloud Foundations repositories impersonating `tf-plan` from any ref and `tf-bootstrap` from the default branch,
* the workload repositories impersonating their environment's deployer from any ref.

It is called by cf-bootstrap when its `github` input is set.

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| default\_branch\_name | Default branch of the Cloud Foundations repositories, the only ref impersonating `tf-bootstrap`. | `string` | `"main"` | no |
| foundation\_repository\_ids | IDs of the Cloud Foundations repositories, impersonating `tf-plan` from any ref and `tf-bootstrap` from the default branch. | `list(string)` | `[]` | no |
| name\_prefix | Prefix of the pool's and provider's IDs, `<prefix>-gh` and `<prefix>-gha`, e.g. `cmn-cf-bootstrap`. | `string` | n/a | yes |
| project\_id | ID of the project holding the Workload Identity Federation pool, e.g. the bootstrap project. | `string` | n/a | yes |
| repository\_owner\_id | ID of the GitHub organisation, the only one trusted. | `string` | n/a | yes |
| tf\_bootstrap\_service\_account | Resource name of the `tf-bootstrap` service account, `projects/<project>/serviceAccounts/<email>`. | `string` | n/a | yes |
| tf\_environment\_service\_accounts | Resource names of the environment deployer service accounts, by environment folder name. | `map(string)` | `{}` | no |
| tf\_plan\_service\_account | Resource name of the `tf-plan` service account, `projects/<project>/serviceAccounts/<email>`. | `string` | n/a | yes |
| workload\_repository\_ids | IDs of the workload repositories, by environment folder name, impersonating the environment's deployer from any ref. | `map(list(string))` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| workload\_identity\_provider | Name of the Workload Identity Federation provider, for `google-github-actions/auth`. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->
