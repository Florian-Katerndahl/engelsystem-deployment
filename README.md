# Deployment of Engelsystem

The Engelsystem is used to organise volunteers for events and is developed by folks from the CCC.

In contrast to the original Docker based deployment, this is not bound to NGINX. Currently, Caddy is used as a webserver which greatly simplifies management of TLS certificates. In theory, an other webserver can be used simply by replacing the container image of the `webserver` service.

## Setup

To deploy the Engelsystem, you need to execute only three commands:

```bash
docker compose build
docker compose up -d
docker compose exec engelsysten bin/migrate
```

Please note that on the first startup, Caddy will try to acquire TLS certificates which may take a while. Thus, it's best not to immediately execute the third command which will create all necessary SQL tables if they don't alreay exist. For convenience, there exists the `setup.sh` script which waits 20 seconds between starting the containers and issuing the last command. Usually, this should be enough. 

## Configuration

### Caddy

Caddy only needs an email for the TLS certificate and a domain. Both should be given as `DOMAIN` and `TLS_EMAIL` in the file `environments/caddy.env` which must be created first.

### Engelsystem

Almost all settings can/should be made by setting the corresponding values in `environments/engel.env`. Note though, that not all configuration is possible that way and some settings require changes to the PHP config file. `configs/config.default.php` is the default configuration at the time of writing and is adapted in `configs/config.php` by e.g. including different mail settings (different key) to enable mail notifications.

