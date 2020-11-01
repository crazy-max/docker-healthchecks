<p align="center"><a href="https://github.com/crazy-max/docker-healthchecks" target="_blank"><img height="128" src="https://raw.githubusercontent.com/crazy-max/docker-healthchecks/master/.github/docker-healthchecks.jpg"></a></p>

<p align="center">
  <a href="https://hub.docker.com/r/crazymax/healthchecks/tags?page=1&ordering=last_updated"><img src="https://img.shields.io/github/v/tag/crazy-max/docker-healthchecks?label=version&style=flat-square" alt="Latest Version"></a>
  <a href="https://github.com/crazy-max/docker-healthchecks/actions?workflow=build"><img src="https://img.shields.io/github/workflow/status/crazy-max/docker-healthchecks/build?label=build&logo=github&style=flat-square" alt="Build Status"></a>
  <a href="https://hub.docker.com/r/crazymax/healthchecks/"><img src="https://img.shields.io/docker/stars/crazymax/healthchecks.svg?style=flat-square&logo=docker" alt="Docker Stars"></a>
  <a href="https://hub.docker.com/r/crazymax/healthchecks/"><img src="https://img.shields.io/docker/pulls/crazymax/healthchecks.svg?style=flat-square&logo=docker" alt="Docker Pulls"></a>
  <br /><a href="https://github.com/sponsors/crazy-max"><img src="https://img.shields.io/badge/sponsor-crazy--max-181717.svg?logo=github&style=flat-square" alt="Become a sponsor"></a>
  <a href="https://www.paypal.me/crazyws"><img src="https://img.shields.io/badge/donate-paypal-00457c.svg?logo=paypal&style=flat-square" alt="Donate Paypal"></a>
</p>

## About

[Healthchecks](https://github.com/healthchecks/healthchecks) Docker image based on Alpine Linux.<br />
If you are interested, [check out](https://hub.docker.com/r/crazymax/) my other Docker images!

💡 Want to be notified of new releases? Check out 🔔 [Diun (Docker Image Update Notifier)](https://github.com/crazy-max/diun) project!

___

* [Docker](#docker)
  * [Image](#image)
  * [Environment variables](#environment-variables)
  * [Ports](#ports)
* [Usage](#usage)
  * [Docker Compose](#docker-compose)
  * [Command line](#command-line)
* [Upgrade](#upgrade)
* [How can I help?](#how-can-i-help)
* [License](#license)

## Features

* Run as non-root user
* Multi-platform image
* [Traefik](https://github.com/containous/traefik-library-image) as reverse proxy and creation/renewal of Let's Encrypt certificates (see [this template](examples/traefik))

## Docker

### Image

| Registry                                                                                         | Image                           |
|--------------------------------------------------------------------------------------------------|---------------------------------|
| [Docker Hub](https://hub.docker.com/r/crazymax/healthchecks/)                                            | `crazymax/healthchecks`                 |
| [GitHub Container Registry](https://github.com/users/crazy-max/packages/container/package/healthchecks)  | `ghcr.io/crazy-max/healthchecks`        |

Following platforms for this image are available:

```
$ docker run --rm mplatform/mquery crazymax/healthchecks:latest
Image: crazymax/healthchecks:latest
 * Manifest List: Yes
 * Supported platforms:
   - linux/amd64
   - linux/arm/v6
   - linux/arm/v7
   - linux/arm64
   - linux/386
   - linux/ppc64le
   - linux/s390x
```

### Environment variables

* `TZ`: The timezone assigned to the container (default `UTC`)
* `PUID`: Process UID (default `1000`)
* `PGID`: Process GID (default `1000`)
* `SUPERUSER_EMAIL`: Superuser email to access [admin panel](https://github.com/healthchecks/healthchecks#accessing-administration-panel)
* `SUPERUSER_PASSWORD`: Superuser password
* `USE_OFFICIAL_LOGO`: Replace generic logo with official branding (default `false`)

To configure the application, you just add the environment variables as shown in the
[Configuration page](https://github.com/healthchecks/healthchecks#configuration) of Healthchecks Project.

> 💡 `SUPERUSER_PASSWORD_FILE` can be used to fill in the value from a file, especially for Docker's secrets feature.

### Volumes

* `/data`: Contains SQLite database and static images folder

> :warning: Note that the volumes should be owned by the user/group with the specified `PUID` and `PGID`. If you don't
> give the volume correct permissions, the container may not start.

### Ports

* `2500`: [Healthchecks SMTP](https://github.com/healthchecks/healthchecks#receiving-emails) listener service
* `8000`: HTTP port

## Usage

### Docker Compose

Docker compose is the recommended way to run this image. You can use the following
[docker compose template](examples/compose/docker-compose.yml), then run the container:

```bash
docker-compose up -d
docker-compose logs -f
```

### Command line

You can also use the following minimal command:

```bash
$ docker run -d -p 8000:8000 --name healthchecks \
  -e "TZ=Europe/Paris" \
  -e "SECRET_KEY=5up3rS3kr1t" \
  -e "DB=sqlite" \
  -e "DB_NAME=/data/hc.sqlite" \
  -e "ALLOWED_HOSTS=*" \
  -v $(pwd)/data:/data \
  crazymax/healthchecks:latest
```

## Upgrade

Recreate the container whenever I push an update:

```bash
docker-compose pull
docker-compose up -d
```

## How can I help?

All kinds of contributions are welcome :raised_hands:! The most basic way to show your support is to star :star2:
the project, or to raise issues :speech_balloon: You can also support this project by
[**becoming a sponsor on GitHub**](https://github.com/sponsors/crazy-max) :clap: or by making a
[Paypal donation](https://www.paypal.me/crazyws) to ensure this journey continues indefinitely! :rocket:

Thanks again for your support, it is much appreciated! :pray:

## License

MIT. See `LICENSE` for more details.
