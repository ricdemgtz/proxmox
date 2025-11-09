# Configuraciones de Contenedores LXC / Container Configurations

Este directorio contiene las configuraciones y plantillas de contenedores LXC.

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
