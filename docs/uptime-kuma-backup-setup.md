# Configuración de Uptime Kuma - Respaldo en Nodo Secundario

Guía para crear un LXC de respaldo de Uptime Kuma en el nodo `proxmedia`.

## 📋 Estado Actual

**LXC 105 (Principal) - Nodo proxmox**
- **IP Local**: 192.168.1.70
- **IP Tailscale**: 100.101.238.45
- **Puerto**: 3001
- **Instalación**: Nativa con Node.js (NO Docker)
- **Servicio**: systemd `uptime-kuma.service`
- **Datos**: `/opt/uptime-kuma/`
- **Script origen**: Community Scripts ProxmoxVE

## 🎯 Objetivo

Crear **LXC 205** en el nodo `proxmedia` como respaldo de Uptime Kuma.

**✅ Estado Actual: COMPLETADO**
- LXC 205 creado exitosamente en proxmedia
- IP asignada: 192.168.1.71
- Servicio corriendo en puerto 3001
- Pendiente: Sincronización inicial de datos

---

## 🚀 Método 1: Clonar LXC Existente (Recomendado)

### Paso 1: Detener LXC 105 temporalmente

```bash
# En nodo proxmox (192.168.1.78)
pct stop 105
```

### Paso 2: Crear backup del LXC 105

```bash
# Backup con compresión zstd
vzdump 105 --mode stop --compress zstd --dumpdir /var/lib/vz/dump

# Ver el archivo creado
ls -lh /var/lib/vz/dump/vzdump-lxc-105-*.tar.zst
```

### Paso 3: Copiar backup al nodo proxmedia

```bash
# Desde proxmox, copiar a proxmedia
scp /var/lib/vz/dump/vzdump-lxc-105-*.tar.zst root@192.168.1.82:/var/lib/vz/dump/
```

### Paso 4: Restaurar en el nodo proxmedia como LXC 205

```bash
# Conectar a proxmedia
ssh root@192.168.1.82

# Restaurar con nuevo ID
pct restore 205 /var/lib/vz/dump/vzdump-lxc-105-*.tar.zst \
  --storage local-lvm \
  --hostname uptimekuma-backup \
  --unprivileged 1

# Verificar que se creó
pct list | grep 205
```

### Paso 5: Modificar configuración de red del LXC 205

```bash
# En proxmedia
# Editar para cambiar IP
nano /etc/pve/lxc/205.conf

# Cambiar la línea de red a IP estática:
# net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:CA:F1:FD,ip=192.168.1.71/24,gw=192.168.1.254,type=veth

# O dejar DHCP pero con MAC diferente para evitar conflictos
# net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:CA:F1:FD,ip=dhcp,ip6=auto,type=veth
```

### Paso 6: Iniciar LXC 205 y verificar

```bash
# Iniciar el contenedor
pct start 205

# Verificar estado
pct status 205

# Ver IP asignada
pct exec 205 -- ip addr show eth0

# Verificar que Uptime Kuma está corriendo
pct exec 205 -- systemctl status uptime-kuma

# Verificar puerto
pct exec 205 -- ss -tlnp | grep 3001
```

### Paso 7: Reinstalar Tailscale en LXC 205 (opcional)

```bash
# Entrar al contenedor
pct enter 205

# Reinstalar Tailscale con nueva identidad
curl -fsSL https://tailscale.com/install.sh | sh

# Autenticar (generará nueva IP Tailscale)
tailscale up

# Salir del contenedor
exit
```

### Paso 8: Reiniciar LXC 105

```bash
# En proxmox
ssh root@192.168.1.78
pct start 105
```

---

## 🔧 Método 2: Instalación Limpia con Community Script

Si prefieres una instalación desde cero:

### Paso 1: Conectar a proxmedia

```bash
ssh root@192.168.1.82
```

### Paso 2: Descargar y ejecutar Community Script

```bash
# Descargar el script de Uptime Kuma
bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/ct/uptimekuma.sh)"
```

El script te preguntará:
- **CT ID**: Ingresa `205`
- **Hostname**: Ingresa `uptimekuma-backup`
- **Disk Size**: `16` GB (igual al original)
- **CPU Cores**: `1`
- **RAM**: `1024` MB
- **Bridge**: `vmbr0`
- **IP Config**: `dhcp` o `192.168.1.71/24`
- **Gateway**: `192.168.1.1`
- **Start on Boot**: `yes`

### Paso 3: Verificar instalación

```bash
pct list | grep 205
pct status 205
pct exec 205 -- systemctl status uptime-kuma
```

---

## 📁 Sincronización de Datos entre LXC 105 y 205

