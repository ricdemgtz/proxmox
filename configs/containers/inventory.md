# Inventario de Contenedores LXC

Este archivo mantiene un registro de todos los contenedores en el servidor Proxmox.

## Contenedores de Producción

| CT ID | Nombre | OS | vCPU | RAM | Disco | IP | Propósito | Privilegiado | Estado |
|-------|--------|---------|------|-----|-------|------------|-----------|--------------|--------|
| 100 | - | - | - | - | - | - | - | No | - |

## Contenedores de Desarrollo

| CT ID | Nombre | OS | vCPU | RAM | Disco | IP | Propósito | Privilegiado | Estado |
|-------|--------|---------|------|-----|-------|------------|-----------|--------------|--------|
| 200 | - | - | - | - | - | - | - | No | - |

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
