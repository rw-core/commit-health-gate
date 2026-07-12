# Commit Health Gate

<div align="center">
  <img src="commit_health_gate_logo.png" alt="Commit Health Gate Logo" width="200" />

  <br />

  [![Marketplace](https://img.shields.io/badge/Marketplace-Commit_Health_Gate-blue.svg?logo=github)](https://github.com/marketplace/actions/commit-health-gate)
  [![CI](https://github.com/rw-core/commit-health-gate/actions/workflows/release.yml/badge.svg)](https://github.com/rw-core/commit-health-gate/actions/workflows/release.yml)
  [![codecov](https://codecov.io/gh/rw-core/commit-health-gate/branch/main/graph/badge.svg)](https://codecov.io/gh/rw-core/commit-health-gate)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
</div>

A language-agnostic code-quality gate for Pull Requests. It automatically analyzes the commits in a PR and fails or warns if they contain "mega commits" (too many lines or files changed) or commits with suspicious patterns.

This helps maintain a clean, reviewable, and high-quality commit history in your repository.

## Features

- 🚦 **Language Agnostic:** Works with any repository regardless of the programming language.
- 🐘 **Detects Mega Commits:** Configurable thresholds for lines changed and files changed to discourage massive commits that are hard to review.
- 🕵️ **Identifies Suspicious Patterns:** Automatically spots commits that have questionable messages or patterns.
- 🚀 **Fast Native Binary:** Uses a pre-compiled native binary for near-instant startup, with a fallback to Dart source execution.
- 💬 **Sticky PR Comments:** Posts a summary comment on the Pull Request highlighting any violations found.

## Usage

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
          mega-commit-line-threshold: '500'
          mega-commit-file-threshold: '20'
          # Set to true to fail the workflow on violations
          fail-on-violation: 'true'
```

## Inputs

| Name | Description | Default | Required |
| --- | --- | --- | --- |
| `github-token` | Token used to post the sticky PR comment (needs `pull-requests:write`). | `${{ github.token }}` | No |
| `mega-commit-line-threshold` | Threshold of lines changed to flag a commit as a mega commit. | `'500'` | No |
| `mega-commit-file-threshold` | Threshold of files changed to flag a commit as a mega commit. | `'20'` | No |
| `fail-on-violation` | When true, exit non-zero if any threshold is violated or suspicious commit is found. | `'false'` | No |
| `working-directory` | Path (relative to the checkout) of the repository root to analyse. | `'.'` | No |

## Outputs

| Name | Description |
| --- | --- |
| `mega-commits-count` | Number of mega commits found. |
| `suspicious-commits-count` | Number of suspicious commits found. |

## Publishing to GitHub Marketplace

This action is ready to be published to the GitHub Marketplace!
The `action.yml` file contains the required `name`, `description`, and `branding` fields.

To publish:
1. Go to your repository on GitHub.
2. Click on the "Releases" section.
3. Draft a new release.
4. Check the box that says "Publish this Action to the GitHub Marketplace".
5. Follow the prompts to categorize and publish!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.