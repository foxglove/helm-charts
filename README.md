# Foxglove Helm Charts

> To use the helm charts, see the docs at https://helm-charts.foxglove.dev.

This repo contains charts and support scripts to manage the Foxglove [helm repo](https://helm.sh/docs/helm/helm_repo/).

The rest of the README is developer notes for updating this repo.

---

## Release a new chart version

Once the chart is working as you desire, open a PR to bump the chart version. Once it is merged to main, the [chart-releaser-action](https://github.com/helm/chart-releaser-action) will package it into a Github Release and update the `index.yaml` file in `gh-pages` with the new chart.