### ⚠️ IMPORTANTE: Filesystem de LXC

**Los LXC unprivileged NO montan su filesystem en `/var/lib/lxc/X/rootfs/` cuando están detenidos**. Por lo tanto:

❌ **NO funciona**: Acceder a `/var/lib/lxc/105/rootfs/opt/` con el LXC detenido  
✅ **SÍ funciona**: Usar `pct exec` o `tar` con los LXC corriendo

---

### ✅ Método Recomendado: Tar sobre SSH

**Este método usa `tar` (ya instalado) y funciona con LXC unprivileged corriendo:**

```bash
# Iniciar ambos contenedores
pct start 105
ssh root@192.168.1.82 "pct start 205"

# Esperar a que inicien completamente
sleep 5

# Detener servicios (mantener LXC corriendo)
pct exec 105 -- systemctl stop uptime-kuma
ssh root@192.168.1.82 "pct exec 205 -- systemctl stop uptime-kuma"

# Sincronizar datos con tar sobre SSH (no requiere rsync)
pct exec 105 -- tar czf - -C /opt/uptime-kuma data/ | \
  ssh root@192.168.1.82 "pct exec 205 -- tar xzf - -C /opt/uptime-kuma"

# Reiniciar servicios
pct exec 105 -- systemctl start uptime-kuma
ssh root@192.168.1.82 "pct exec 205 -- systemctl start uptime-kuma"

# Verificar estado
pct exec 105 -- systemctl status uptime-kuma --no-pager
ssh root@192.168.1.82 "pct exec 205 -- systemctl status uptime-kuma --no-pager"
```

**Ventajas de este método:**
- ✅ Funciona con LXC unprivileged
- ✅ No requiere instalar paquetes adicionales
- ✅ Comprime datos durante transferencia (más rápido)
- ✅ Mantiene permisos y timestamps
- ✅ Una sola línea de comando

### Script Automatizado de Sincronización

Crear un script en el nodo proxmox que sincroniza usando tar:

```bash
# Crear script de sincronización
cat > /root/sync-uptimekuma.sh << 'EOF'
#!/bin/bash
# Sincronizar Uptime Kuma de LXC 105 a LXC 205

LOG_FILE="/var/log/uptimekuma-sync.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "===== Iniciando sincronización de Uptime Kuma ====="

# Asegurar que ambos LXC están corriendo
log "Verificando estado de LXC..."
pct start 105 2>/dev/null || log "LXC 105 ya estaba corriendo"
ssh root@192.168.1.82 "pct start 205" 2>/dev/null || log "LXC 205 ya estaba corriendo"

# Esperar a que inicien
sleep 5

# Detener servicios (mantener LXC corriendo)
log "Deteniendo servicio Uptime Kuma en LXC 105..."
pct exec 105 -- systemctl stop uptime-kuma

log "Deteniendo servicio Uptime Kuma en LXC 205..."
ssh root@192.168.1.82 "pct exec 205 -- systemctl stop uptime-kuma"

# Sincronizar datos con tar sobre SSH
log "Sincronizando datos..."
pct exec 105 -- tar czf - -C /opt/uptime-kuma data/ | \
  ssh root@192.168.1.82 "pct exec 205 -- tar xzf - -C /opt/uptime-kuma"

if [ $? -eq 0 ]; then
    log "Sincronización completada exitosamente"
else
    log "ERROR: Falló la sincronización"
fi

# Reiniciar servicios
log "Reiniciando servicio Uptime Kuma en LXC 105..."
pct exec 105 -- systemctl start uptime-kuma

log "Reiniciando servicio Uptime Kuma en LXC 205..."
ssh root@192.168.1.82 "pct exec 205 -- systemctl start uptime-kuma"

log "===== Sincronización completada ====="
EOF

# Dar permisos de ejecución
chmod +x /root/sync-uptimekuma.sh

# Probar el script
/root/sync-uptimekuma.sh
```

### Programar Sincronización Automática

```bash
# En proxmox, agregar cron job
crontab -e

# Agregar línea para sincronizar diariamente a las 3 AM
0 3 * * * /root/sync-uptimekuma.sh
```

---

## 🔄 Failover Manual

### Si LXC 105 falla, activar LXC 205:

```bash
# 1. Actualizar NPM (LXC 100) para apuntar al respaldo
# En LXC 100, cambiar proxy de uptimekuma de:
# 192.168.1.70:3001 → 192.168.1.71:3001

# 2. O usar Tailscale para apuntar a la nueva IP
```

---

## 📊 Tabla de Configuración

