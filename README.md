# Damson Cloud GCP Cloud Foundations: bootstrap

Terraform module of the Damson Cloud GCP Cloud Foundations creating the bootstrap of a Google Cloud organisation:

* the bootstrap project and the foundations' Terraform state bucket,
* the `tf-bootstrap` (apply) and `tf-plan` (plan) service accounts, and a deployer service account (`tf-<env>`) with a state bucket per environment,
* the billing grants and the organisation roles of `tf-bootstrap`,
* GitHub Workload Identity Federation trusting only the listed repositories.

The module is applied in the same Terraform state as [`cf-hierarchy`](https://registry.terraform.io/modules/damsoncloud/cf-hierarchy/google).

## Usage

```hcl
module "bootstrap" {
  source  = "damsoncloud/cf-bootstrap/google"
  version = "X.Y.Z"

  # Inputs are documented once the module's first version is released.
}
```

Pin an exact version. New versions are published as immutable GitHub releases with `vX.Y.Z` tags, following [semantic versioning](https://semver.org/).

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| billing\_account | ID of the billing account of the bootstrap project, e.g. `012345-6789AB-CDEF01`. | `string` | n/a | yes |
| billing\_admins\_group | Email of the group administering the billing account, e.g. `gcp-billing-admins@example.com`. No group is granted when null. | `string` | `null` | no |
| environments | Short names of the environments, by environment folder name, e.g. the cf-hierarchy environments. Each environment gets a `tf-<short name>` deployer service account with its own state bucket. | `map(string)` | ```{ "certification": "cert", "common": "cmn", "development": "dev", "production": "prod" }``` | no |
| folder\_id | The `common` folder holding the bootstrap project, as `folders/<id>`, e.g. the `folders["common"]` output of cf-hierarchy. | `string` | n/a | yes |
| organization\_id | ID of the organisation, where the deployer service accounts are granted their roles. | `string` | n/a | yes |
| project\_id | ID of the bootstrap project. Generated as `cmn-cf-bootstrap-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project. | `string` | `null` | no |
| region | Region of the regional resources, e.g. the state buckets. | `string` | `"europe-west4"` | no |
| state\_bucket\_name | Name of the foundations state bucket. Generated as `cmn-cf-bootstrap-terraform-state-<suffix>`, with the suffix of a generated project ID, when null; set it to keep an existing bucket. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| project\_id | ID of the bootstrap project. |
| state\_bucket | Name of the foundations state bucket. |
| tf\_bootstrap\_email | Email of the `tf-bootstrap` service account, applying the Cloud Foundations configurations. |
| tf\_bootstrap\_organization\_roles | Organisation roles of `tf-bootstrap`, which the authoritative organisation IAM policy of cf-organization must keep. |
| tf\_environment\_emails | Emails of the `tf-<short name>` deployer service accounts, by environment folder name. |
| tf\_environment\_state\_buckets | Names of the deployers' state buckets, by environment folder name. |
| tf\_plan\_email | Email of the `tf-plan` service account, planning the Cloud Foundations configurations. |
| tf\_plan\_organization\_roles | Organisation roles of `tf-plan`, which the authoritative organisation IAM policy of cf-organization must keep. |
<!-- markdownlint-restore -->
<!-- END_TF_DOCS -->

## Releases

Releases are dispatched manually on `main` with the [`release.yaml`](.github/workflows/release.yaml) workflow, choosing the part of the version to increase. It calls the
[`github-release.yaml`](https://github.com/damsoncloud/dcp.sdlc#reusable-workflows) reusable workflow, which creates the GitHub release and its tag. The Terraform Registry
publishes the new version from the tag.

## Security

See [SECURITY.md](SECURITY.md) for how to report vulnerabilities.

## Development

The repository uses [devenv](https://devenv.sh) with the shared [devenvbase](https://github.com/damsoncloud/dcp.sdlc/blob/main/devenvbase/README.md), pinned to a
[dcp.sdlc](https://github.com/damsoncloud/dcp.sdlc) release in `devenv.yaml`.

* `devenv shell` starts the shell.
* `devenv test` runs the git hooks and tests.
* `terraform_docs` regenerates the inputs and outputs above, which the `terraform-docs` git hook also does on commit.

The weekly `dcp.sdlc check` workflow opens an issue when a newer dcp.sdlc release is available. Upgrade with `devenv shell -- dcp_sdlc_upgrade_pr`, which also updates
the devenv inputs, runs the tests and opens a pull request.

## Licence

[Apache License 2.0](LICENSE)
