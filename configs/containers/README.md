# Configuraciones de Contenedores LXC / Container Configurations

Este directorio contiene las configuraciones y plantillas de contenedores LXC.

## 📁 Archivos en este Directorio

- **`inventory.md`**: Inventario completo de todos los contenedores LXC con IPs, recursos y propósito
- **`docker-stacks.md`**: Documentación detallada de todos los stacks de Docker desplegados en LXC
- **`lxc-105-uptimekuma.conf.example`**: Configuración completa de ejemplo del contenedor Uptime Kuma

## 🌐 Contenedores Actuales en el Cluster

### Nodo: proxmox (192.168.1.78)
- **LXC 100** (proxy): Nginx Proxy Manager, Cloudflared - `192.168.1.100`
- **LXC 101** (apps): Vaultwarden - `192.168.1.101`
- **LXC 102** (media): Immich (fotos) - `192.168.1.102`
- **LXC 103** (adguard): AdGuard Home DNS - `192.168.1.120`
- **LXC 105** (uptimekuma): Uptime Kuma monitoring - `192.168.1.70`

### Nodo: proxmedia (192.168.1.82)
- **LXC 200** (mediaserver): Jellyfin + *arr stack - `192.168.1.50`

Ver detalles completos en `inventory.md`

## Estructura

Organiza los contenedores por propósito:
- `production/`: Contenedores de producción
- `development/`: Contenedores de desarrollo
- `templates/`: Plantillas de contenedores

## Archivos de Configuración de Contenedores

Las configuraciones de contenedores se almacenan en `/etc/pve/lxc/` en el servidor Proxmox.

### Formato de Configuración

```
# Container 100 - Ejemplo
arch: amd64
cores: 2
hostname: ct-ejemplo
memory: 2048
net0: name=eth0,bridge=vmbr0,ip=192.168.1.100/24,gw=192.168.1.1
ostype: ubuntu
rootfs: local-lvm:vm-100-disk-0,size=8G
swap: 512
```

## Ventajas de LXC vs VMs

- **Ligeros**: Menor uso de recursos
- **Rápidos**: Inicio casi instantáneo
- **Eficientes**: Mejor densidad por hardware
- **Limitaciones**: Comparten kernel con el host

## Cuándo Usar Contenedores

✅ **Usar LXC para:**
- Servicios web
- Bases de datos
- Servidores de aplicaciones
- Servicios de red

❌ **Usar VM para:**
- Sistemas operativos diferentes al host
- Kernel personalizado
- Requisitos de aislamiento estricto

## Mejores Prácticas

1. **Privilegiados vs No-privilegiados**: Prefiere contenedores no-privilegiados por seguridad
2. **Recursos**: Los contenedores usan menos que VMs, ajusta apropiadamente
3. **Almacenamiento**: Usa directorios para contenedores que no requieren alto I/O
4. **Plantillas**: Descarga plantillas oficiales desde Proxmox

## Comandos Útiles

```bash
# Listar contenedores
pct list

# Ver configuración
pct config <ctid>

# Iniciar/Detener contenedor
pct start <ctid>
pct stop <ctid>

# Entrar al contenedor
pct enter <ctid>

# Crear snapshot
pct snapshot <ctid> <snapshot-name>

# Restaurar desde plantilla
pct restore <ctid> <backup-file>
```

## Descargar Plantillas

```bash
# Listar plantillas disponibles
pveam available

# Descargar plantilla
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst
```
