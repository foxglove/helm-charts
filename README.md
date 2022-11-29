# Foxglove Helm Charts

> To use the helm charts, see the docs at https://helm-charts.foxglove.dev.

This repo contains charts and support scripts to manage the Foxglove [helm repo](https://helm.sh/docs/helm/helm_repo/).

The rest of the README is developer notes for updating this repo.

---

## Release a new chart version

Once the chart is working as you desire, open a PR to bump the chart version. Once it is merged to main, the [chart-releaser-action](https://github.com/helm/chart-releaser-action) will package it into a Github Release and update the `index.yaml` file in `gh-pages` with the new chart.

## License

Copyright (c) Foxglove Technologies Inc

The helm charts and other code contained within this repository are [MIT licensed](/LICENSE). Containers, binaries, and other software referenced by this repository ("Software") may only be used if you (and any entity that you represent) have a valid enterprise agreement between you and Foxglove governing the use of the Software.
