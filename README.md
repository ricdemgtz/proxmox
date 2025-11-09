# Proxmox Server Management Repository

Este repositorio contiene toda la configuración, scripts y documentación para la gestión del servidor Proxmox.

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
- Configuración inicial del servidor
- Procedimientos de respaldo y recuperación
- Guías de troubleshooting
- Mejores prácticas

---

**Última actualización**: 2025-11-09