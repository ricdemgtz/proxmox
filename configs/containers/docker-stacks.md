# Docker Stacks en Contenedores LXC

Este documento detalla todos los stacks de Docker desplegados en los contenedores LXC del cluster.

## 📋 Resumen de Contenedores con Docker

| LXC ID | Nombre | IP Local | IP Tailscale | Contenedores Docker | Propósito Principal |
|--------|--------|----------|--------------|---------------------|---------------------|
| 100 | proxy | 192.168.1.100 | - | 4 | Reverse proxy y túneles Cloudflare |
| 101 | apps | 192.168.1.101 | - | 2 | Gestión de contraseñas (Vaultwarden) |
| 102 | media | 192.168.1.102 | - | 5 | Gestión de fotos (Immich) |
| 103 | adguard | 192.168.1.120 | 100.109.98.48 | - | DNS con bloqueo de ads |
| 105 | uptimekuma | 192.168.1.70 | 100.101.238.45 | - | Monitoreo de servicios |
| 200 | mediaserver | 192.168.1.50 | 100.78.240.75 | 8 | Media server completo (Jellyfin + *arr) |

### 🌍 Dominios Públicos Configurados (*.disccheep.com)

Todos accesibles vía túnel Cloudflare a través de LXC 100 (proxy):

| Dominio | Servicio | IP Destino | Puerto | SSL |
|---------|----------|------------|--------|-----|
| nas.disccheep.com | NAS Storage | 196.168.1.100 | 80 | ❌ |
| pmv.disccheep.com | Proxmox Web UI | 192.168.1.78 | 8006 | ✅ |
| vault.disccheep.com | Vaultwarden | 192.168.1.101 | 8080 | ❌ |
| immich.disccheep.com | Immich | 192.168.1.100* | 80 | ❌ |
| fin.disccheep.com | Jellyfin | 192.168.1.50 | 8096 | ❌ |

**⚠️ Correcciones pendientes**: 
- immich.disccheep.com debe apuntar a 192.168.1.102:2283 (no .100:80)

---

## 🌐 LXC 100: proxy (192.168.1.100)

**Propósito**: Reverse proxy centralizado y túneles Cloudflare

### Contenedores Docker

| Contenedor | Imagen | Puertos | Estado | Propósito |
|------------|--------|---------|--------|-----------|
| nginx-proxy-manager | jc21/nginx-proxy-manager:latest | 80-81, 443 | Healthy | Gestión de proxy reverso con SSL |
| cloudflared | cloudflare/cloudflared:latest | 9090 (local) | Running | Túnel Cloudflare para acceso externo |
| portainer | portainer/portainer-ce:latest | 8000, 9443 | Running | Gestión de contenedores Docker |
| helloworld | karthequian/helloworld:latest | 80 | Running | Contenedor de prueba |

### Redes Docker
- `proxy_proxy_net` (bridge)
- `bridge` (default)

### Volúmenes
- `proxy_npm_data` - Datos de Nginx Proxy Manager
- `proxy_npm_letsencrypt` - Certificados SSL Let's Encrypt
- `portainer_data` - Datos de Portainer

### Características Especiales
- **Host Network Binding**: NPM se bindea directamente a la IP del LXC (192.168.1.100:80-81, 443)
- **Cloudflared**: Túnel en localhost:9090 para acceso externo seguro
- **Restart Policy**: `unless-stopped` para todos excepto Portainer

---

## 🔐 LXC 101: apps (192.168.1.101)

**Propósito**: Alojamiento de aplicaciones empresariales

### Contenedores Docker

| Contenedor | Imagen | Puertos | Estado | Propósito |
|------------|--------|---------|--------|-----------|
| vaultwarden | vaultwarden/server:latest | 8080:80 | Unhealthy* | Gestor de contraseñas compatible con Bitwarden |
| portainer | portainer/portainer-ce:latest | 9443 | Running | Gestión de contenedores |

**Nota**: Vaultwarden aparece como "unhealthy" - revisar healthcheck

### Redes Docker
- `vault_default` (bridge)
- `bridge` (default)

### Volúmenes
- `portainer_data` - Datos de Portainer

### Características Especiales
- **Port Binding**: Vaultwarden mapeado a 192.168.1.101:8080
- **Acceso**: Probablemente accesible vía NPM en el LXC 100

---

## 📸 LXC 102: media (192.168.1.102)

**Propósito**: Gestión de fotos y medios personales con Immich

### Contenedores Docker

| Contenedor | Imagen | Puertos | Estado | Propósito |
|------------|--------|---------|--------|-----------|
| immich-immich-server-1 | ghcr.io/immich-app/immich-server:v1.143.0 | 2283 | Healthy | Servidor principal de Immich |
| immich-immich-db-1 | ghcr.io/immich-app/postgres:16-vectorchord0.3.0-pgvectors0.3.0 | 5432 | Healthy | Base de datos PostgreSQL con extensiones de vectores |
| immich-immich-redis-1 | redis:7-alpine | 6379 | Healthy | Cache Redis |
| immich-immich-machine-learning-1 | ghcr.io/immich-app/immich-machine-learning:v1.143.0 | - | Healthy | ML para reconocimiento facial y objetos |
| portainer | portainer/portainer-ce:latest | 9443 | Running | Gestión de contenedores |

### Redes Docker
- `immich_immich-net` (bridge) - Red dedicada para el stack de Immich
- `immich-net` (bridge) - Red adicional
- `bridge` (default)

### Volúmenes
- Volúmenes con hash para persistencia de Immich
- `portainer_data` - Datos de Portainer

