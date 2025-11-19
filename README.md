# Proxmox Cluster Management Repository

Este repositorio contiene toda la configuración, scripts y documentación para la gestión del **cluster Proxmox "proxmedia"**.

## 🏗️ Cluster Proxmedia

**Cluster de 2 nodos** con alta disponibilidad:
- **Nodo 1** (proxmox): `192.168.1.78` - 5 LXC + 1 VM
- **Nodo 2** (proxmedia): `192.168.1.82` - 1 LXC

**Servicios desplegados**: 6 contenedores LXC con 19 contenedores Docker ejecutándose
- Reverse Proxy (Nginx Proxy Manager + Cloudflare)
- Media Server (Jellyfin + Radarr + Sonarr + Prowlarr + Bazarr + qBittorrent)
- Photo Management (Immich)
- Password Manager (Vaultwarden)
- DNS Ad-Blocker (AdGuard Home)
- Monitoring (Uptime Kuma)
- Home Automation (Home Assistant OS)

Ver documentación completa en:
- 📋 **Inventario**: `configs/containers/inventory.md` y `configs/vms/inventory.md`
- 🐳 **Docker Stacks**: `configs/containers/docker-stacks.md`
- 🌐 **Arquitectura de Red**: `docs/network-architecture.md`

## 📁 Estructura del Repositorio

```
proxmox/
├── configs/              # Archivos de configuración
│   ├── network/         # Configuraciones de red
│   ├── storage/         # Configuraciones de almacenamiento
│   ├── vms/            # Configuraciones de máquinas virtuales
│   └── containers/     # Configuraciones de contenedores LXC
├── scripts/             # Scripts de automatización
│   ├── backup/         # Scripts de respaldo
│   ├── monitoring/     # Scripts de monitoreo
│   └── maintenance/    # Scripts de mantenimiento
├── docs/               # Documentación
└── backups/            # Directorio para backups (excluido del git)
```

## 🚀 Uso

### Configuraciones

Las configuraciones están organizadas por categoría en el directorio `configs/`. Cada subdirectorio contiene:

- **network/**: Configuraciones de red (interfaces, bridges, vlans)
- **storage/**: Configuraciones de almacenamiento (NFS, iSCSI, local)
- **vms/**: Definiciones y configuraciones de VMs
- **containers/**: Definiciones y configuraciones de contenedores LXC

### Scripts

Los scripts están organizados en el directorio `scripts/`:

- **backup/**: Scripts para realizar respaldos automáticos
- **monitoring/**: Scripts para monitoreo del sistema
- **maintenance/**: Scripts para tareas de mantenimiento

### Documentación

La documentación completa del servidor y sus servicios se encuentra en el directorio `docs/`.

## 🔒 Seguridad

**IMPORTANTE**: Este repositorio NO debe contener:
- Claves privadas
- Certificados
- Contraseñas
- Tokens de acceso
- Información sensible

Estos archivos están excluidos en `.gitignore`. Utiliza un gestor de secretos apropiado para información sensible.

## 📝 Contribución

Para agregar o modificar configuraciones:

1. Crea una rama para tus cambios
2. Documenta los cambios en los archivos README correspondientes
3. Haz commit de los cambios con mensajes descriptivos
4. Mantén la estructura organizada

## 📋 Requisitos

- Proxmox VE 7.x o superior
- Acceso SSH al servidor
- Permisos de administrador

## 🔄 Backup

Los backups NO se versionan en Git. Utiliza los scripts en `scripts/backup/` para gestionar respaldos y almacénalos en ubicaciones seguras fuera del repositorio.

## 📖 Documentación Adicional

Consulta el directorio `docs/` para documentación detallada sobre:
- **Configuración inicial del servidor** (`setup-guide.md`)
- **Arquitectura de red completa** (`network-architecture.md`) ⭐ NUEVO
- **Recreación del cluster** (`cluster-recreation-guide.md`)
- **Procedimientos de respaldo y recuperación** (`backup-recovery.md`)
- **Guías de troubleshooting** (`troubleshooting.md`)
- **Mejores prácticas de seguridad** (`security-best-practices.md`)
- **Especificaciones de hardware** (`hardware-specs.md`)

### Documentación de Contenedores

- **Inventario de LXC**: `configs/containers/inventory.md`
- **Docker Stacks**: `configs/containers/docker-stacks.md` ⭐ NUEVO
- **Configuración Uptime Kuma**: `configs/containers/lxc-105-uptimekuma.conf.example` ⭐ NUEVO

---

**Última actualización**: 2025-11-19
**Cluster**: proxmedia (2 nodos)
**Administrador**: Ricardo Gutierrez