# 🍚 Contributing recipes

Thank you for contributing to the OpenTelemetry Collector Cookbook. Contributions may add a new
recipe, correct an existing one, improve its reproducibility, or update it for a current
OpenTelemetry release.

## Before you start

Search existing issues, pull requests, and recipes for related work. Create a focused feature
branch from the latest `origin/main`:

```bash
git fetch origin
git switch -c <type>/<short-description> origin/main
```

Do not mix unrelated cleanup into a recipe contribution.

## Recipe requirements

A recipe should:

- demonstrate one clear concept or integration;
- be reproducible with publicly available tools and services;
- be self-contained, even when it links to related recipes;
- use current, non-deprecated Collector component names;
- pin the versions used for validation;
- include complete commands and realistic configuration values; and
- add or update its entry in the root [`README.md`](README.md) index.

Recipes for commercial vendors are welcome when anyone can reproduce them with a free account.
Keep the recipe focused on the OpenTelemetry integration and avoid marketing claims.

Follow the README structure, configuration conventions, and source-of-truth policy in
[`AGENTS.md`](AGENTS.md). These requirements apply whether a human or an AI coding agent writes
the change.

## Validate your change

There is no unit-test suite. A recipe's test is a runtime smoke test at the versions listed in its
`😋 Tested with` section.

For a local recipe, start the Collector, generate representative telemetry, and verify the
documented result. For a Kubernetes recipe, use a real k3d cluster and the pinned OpenTelemetry
Operator whenever the recipe depends on Operator reconciliation or Kubernetes runtime behavior.

Include the exact commands and a short result summary in the pull request. Clean up containers,
clusters, credentials, certificates, and generated files after testing. Never commit secrets or
private keys.

## Contributions from AI coding agents

Pull requests authored or implemented with AI coding agents are welcome. They are held to the same
correctness and validation standards as every other contribution.

- A human contributor must open or take ownership of the pull request, review the output before
  submission, and be able to answer review feedback.
- Disclose material agent involvement in the pull request description or with an appropriate
  `Co-authored-by` commit trailer.
- Verify the repository, working directory, and branch before committing. This is especially
  important when an agent works across multiple worktrees.
- Preserve unrelated local changes and do not reset, overwrite, or discard work that is outside
  the contribution.
- Report what was actually tested. Do not claim that a runtime test passed when only static
  validation was performed.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<optional scope>): <short description>

<optional body>
```

Common types:

- `feat`: a new recipe or capability
- `fix`: a configuration or documentation correction
- `docs`: documentation-only changes
- `chore`: version bumps and repository maintenance
- `refactor`: restructuring without changing recipe behavior

Use the recipe name as the optional scope when useful. Examples:

```text
feat(log-clustering): add Drain processor recipe
fix(access-logs-to-metrics): use record-level test attributes
docs: document contribution workflow
chore: update recipes to Collector v0.157.0
```

Keep commits focused and explain non-obvious choices in the body. If you add a
`Co-authored-by` trailer, place it after a blank line at the end of the message.

## Pull requests

A pull request should include:

- a concise summary of the change;
- the exact validation commands and observed results;
- links to relevant upstream component documentation or release notes;
- any limitations, skipped runtime checks, or follow-up work; and
- disclosure of material AI-agent involvement, when applicable.

Before requesting review, confirm that the branch is based on the latest `origin/main`, the root
recipe index is current, no generated secrets are present, and the diff contains only the intended
change.
