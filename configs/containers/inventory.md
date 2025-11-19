# Inventario de Contenedores LXC

Este archivo mantiene un registro de todos los contenedores en el servidor Proxmox.

## Contenedores de Producción

| CT ID | Nombre | OS | vCPU | RAM | Disco | IP Local | IP Tailscale | Propósito | Privilegiado | Estado | Tags | Nodo | Docker Stack |
|-------|--------|---------|------|-----|-------|----------|--------------|-----------|--------------|--------|------|------|--------------|
| 100 | proxy | Debian | 4 | 4092MB | - | 192.168.1.100 | - | Reverse proxy y túneles | No | Activo | proxy | proxmox | nginx-proxy-manager, cloudflared, portainer, helloworld |
| 101 | apps | Debian | 2 | 4096MB | - | 192.168.1.101 | - | Aplicaciones varias | No | Activo | - | proxmox | vaultwarden, portainer |
| 102 | media | Debian | 4 | 8192MB | - | 192.168.1.102 | - | Gestión de fotos | No | Activo | - | proxmox | immich (server, db, redis, ML), portainer |
| 103 | adguard | Debian | 2 | 1024MB | - | 192.168.1.120 | 100.109.98.48 | DNS bloqueador de ads | No | Activo | adblock;community-script | proxmox | AdGuard Home |
| 105 | uptimekuma | Debian | 1 | 1024MB | 16GB | 192.168.1.70 | 100.101.238.45 | Monitoreo de servicios | No | Activo | analytics;community-script;monitoring | proxmox | Uptime Kuma |

## Contenedores de Desarrollo

| CT ID | Nombre | OS | vCPU | RAM | Disco | IP Local | IP Tailscale | Propósito | Privilegiado | Estado | Tags | Nodo | Docker Stack |
|-------|--------|---------|------|-----|-------|----------|--------------|-----------|--------------|--------|------|------|--------------|
| 200 | proxmedia | mediaserver | 192.168.1.50 | 100.68.73.113 | 4 | 8192 | 1000 | Docker: Jellyfin + *arr stack + qBittorrent | Unprivileged | media, docker |
| 205 | proxmedia | uptimekuma-backup | 192.168.1.71 | TBD | 1 | 1024 | 16 | Uptime Kuma (respaldo/standby de LXC 105) | Unprivileged | monitoring, backup, standby |

---

## Plantillas Disponibles

| Template | OS/Versión | Descarga | Última Actualización |
|----------|------------|----------|---------------------|
| - | - | - | - |

## Notas

- Actualiza este inventario cada vez que crees, modifiques o elimines un contenedor
- Documenta si el contenedor es privilegiado (requiere justificación de seguridad)
- Mantén las IPs documentadas para evitar conflictos
- Estado puede ser: Activo, Detenido, Template, Archivado

## Ejemplo de Entrada

```markdown
| 101 | web-nginx | Ubuntu 22.04 | 1 | 1GB | 8GB | 192.168.1.101 | Servidor web Nginx | No | Activo |
```

## Plantillas Comunes

Plantillas oficiales más utilizadas:
- `ubuntu-22.04-standard` - Ubuntu 22.04 LTS
- `debian-12-standard` - Debian 12
- `alpine-3.18-default` - Alpine Linux (ultra ligero)
- `centos-9-stream-default` - CentOS Stream 9
