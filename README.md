# 🛠️ Zabbix Proxy for PostgreSQL

![Build Status](https://github.com/monfardineL/zabbix-proxy-pgsql/actions/workflows/push-to-registries.yml/badge.svg)
![License: AGPL-3.0](https://img.shields.io/badge/License-AGPL--3.0-blue.svg)
![Zabbix Version](https://img.shields.io/badge/Zabbix-7.4-blue)


A high-performance Zabbix Proxy Docker image specifically built with **PostgreSQL database support**. Unlike the official images that often default to SQLite or MySQL, this project enables seamless integration with PostgreSQL, matching your Zabbix Server infrastructure.

## 🚀 Repositories
Images are automatically built and pushed to:
- 🐙 **GitHub Container Registry**: `ghcr.io/monfardineL/zabbix-proxy-pgsql`
- 🐳 **Docker Hub**: `monfardinel/zabbix-proxy-pgsql`

## 🏷️ Tagging Logic
The build pipeline automatically generates tags based on the OS and Zabbix version:
- `ubuntu-{MAJOR_VERSION}` (e.g., `ubuntu-7.4`)
- `ubuntu-{ZBX_VERSION}` (e.g., `ubuntu-7.4.8`)

## 🏗️ Getting Started

### Prerequisites
- Docker & Docker Compose
- A PostgreSQL 16+ database instance

### Supported Environment Variables
You can configure the Zabbix Proxy using the following environment variables:

| Variable | Default | Description |
| :--- | :--- | :--- |
| **Database Connection** | | |
| `DB_SERVER_HOST` | `postgres-server` | PostgreSQL server host. |
| `DB_SERVER_PORT` | `5432` | PostgreSQL server port. |
| `POSTGRES_USER` | `zabbix` | PostgreSQL username. |
| `POSTGRES_PASSWORD` | `zabbix` | PostgreSQL password. |
| `POSTGRES_DB` | `zabbix_proxy` | PostgreSQL database name. |
| `DB_SERVER_SCHEMA` | `public` | PostgreSQL schema to use. |
| **Proxy Configuration** | | |
| `ZBX_HOSTNAME` | `zabbix-proxy-postgresql` | Hostname of the proxy. |
| `ZBX_SERVER_HOST` | `zabbix-server` | IP or hostname of Zabbix server. |
| `ZBX_SERVER_PORT` | `10051` | Port of Zabbix server. |
| `ZBX_PROXYMODE` | `0` | `0` for active proxy (default), `1` for passive. |
| `ZBX_DEBUGLEVEL` | `3` | Debug level (0-5). |
| `ZBX_TIMEOUT` | `4` | Timeout (1-30). |
| **Advanced Options** | | |
| `DEBUG_MODE` | `false` | Enable trace mode in the entrypoint script. |
| `ZBX_ENABLE_SNMP_TRAPS` | `false` | Set to `true` to enable SNMP traps. |
| `ZBX_ALLOWUNSUPPORTEDDBVERSIONS` | `0` | Allow unsupported DB versions. |
| `ZBX_CLEAR_ENV` | `true` | Clear environment variables after startup. |

### TLS & Encryption
The image supports TLS for both the Zabbix Server connection and the Database connection.
- **For Server**: `ZBX_TLSCONNECT`, `ZBX_TLSACCEPT`, `ZBX_TLSCAFILE`, `ZBX_TLSCERTFILE`, `ZBX_TLSKEYFILE`
- **For Database**: `ZBX_DBTLSCONNECT`, `ZBX_DBTLSCAFILE`, `ZBX_DBTLSCERTFILE`, `ZBX_DBTLSKEYFILE`

### Run with Docker Compose

```yaml
services:
  zabbix-proxy:
    image: ghcr.io/monfardinel/zabbix-proxy-pgsql:ubuntu-7.4
    restart: always
    environment:
      - ZBX_HOSTNAME=ZabbixProxy
      - ZBX_SERVER_HOST=zabbix-server.example.com
      - ZBX_DB_TYPE=postgresql
      - ZBX_DB_HOST=postgres-db
      - ZBX_DB_NAME=zabbix_proxy
      - ZBX_DB_USER=zabbix
      - ZBX_DB_PASSWORD=secure_password
    ports:
      - "10051:10051"
```

## 🛠️ Build Locally
If you want to customize the build, you can use the following command:
```bash
docker build \
  --build-arg MAJOR_VERSION=7.4 \
  --build-arg ZBX_VERSION=7.4.8 \
  -t zabbix-proxy-pgsql:local .
```

## ⚖️ License
This project is licensed under the [GNU Affero General Public License v3.0](LICENSE), matching the official Zabbix license to ensure full compliance and alignment with the ecosystem.

