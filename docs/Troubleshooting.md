# Troubleshooting Guide

This guide covers common issues when working with PBIP validation, report rules, and dataset rules in this repository.

## PBIP Structure Validation Fails

Symptom:

- `No .pbip file found`
- `Expected exactly one .pbip file at the project root`
- missing report or semantic model definition files

What to check:

- the repository root contains exactly one `.pbip` file
- the PBIP `artifacts[0].report.path` points to the report folder
- `definition.pbir` contains a valid `datasetReference.byPath.path`
- the semantic model includes `definition.pbism` and `definition/model.tmdl`
- `definition/relationships.tmdl` is optional; single-table semantic models may not have relationships

Relevant validator:

- `tests/validate_pbip_structure.py`

## Dataset Rules Behave Differently on Branches

Symptom:

- a dataset rule triggers on `main` or `develop` but not on a feature branch

Cause:

- the effective ruleset is filtered by severity in `scripts/Prepare-QualityRules.ps1`

What to check:

- `Severity` value in `Rules-Dataset.json`
- branch name passed as `-SourceBranch`
- generated `Rules-Dataset.effective.json`

Rule behavior summary:

- `main` and `develop`: `Severity >= 2`
- feature branches: `Severity >= 3`

## Report Rules Behave Differently on Branches

Symptom:

- a report rule is only blocking on `main` or `develop`

Cause:

- selected warnings are promoted to `error` on protected integration branches

What to check:

- `id` in `Rules-Report.json`
- `logType` in the prepared output file
- generated `Rules-Report.effective.json`

## A Rule Is Too Noisy

Symptom:

- a rule catches valid visuals, valid model objects, or too many edge cases

What to do:

- narrow the scope first
- add explicit exclusions for known acceptable cases
- reduce severity or keep the report rule at `warning`
- validate on a feature branch before promoting on `main`

Best reference:

- `Rules-Authoring-Guide.md`
- `tools/enterprise-standards-builder/index.html` for policy-level changes
- `tools/rule-designer/index.html` for individual rule tuning

## Pipeline Cannot Find Report or Semantic Model Definitions

Symptom:

- `No semantic model definitions found`
- `No report definitions found`
- `Cannot find semantic model definition`

What to check:

- required `.pbism` and `.pbir` files still exist in expected folders
- folder names match the PBIP and PBIR path references
- the repository layout was not changed without updating those references

## Tool Download Failures in CI

Symptom:

- Tabular Editor or PBI Inspector download step fails

Likely causes:

- transient GitHub release availability issue
- network restrictions on the build agent
- upstream release asset naming change

What to check:

- URLs defined in `azure-pipelines.yml`
- build agent outbound connectivity
- whether fallback rule downloads succeeded separately from tool downloads

## GCC High Deployment Uses PBIX Import

Symptom:

- deployment logs show `Power BI PBIX deployment completed`
- the pipeline requires `deployment-manifest.json`
- a GCC High run fails before import because the PBIX hash or PBIP source hash does not match the manifest

Cause:

- **GCC High deployment intentionally validates PBIP but deploys PBIX. It does not push PBIP definitions with Fabric REST semantic model APIs.**

What to check:

- the target endpoint variables identify GCC High
- the PBIX was saved from Power BI Desktop after PBIP changes
- `deployment-manifest.json` was regenerated after saving the PBIX
- the PBIP, PBIX, and `deployment-manifest.json` were committed together

Regenerate the manifest:

```powershell
.\shared\scripts\New-PbixDeploymentManifest.ps1 `
  -PbipPath .\shared\pbip-local `
  -PbixFile .\shared\pbip-local\<project>.pbix
```

Reference:

- [GCC High deployment behavior](architecture/gcc-high-deployment.md)

## DAX Test Stage Shows Skipped DAX Execution

Symptom:

- CI passes and JUnit results show DAX catalog tests, but execution cases are skipped

Cause:

- `tests/run_dax_tests.py` now reads `dax-tests.json` and validates metadata, but actual measure query execution still needs an evaluator implementation

What to do:

- customize and enable tests in `shared/dax-tests.json`
- wire semantic-link-labs, XMLA, or Tabular Editor scripting into the runner to execute generated DAX queries
- keep JUnit XML output so Azure Pipelines can publish results
- treat current execution-skipped tests as metadata coverage, not full semantic validation

## Two Pipeline YAML Files Exist

Symptom:

- uncertainty about which pipeline file is operational

Current repository state:

- `azure-pipelines.yml` is the active quality-validation pipeline
- `azure-pipeline.yml` reads like example/template-oriented CI/CD guidance

Recommendation:

- use `azure-pipelines.yml` as the authoritative validation reference
- either document the purpose of `azure-pipeline.yml` or move/archive it to reduce ambiguity

## When To Change Rules vs Fix Artifacts

Change the artifact when:

- the rule is correct and the report/model violates a standard you want to keep

Change the rule when:

- the rule produces false positives
- the rule is enforcing a standard not yet agreed by the team
- the rule is too broad for the current project shape
