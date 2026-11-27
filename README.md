# Damson Cloud GCP Cloud Foundations: bootstrap

Terraform module of the Damson Cloud GCP Cloud Foundations creating the bootstrap of a Google Cloud organisation:

* the bootstrap project and the foundations' Terraform state bucket,
* the `tf-bootstrap` (apply) and `tf-plan` (plan) service accounts, and a deployer service account (`tf-<env>`) with a state bucket per environment,
* the organisation roles of `tf-bootstrap` and `tf-plan`, and their billing account grants,
* optionally, further organisations sharing the bootstrap project (see [Several organisations](#several-organisations)),
* optionally, GitHub Workload Identity Federation trusting only the listed repositories, by their immutable IDs ([`modules/github`](modules/github)).

The organisation roles of `tf-bootstrap` and `tf-plan` are returned as outputs, so that the authoritative organisation IAM policy of cf-organization keeps them.

The module is applied in the same Terraform state as [`cf-hierarchy`](https://registry.terraform.io/modules/damsoncloud/cf-hierarchy/google).

## Usage

```hcl
module "bootstrap" {
  source  = "damsoncloud/cf-bootstrap/google"
  version = "X.Y.Z"

  organization_id = "123456789012"
  folders         = module.hierarchy.folders
  billing_account = "012345-6789AB-CDEF01"
}
```

Pin an exact version. New versions are published as immutable GitHub releases with `vX.Y.Z` tags, following [semantic versioning](https://semver.org/).

See [`examples/basic`](examples/basic) for the module applied with cf-hierarchy, and [`examples/github`](examples/github) for the GitHub Actions integration.

### Several organisations

A customer with several organisations, e.g. one per domain, shares one bootstrap project in the organisation of `organization_id`. The further organisations, each with its own
`cf-hierarchy`, are listed in `additional_organizations` by a short key:

* `tf-bootstrap` and `tf-plan` are granted the same organisation roles in each of them, and the roles on their billing accounts,
* each of their environments gets a `tf-<short name>-<key>` deployer with its own state bucket, returned by the `additional_organizations` output,
* the GitHub workload repositories of their environments are listed under `<key>/<folder name>` in `github.workload_repository_ids`.

The deployers of a further organisation are external identities there, so the org-policies submodule of its cf-organization must allow them.

See [`examples/several-organizations`](examples/several-organizations).

<!-- BEGIN_TF_DOCS -->
<!-- markdownlint-capture -->
<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| additional\_organizations | Further organisations sharing the bootstrap project, by a key of 1-10 lowercase letters, digits or hyphens, suffixing the names of their deployers, e.g. `net`:   `organization_id`, the ID of the organisation, where `tf-bootstrap` and `tf-plan` are granted their organisation roles too;   `folders`, as the `folders` input, e.g. the `folders` output of the organisation's cf-hierarchy;   each environment gets a `tf-<short name>-<key>` deployer service account with its own state bucket;   `billing_account`, the ID of the billing account of the organisation's projects, administered by `tf-bootstrap` and viewed by `tf-plan`; the bootstrap project's when null;   `billing_admins_group`, the email of the group administering that billing account; no group is granted when null. | ```map(object({ organization_id = string folders = map(object({ id = string short_name = optional(string) common = optional(bool, false) })) billing_account = optional(string) billing_admins_group = optional(string) }))``` | `{}` | no |
| billing\_account | ID of the billing account of the bootstrap project, e.g. `012345-6789AB-CDEF01`. | `string` | n/a | yes |
| billing\_admins\_group | Email of the group administering the billing account, e.g. `gcp-billing-admins@example.com`. No group is granted when null. | `string` | `null` | no |
| folders | The folders by folder name, e.g. the `folders` output of cf-hierarchy:   `id`, the resource name (`folders/<id>`);   `short_name`, the environment's short name, null for folders other than environments;   `common`, whether it is the common environment. The bootstrap project is created in the common environment's folder and its generated names start with its short name; each environment gets a `tf-<short name>` deployer service account with its own state bucket. | ```map(object({ id = string short_name = optional(string) common = optional(bool, false) }))``` | n/a | yes |
| github | GitHub Actions integration through Workload Identity Federation; not set up when null:   `repository_owner_id`, the ID of the GitHub organisation, the only one trusted;   `foundation_repository_ids`, the IDs of the Cloud Foundations repositories, impersonating `tf-plan` from any ref and `tf-bootstrap` from the default branch;   `workload_repository_ids`, the IDs of the workload repositories by environment folder name, or `<key>/<folder name>` in the further organisations,     impersonating the environment's deployer from any ref;   `default_branch_name`, the default branch of the Cloud Foundations repositories. | ```object({ repository_owner_id = string foundation_repository_ids = optional(list(string), []) workload_repository_ids = optional(map(list(string)), {}) default_branch_name = optional(string, "main") })``` | `null` | no |
| organization\_id | ID of the organisation, where the deployer service accounts are granted their roles. | `string` | n/a | yes |
| project\_id | ID of the bootstrap project. Generated as `<common short name>-cf-bootstrap-<suffix>`, e.g. `cmn-cf-bootstrap-<suffix>`, with a random 4 hexadecimal characters suffix, when null; set it to keep the ID of an existing project. | `string` | `null` | no |
| region | Region of the regional resources, e.g. the state buckets. | `string` | `"europe-west4"` | no |
| state\_bucket\_name | Name of the foundations state bucket. Generated as `<common short name>-cf-bootstrap-terraform-state-<suffix>`, with the suffix of a generated project ID, when null; set it to keep an existing bucket. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| additional\_organizations | The deployers of the further organisations, by organisation key:   `tf_environment_emails`, the emails of the `tf-<short name>-<key>` deployer service accounts, by environment folder name;   `tf_environment_state_buckets`, the names of their state buckets, by environment folder name. |
| github\_workload\_identity\_provider | Name of the GitHub Actions Workload Identity Federation provider, for `google-github-actions/auth`; null without the GitHub integration. |
| project\_id | ID of the bootstrap project. |
| project\_number | Number of the bootstrap project, e.g. for the membership of the perimeter of cf-organization's vpc-service-controls submodule. |
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
