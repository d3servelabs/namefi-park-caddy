# Namefi-Park Caddy Server

This repo contains the docker config for Caddy Server for [Namefi Park](github.com/d3servelabs/namefi-park).

## Deployment

To set gcloud project to d3serve-labs

```sh
gcloud config set project d3serve-labs
```

To set gcloud region to us-central1

```sh
gcloud config set run/region us-central1
```

To build a new provision

```sh
gcloud builds submit --tag gcr.io/d3serve-labs/caddy
```

To deploy

```sh
gcloud run deploy caddy --image gcr.io/d3serve-labs/caddy --platform managed --allow-unauthenticated
```