# Auto-update Guide

The guide to automatically updating your package on production servers
automatically using GitHub Actions.

> **Note**: you need a GitHub Personal Access Token (PAT) that has read-write
> access to the deployment workflows in this repository.

## Updating Locally

To update locally, you need to have Nix installed and have loaded the Nix
shell. Then, run:

```sh
scripts/pkg update <package>
```

After that, push the changes to the `main` branch as usual.

## The `update-pkg` Action

This repository contains an `update-pkg` action that automatically dispatches a
new workflow run that updates the given package onto acm-aws. Use it as such:

```yml
- name: Update package on production
  uses: acmcsufoss/acm-aws/.github/actions/update-pkg@main
  with:
    token: ${{ secrets.PAT_TOKEN }}
    package: acmregister # !!!: swap with your own!
```

> **Note**: the `PAT_TOKEN` secret is a GitHub Personal Access Token (PAT) that
> has read-write access to the deployment workflows in this repository. To
> obtain one, go to your GitHub settings, then Developer Settings, then
> Personal Access Tokens. Create a new token with the `workflow` scope. Note
> that you must have write access to this repository.

## Full Workflow Example

This workflow is partly taken from
[acmregister](https://github.com/diamondburned/acmregister)'s
`update-production.yml` workflow. For a working example, see that file.

```yml
name: Update on Production

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    uses: ./.github/workflows/build.yml

  dispatch:
    name: Dispatch to acm-aws
    needs: build
    runs-on: ubuntu-latest
    environment: Production
    concurrency: Production
    steps:
      - name: Dispatch workflow
        uses: diamondburned/acm-aws/.github/actions/update-pkg@main
        with:
          token: ${{ secrets.PAT_TOKEN }}
          package: acmregister
```
