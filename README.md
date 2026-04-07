# Forerunner Dev Ops Take Home

## Overview

This repository contains a multi-stage Docker build and a Docker Compose setup for the provided Node.js healthcheck application and a PostgreSQL database.

The solution is designed to satisfy the take-home requirements for:
- three Docker build targets: `development`, `staging`, and `production`
- a Compose-managed local environment that starts both the app and Postgres
- explicit image tagging for each environment
- simple build tooling outside of Docker Compose via `make`

## Requirements

### Docker

This project assumes Docker Engine is installed and running.

If you want to use the Makefile commands exactly as written, you also need:
- Docker Compose v2 available as `docker compose`
- GNU Make

### Additional dependencies outside Docker

No non-Docker application dependencies are required to run the containerized solution.

You do **not** need to install:
- Node.js
- npm packages for the app
- PostgreSQL

Those are all handled inside Docker.

The only non-Docker dependency I rely on for the convenience commands is `make`. If `make` is not installed, you can still run all build and startup commands directly with `docker build` and `docker compose`.

## Build Instructions

### Build environment-specific images directly

Build the development image:

```bash
make build-development
```

Build the staging image:

```bash
make build-staging
```

Build the production image:

```bash
make build-production
```

These commands produce the following tags by default:
- `forerunner-app:development`
- `forerunner-app:staging`
- `forerunner-app:production`

If you want a different repository name, override `APP_IMAGE`:

```bash
make build-production APP_IMAGE=my-app
```

## Run Instructions

### Local development stack with Docker Compose

Start the development environment:

```bash
make up-development
```

This starts:
- `db`: a PostgreSQL 16.0 container
- `app`: the Node application built from the `development` target

The application is exposed on host port `3000`.

Once the application has finished its intentionally delayed startup and can connect to Postgres, the healthcheck should succeed:

```bash
curl localhost:3000/healthcheck
```

Note that the provided application intentionally returns `503` for a random 60-120 seconds after startup before it can become healthy, so an immediate success response is not expected.

### Run staging locally with Docker Compose

```bash
make up-staging
```

This uses the `staging` image tag and starts the app with the `--debug` flag.

### Run production locally with Docker Compose

```bash
make up-production
```

This uses the `production` image tag and includes `sysstat` in the app image.

### Override the container's internal application port

The assignment requires the server to honor a `PORT` environment variable while still being reachable on port `3000` on the host.

This repository does that with:

```yaml
ports:
  - "3000:${PORT:-3000}"
```

Example:

```bash
PORT=4000 make up-development
```

In that case, the app listens on port `4000` inside the container but is still available on:

```bash
curl localhost:3000/healthcheck
```

### Stop the stack

```bash
make down
```

## Technical Decisions

### 1. Multi-stage Dockerfile with three explicit targets

The Dockerfile exposes three final build targets:
- `development`
- `staging`
- `production`

This lets us separate the dependencies and configuration specific for each environment (such as sysstat or running in debug mode)

### 2. Separate dependency-install stages from runtime stages

The Dockerfile uses dedicated dependency stages:
- `deps-production`
- `deps-development`

The final runtime stages only copy in:
- `server.js`
- `run.sh`
- `node_modules`

This keeps the final images smaller and makes the layer invalidation behavior more precise.

### 3. Keep the runtime image simple

I intentionally did **not** include build-time files such as:
- `build.sh`
- `package.json`
- `package-lock.json`

in the final runtime image because the running application does not need them.

### 4. Healthcheck lives in the image rather than Compose

I placed the application healthcheck in the Dockerfile instead of duplicating it in `docker-compose.yml`.

That means:
- the healthcheck behavior travels with the image
- local Compose runs and other image consumers use the same healthcheck logic
- the app is considered healthy only when `/healthcheck` returns `200`

The healthcheck also includes a long `start-period` because the provided server intentionally returns `503` for a random startup window before it is allowed to become healthy.

### 5. Explicit image naming in Docker Compose

I configured the app service as:

```yaml
image: ${APP_IMAGE:-forerunner-app}:${APP_ENV:-development}
```

instead of letting Docker Compose create a project-directory-based image name.

This makes it obvious which image tag corresponds to which environment and lines up cleanly with the Makefile targets.

### 6. Makefile for build convenience outside Compose

The assignment says staging and production will not be built with Docker Compose in practice, so I added a Makefile with explicit commands for:
- building each environment image directly
- bringing up the stack locally with a chosen environment image/tag

This keeps the common commands short while still making the underlying Docker behavior clear.

### 7. Run the app as the non-root `node` user

The final runtime stages switch to `USER node`.

This is not required for functionality, but it is a low-cost security hardening step because the application does not need root privileges to listen on its configured port or serve requests.

## Resources Used

- The take-home assignment PDF provided by Forerunner
- The provided public GitHub repository for the application source
- Official Docker Hub image documentation for Node and Postgres
- ChatGPT

I used ChatGPT heavily for this, asking it to look at the github repo and generate the Dockerfile, docker-compose, Makefile and README per the instructions. Then I went through each and sanity checked the following:
- the Dockerfile was balancing readability, image size (slim base images and only copying node_modules to the runtime image) and intelligent layer ordering for caching (copying application files after running apt-get installs)
- the docker-compose file had common sense volume names, the ports were mapped correctly, the health checks were well calibrated to make sure the db spun up before the app, and the image names matched the images built directly from the Dockerfile so we wouldn't have the local env cluttered up with duplicates
- the Makefile is a little more crowded than I would normally start with, I wouldn't have separate up commands for all the environments or possibly even separate ones for all the build environments but I'm trying to keep to what the assignment asked. Given my preference i'd just have make build, up and down associated with dev, since that's what people are likely to run locally, and only add the others if people are really running staging and prod locally for debug purposes frequently.
- the README I just went through to chop out AI slop as much as possible

## Feedback on the Assignment
I was torn on how much to use AI when doing this assignment. In the end I let it do a lot because that's what I would do in a real work setting, but I'm not sure if it makes the assignment seem too easy. It was able to generate a working solution directly from uploading the assignment pdf, and though I sanity checked every file and double checked everything was reasonably human readable, a lot of the gotchas I was looking out for (networking issues, missing volumes, stupid layer ordering) it dodged by itself. So as far as feedback goes, maybe a live debugging session in the future will help you get a better sense of my technical depth.

No notes on the clarity of the instructions though, that was great. Specific versions made things very straightforward.
