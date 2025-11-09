# Directorio de Backups

⚠️ **IMPORTANTE**: Este directorio está excluido del control de versiones de Git por razones de seguridad y espacio.

## 📋 Propósito

Este directorio es para almacenar backups **locales temporales**. No es para almacenamiento permanente de backups.

## 🔒 Seguridad

- Los backups pueden contener información sensible
- **NUNCA** hagas commit de backups al repositorio Git
- Usa permisos restrictivos: `chmod 700 /path/to/backups`

## 💾 Mejores Prácticas de Backup

### Regla 3-2-1

1. **3 copias** de tus datos
2. En **2 tipos de medios** diferentes
3. **1 copia offsite** (fuera del sitio)

### Ubicaciones Recomendadas

1. **Local** (este directorio): Para respaldos inmediatos y pruebas
2. **Almacenamiento remoto**: NFS, iSCSI, etc.
3. **Offsite/Cloud**: AWS S3, Backblaze B2, otro datacenter

## 📂 Estructura Sugerida

```
backups/
├── vms/              # Backups de VMs
│   └── YYYY-MM-DD/
├── containers/       # Backups de contenedores
│   └── YYYY-MM-DD/
├── configs/          # Backups de configuraciones
│   └── YYYY-MM-DD/
└── README.md         # Este archivo
```

## 🔄 Retención

Ejemplo de política de retención:

- **Diarios**: 7 días
- **Semanales**: 4 semanas
- **Mensuales**: 6 meses
- **Anuales**: 3 años

## ⚙️ Automatización

Usa los scripts en `../scripts/backup/` para automatizar backups:

```bash
# Configurar cron para backups automáticos
crontab -e

# Ejemplo: Backup diario a las 2 AM
0 2 * * * /root/scripts/backup/backup-vms.sh
```

## ✅ Verificación

**Verifica tus backups regularmente**:

1. Haz pruebas de restauración
2. Verifica integridad de archivos
3. Documenta procedimientos de restauración
4. Realiza simulacros de recuperación

## 📝 Registro de Backups

Mantén un log de backups importantes:

| Fecha | Tipo | Descripción | Ubicación | Estado |
|-------|------|-------------|-----------|--------|
| - | - | - | - | - |

## 🚫 Lo que NO Hacer

- ❌ No almacenar backups solo localmente
- ❌ No usar el mismo disco que el sistema
- ❌ No asumir que los backups funcionan sin probarlos
- ❌ No olvidar encriptar backups con datos sensibles
- ❌ No versionar backups en Git

---

**Recuerda**: Un backup que no has probado restaurar es solo un archivo sin verificar.