| Parámetro | LXC 105 (Principal) | LXC 205 (Respaldo) |
|-----------|---------------------|---------------------|
| **Nodo** | proxmox | proxmedia |
| **IP Local** | 192.168.1.70 | 192.168.1.71 ✅ |
| **IP Tailscale** | 100.101.238.45 | (Pendiente config) |
| **Hostname** | uptimekuma | uptimekuma-backup ✅ |
| **Puerto** | 3001 | 3001 ✅ |
| **vCPU** | 1 | 1 ✅ |
| **RAM** | 1024MB | 1024MB ✅ |
| **Disco** | 16GB | 16GB ✅ |
| **Estado** | Activo | Standby ✅ |

---

## ✅ Checklist Post-Instalación

- [x] LXC 205 creado en proxmedia
- [x] IP configurada (192.168.1.71)
- [x] Uptime Kuma corriendo en puerto 3001
- [x] Datos sincronizados desde LXC 105 ✅
- [ ] Tailscale configurado (opcional)
- [x] Script de sincronización creado (`/root/sync-uptimekuma.sh`)
- [ ] Cron job programado (opcional - ejecutar `/root/sync-uptimekuma.sh`)
- [ ] Acceso web verificado: http://192.168.1.71:3001
- [x] Documentado en `configs/containers/inventory.md` ✅

---

## 🔧 Comandos de Sincronización Rápida

Una vez que LXC 205 está creado, ejecuta esto en el nodo **proxmox** para sincronizar:

```bash
# Sincronización rápida con tar (método recomendado)
pct start 105
ssh root@192.168.1.82 "pct start 205"
sleep 5

pct exec 105 -- systemctl stop uptime-kuma
ssh root@192.168.1.82 "pct exec 205 -- systemctl stop uptime-kuma"

pct exec 105 -- tar czf - -C /opt/uptime-kuma data/ | \
  ssh root@192.168.1.82 "pct exec 205 -- tar xzf - -C /opt/uptime-kuma"

pct exec 105 -- systemctl start uptime-kuma
ssh root@192.168.1.82 "pct exec 205 -- systemctl start uptime-kuma"

# Verificar que ambos están corriendo
pct exec 105 -- systemctl status uptime-kuma --no-pager
ssh root@192.168.1.82 "pct exec 205 -- systemctl status uptime-kuma --no-pager"
```

---

## 🚨 Troubleshooting

### Error: "No such file or directory" al acceder a /var/lib/lxc/X/rootfs/

```
rsync: change_dir "/var/lib/lxc/105/rootfs/opt/uptime-kuma/data" failed: No such file or directory
```

**Causa**: Los LXC unprivileged NO montan su filesystem en `/var/lib/lxc/X/rootfs/` cuando están **detenidos**.

**Solución**: Usa el método con `tar` y `pct exec` con los LXC **corriendo** (ver sección anterior).

---

### Error: "Operation not permitted" al instalar paquetes

```
Error: setgroups 65534 failed - setgroups (1: Operation not permitted)
Error: Could not open file - open (13: Permission denied)
```

**Causa**: El LXC es **unprivileged** (más seguro), lo que limita operaciones con permisos elevados.

**Solución**: ❌ NO hagas el LXC privileged por seguridad. Usa el método con `tar` que no requiere instalar nada adicional.

---

### LXC 205 no inicia
```bash
# Ver logs
pct exec 205 -- journalctl -xe

# Verificar configuración
pct config 205
```

### Uptime Kuma no arranca
```bash
# Ver status del servicio
pct exec 205 -- systemctl status uptime-kuma

# Ver logs
pct exec 205 -- journalctl -u uptime-kuma -f
```

### Conflicto de IP
```bash
# Cambiar a IP estática
nano /etc/pve/lxc/205.conf
# Editar net0 con IP diferente
pct reboot 205
```

### Puerto 3001 no responde
```bash
# Verificar que el proceso está corriendo
pct exec 205 -- ps aux | grep node

# Verificar puerto
pct exec 205 -- ss -tlnp | grep 3001

# Reiniciar servicio
pct exec 205 -- systemctl restart uptime-kuma
```

### Error de sincronización "rsync: command not found" en host

Si el comando `rsync` no existe en el **host Proxmox**:

```bash
# Instalar rsync en el HOST Proxmox (no en el LXC)
apt update && apt install -y rsync
```

**Nota**: Proxmox VE normalmente incluye rsync por defecto. **Sin embargo, el método con `tar` es preferible** ya que no depende de rsync.

---

**Última actualización**: 2025-11-19
**Autor**: Ricardo Gutierrez
**Cluster**: proxmedia
