# Inventario de Máquinas Virtuales

Este archivo mantiene un registro de todas las VMs en el servidor Proxmox.

## VMs de Producción

| VM ID | Nombre | OS | vCPU | RAM | Disco | IP | Propósito | Estado |
|-------|--------|-------|------|-----|-------|------------|-----------|--------|
| 100 | - | - | - | - | - | - | - | - |

## VMs de Desarrollo

| VM ID | Nombre | OS | vCPU | RAM | Disco | IP | Propósito | Estado |
|-------|--------|-------|------|-----|-------|------------|-----------|--------|
| 200 | - | - | - | - | - | - | - | - |

## Plantillas

| VM ID | Nombre | OS | Descripción | Última Actualización |
|-------|--------|-------|-------------|---------------------|
| 9000 | - | - | - | - |

## Notas

- Actualiza este inventario cada vez que crees, modifiques o elimines una VM
- Mantén las IPs documentadas para evitar conflictos
- Estado puede ser: Activa, Detenida, Template, Archivada

## Ejemplo de Entrada

```markdown
| 101 | web-server-01 | Ubuntu 22.04 | 2 | 4GB | 50GB | 192.168.1.101 | Servidor web principal | Activa |
```
