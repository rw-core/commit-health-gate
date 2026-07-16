<div align="center">
  <img src="assets/logo.png" alt="Commit Health Gate Logo" width="128" />

  <h1>Commit Health Gate</h1>

  <p>
    <a href="https://github.com/rw-core/commit-health-gate/actions/workflows/release.yml"><img src="https://github.com/rw-core/commit-health-gate/actions/workflows/release.yml/badge.svg" alt="CI"></a>
    <a href="https://github.com/marketplace/actions/commit-health-gate"><img src="https://img.shields.io/badge/marketplace-Commit_Health_Gate-blue.svg?logo=github" alt="GitHub Marketplace"></a>
    <a href="https://codecov.io/gh/rw-core/commit-health-gate"><img src="https://codecov.io/gh/rw-core/commit-health-gate/graph/badge.svg" alt="codecov"></a>
    <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  </p>
</div>


A language-agnostic code-quality gate for Pull Requests. It automatically analyzes the commits in a PR and fails or warns if they contain "mega commits" (too many lines or files changed) or commits with suspicious patterns.

This helps maintain a clean, reviewable, and high-quality commit history in your repository.

- 🚦 **Language Agnostic:** Works with any repository regardless of the programming language.
- 🐘 **Detects Mega Commits:** Configurable thresholds for lines changed and files changed to discourage massive commits that are hard to review.
- 🕵️ **Identifies Suspicious Patterns:** Automatically spots commits that have questionable messages or patterns.
- 🕒 **Identifies Burnout Commits:** Flags commits made outside configured working hours to protect team health.
- 🚀 **Fast Native Binary:** Uses a pre-compiled native binary for near-instant startup, with a fallback to Dart source execution.
- 💬 **Sticky PR Comments:** Posts a summary comment on the Pull Request highlighting any violations found.

## Sample Usage

Create a workflow file (e.g., `.github/workflows/commit-health.yml`) in your repository:

```yaml
name: Commit Health Check

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write # Required to post sticky comments on PRs
  contents: read

jobs:
  check-commits:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 # Required to analyze commits

      - name: Run Commit Health Gate
        uses: rw-core/commit-health-gate@v1
        with:
          # Optional: Specify thresholds
          # github-token: ${{ github.token }}
          # mega-commit-line-threshold: '500'
          # mega-commit-file-threshold: '20'
          # Set to true to fail the workflow on violations
          # fail-on-violation: 'false'
          # Burnout check configuration
          # fail-on-burnout: 'false'
          # work-hours-start: '9'
          # work-hours-end: '17'
          # working-directory: '.'
```

## Inputs

| Name | Description | Default | Required |
| --- | --- | --- | --- |
| `github-token` | Token used to post the sticky PR comment (needs `pull-requests:write`). | `${{ github.token }}` | No |
| `mega-commit-line-threshold` | Threshold of lines changed to flag a commit as a mega commit. | `'500'` | No |
| `mega-commit-file-threshold` | Threshold of files changed to flag a commit as a mega commit. | `'20'` | No |
| `fail-on-violation` | When true, exit non-zero if any threshold is violated or suspicious commit is found. | `'false'` | No |
| `fail-on-burnout` | When true, exit non-zero if any burnout commits are found. | `'false'` | No |
| `work-hours-start` | Start hour (0-23) of standard working hours. | `'9'` | No |
| `work-hours-end` | End hour (0-23) of standard working hours. | `'17'` | No |
| `working-directory` | Path (relative to the checkout) of the repository root to analyse. | `'.'` | No |

## Outputs

| Name | Description |
| --- | --- |
| `mega-commits-count` | Number of mega commits found. |
| `suspicious-commits-count` | Number of suspicious commits found. |
| `burnout-commits-count` | Number of burnout commits found. |

## Example of how the end-result PR comment looks like

> ## 🚦 Commit Health Gate
> 
> ❌ **2** violation(s) found.
> 
> ### 🐘 Mega Commits
> 
> - **`a1b2c3d`**: Commit is too large (600 lines changed, threshold: 500).
> 
> ### 🕵️ Suspicious Patterns
> 
> - **`e4f5g6h`**: Suspicious commit message detected ("fix stuff").