### Características Especiales
- **Versión**: Immich v1.143.0
- **ML Capabilities**: Reconocimiento facial y clasificación de objetos
- **PostgreSQL**: Versión especializada con extensiones vectoriales para búsquedas de similitud
- **Port Binding**: Servidor accesible en 192.168.1.102:2283
- **Health Checks**: Todos los servicios reportan healthy

---

## 🎬 LXC 200: mediaserver (192.168.1.50)

**Propósito**: Media server completo con gestión automática de contenido

### Contenedores Docker

| Contenedor | Imagen | Puertos | Estado | Propósito |
|------------|--------|---------|--------|-----------|
| jellyfin | lscr.io/linuxserver/jellyfin:latest | 8096, 8920 | Running | Servidor de streaming de medios |
| jellyseerr | fallenbagel/jellyseerr:latest | 5055 | Running | Gestión de peticiones de contenido |
| radarr | lscr.io/linuxserver/radarr:latest | 7878 | Running | Gestor automático de películas |
| sonarr | lscr.io/linuxserver/sonarr:latest | 8989 | Running | Gestor automático de series |
| prowlarr | lscr.io/linuxserver/prowlarr:latest | 9696 | Running | Gestor de indexers/trackers |
| bazarr | lscr.io/linuxserver/bazarr:latest | 6767 | Running | Gestor automático de subtítulos |
| qbittorrent | lscr.io/linuxserver/qbittorrent:latest | 6881 (TCP/UDP), 8080 | Running | Cliente BitTorrent |
| portainer | portainer/portainer-ce:latest | - | Running | Gestión de contenedores |

### Redes Docker
- `mediaserver_default` (bridge) - Red compartida del stack
- `bridge` (default)

### Volúmenes
- `portainer_data` - Datos de Portainer

### Arquitectura del Stack
```
Internet → Prowlarr (indexers) → Radarr/Sonarr (búsqueda) → qBittorrent (descarga)
                                          ↓
                                    Jellyfin (reproducción)
                                          ↑
                                    Bazarr (subtítulos)
                                          ↑
                                  Jellyseerr (peticiones de usuarios)
```

### Port Mappings Completos
- **Jellyfin**: 192.168.1.50:8096 (HTTP), 8920 (HTTPS)
- **Jellyseerr**: 192.168.1.50:5055
- **Radarr**: 192.168.1.50:7878
- **Sonarr**: 192.168.1.50:8989
- **Prowlarr**: 192.168.1.50:9696
- **Bazarr**: 192.168.1.50:6767
- **qBittorrent**: 192.168.1.50:8080 (WebUI), 6881 (BT)

### Características Especiales
- **LinuxServer Images**: Todas las aplicaciones *arr usan imágenes de LinuxServer.io
- **Restart Policy**: `unless-stopped` para todos los servicios
- **Network Mode**: Todos en la misma red Docker para comunicación interna
- **Portainer**: Restart policy `always`

---

## 🔧 Configuración General de LXC para Docker

Todos los contenedores LXC tienen estas características comunes para soportar Docker:

```conf
features: keyctl=1,nesting=1,fuse=1
lxc.apparmor.profile: unconfined
lxc.cgroup2.devices.allow: a
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

### ¿Por qué estas configuraciones?

- **nesting=1**: Permite ejecutar contenedores dentro del contenedor LXC
- **keyctl=1**: Soporte para keyrings del kernel (requerido por algunos servicios)
- **fuse=1**: Soporte para sistemas de archivos FUSE
- **apparmor unconfined**: Desactiva restricciones AppArmor para compatibilidad con Docker
- **cgroup2.devices.allow: a**: Permite acceso a todos los dispositivos
- **/dev/net/tun**: Necesario para VPNs y túneles de red

---

## 📊 Estadísticas de Recursos

| LXC | vCPU | RAM | Contenedores Docker | Uso Estimado |
|-----|------|-----|---------------------|--------------|
| 100 (proxy) | 4 | 4GB | 4 | Medio |
| 101 (apps) | 2 | 4GB | 2 | Bajo |
| 102 (media) | 4 | 8GB | 5 | Alto (ML) |
| 200 (mediaserver) | 4 | 8GB | 8 | Alto |
| **TOTAL** | **14** | **24GB** | **19** | - |

---

## 🔍 Comandos Útiles

### Inspeccionar contenedores Docker desde Proxmox

```bash
# Ver contenedores en LXC 100 (proxy)
pct exec 100 -- docker ps

# Ver logs de nginx-proxy-manager
pct exec 100 -- docker logs nginx-proxy-manager

# Entrar a un contenedor específico
pct exec 100 -- docker exec -it nginx-proxy-manager sh
```

### Reiniciar stacks completos

```bash
# Reiniciar todos los contenedores de mediaserver
pct exec 200 -- docker restart $(docker ps -q)

# Reiniciar solo Jellyfin
pct exec 200 -- docker restart jellyfin
```

### Ver estado de salud

```bash
# Ver contenedores con health checks
pct exec 102 -- docker ps --filter "health=healthy"
pct exec 102 -- docker ps --filter "health=unhealthy"
```

---

## 📝 Notas Importantes

1. **Portainer Duplicado**: Cada LXC tiene su propia instancia de Portainer en el puerto 9443
2. **Redes Aisladas**: Los stacks usan redes bridge propias para aislar el tráfico
3. **Restart Policies**: Casi todos usan `unless-stopped` para auto-reinicio
4. **Bind Mounts**: Las IPs de LXC se usan directamente en los bindings de puertos
5. **Vaultwarden Unhealthy**: Requiere investigación y posible reconfiguración del healthcheck

---

**Última actualización**: 2025-11-19
**Nodos del cluster**: proxmox (192.168.1.78), proxmedia (192.168.1.82)
