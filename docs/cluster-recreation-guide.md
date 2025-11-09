# Guía: Eliminar y Recrear Cluster Proxmox

Esta guía documenta el proceso completo para eliminar un cluster Proxmox existente y crear uno nuevo desde cero.

## ⚠️ ADVERTENCIAS CRÍTICAS

### ANTES DE EMPEZAR - LEE ESTO
- ✋ **ESTA OPERACIÓN ES DESTRUCTIVA**: Las VMs/Contenedores NO se perderán, pero la configuración del cluster sí
- 🔴 **BACKUP OBLIGATORIO**: Haz backup de TODAS las VMs y contenedores importantes
- 🔴 **BACKUP DE CONFIGURACIONES**: Respalda `/etc/pve/` antes de proceder
- 🔴 **DOWNTIME**: Habrá tiempo de inactividad durante el proceso
- 🔴 **PREPARACIÓN**: Lee TODA la guía antes de ejecutar comandos
- 🔴 **NO INTERRUMPIR**: Una vez iniciado, completa todo el proceso

### Requisitos Previos
- [ ] Acceso físico o IPMI a ambos nodos (por si pierdes acceso SSH)
- [ ] Backups completos de todas las VMs/Contenedores críticos
- [ ] Backup de `/etc/pve/` de ambos nodos
- [ ] Backup de `/etc/network/interfaces` de ambos nodos
- [ ] Lista de todas las VMs y Contenedores con sus IDs
- [ ] Documentación de IPs y configuración de red
- [ ] Tiempo estimado: 1-2 horas

---

## 📋 Fase 0: PREPARACIÓN Y BACKUPS

### 1. Documentar Estado Actual

En **cada nodo**, ejecuta y guarda la salida:

```bash
# Estado del cluster
pvecm status > /root/cluster-status-before.txt
pvecm nodes >> /root/cluster-status-before.txt

# Lista de VMs y Contenedores
qm list > /root/vms-before.txt
pct list > /root/containers-before.txt

# Configuración de storage
pvesm status > /root/storage-before.txt
cat /etc/pve/storage.cfg > /root/storage-cfg-before.txt

# Configuración de red
cat /etc/network/interfaces > /root/interfaces-before.txt

# Información del cluster
cat /etc/pve/corosync.conf > /root/corosync-before.txt 2>/dev/null || echo "No cluster config"
```

### 2. Backup de Configuraciones Críticas

```bash
# Crear directorio de backup
mkdir -p /root/cluster-backup-$(date +%Y%m%d)
cd /root/cluster-backup-$(date +%Y%m%d)

# Backup completo de /etc/pve/ (¡MUY IMPORTANTE!)
tar czf pve-config-backup.tar.gz /etc/pve/ 2>/dev/null

# Backup de configuraciones de red
cp /etc/network/interfaces interfaces.backup
cp -r /etc/network/interfaces.d . 2>/dev/null || true

# Backup de configuraciones de storage
cp /etc/pve/storage.cfg storage.cfg.backup 2>/dev/null || true

# Backup de lista de usuarios
pveum user list > users.txt

# Backup de permisos
pveum acl list > acl.txt

# Lista de todos los archivos críticos
echo "Backup creado en: $(pwd)"
ls -lh
```

### 3. Backup de VMs y Contenedores (CRÍTICO)

```bash
# Opción A: Backup rápido de TODAS las VMs y Contenedores
vzdump --all --mode snapshot --compress zstd --dumpdir /var/lib/vz/dump

# Opción B: Backup selectivo de VMs críticas
# vzdump 100 101 102 --mode snapshot --compress zstd --dumpdir /var/lib/vz/dump

# Verificar que los backups se crearon
ls -lh /var/lib/vz/dump/
```

### 4. Detener VMs y Contenedores

**IMPORTANTE**: Decide si vas a:
- **Opción A**: Detener todo (más seguro, requiere downtime completo)
- **Opción B**: Mantener corriendo (riesgoso, pueden surgir problemas)

```bash
# Opción A - Detener todas las VMs
for vmid in $(qm list | awk '{if(NR>1) print $1}'); do
    echo "Deteniendo VM $vmid..."
    qm shutdown $vmid
done

# Esperar a que se detengan
sleep 30

# Forzar detención de las que no se detuvieron
for vmid in $(qm list | awk '{if(NR>1) print $1}'); do
    qm stop $vmid 2>/dev/null
done

# Opción A - Detener todos los Contenedores
for ctid in $(pct list | awk '{if(NR>1) print $1}'); do
    echo "Deteniendo CT $ctid..."
    pct shutdown $ctid
done

# Esperar a que se detengan
sleep 30

# Forzar detención de los que no se detuvieron
for ctid in $(pct list | awk '{if(NR>1) print $1}'); do
    pct stop $ctid 2>/dev/null
done
```

---

## 🔥 Fase 1: ELIMINAR CLUSTER EXISTENTE

### En el Nodo 2 (Nodo Secundario PRIMERO)

```bash
# 1. Detener servicios del cluster
systemctl stop pve-cluster
systemctl stop corosync

# 2. Verificar que están detenidos
systemctl status pve-cluster
systemctl status corosync

# 3. Eliminar configuración del cluster
rm /etc/pve/corosync.conf
rm -rf /etc/corosync/*
rm /etc/pve/cluster.conf 2>/dev/null || true

# 4. Eliminar base de datos del cluster
pmxcfs -l  # Esto reinicia el pmxcfs en modo local

# 5. Matar procesos restantes
killall corosync 2>/dev/null || true
killall pmxcfs 2>/dev/null || true

# 6. Reiniciar servicios en modo local
systemctl stop pve-cluster corosync
systemctl start pve-cluster

# 7. Verificar que está en modo local
pvecm status
# Deberías ver un error diciendo que no está en cluster - ESTO ES CORRECTO

# 8. REINICIAR EL NODO 2
echo "Reiniciando Nodo 2 en 10 segundos..."
sleep 10
reboot
```

**ESPERAR** a que el Nodo 2 reinicie completamente (2-5 minutos).

### Verificar Nodo 2 Después del Reinicio

```bash
# SSH al Nodo 2 nuevamente
ssh root@nodo2

# Verificar que NO está en cluster
pvecm status
# Debe mostrar error - esto es CORRECTO

# Verificar que las VMs/Contenedores siguen ahí
qm list
pct list

# Verificar servicios
systemctl status pvedaemon
systemctl status pveproxy
```

---

### En el Nodo 1 (Nodo Principal)

```bash
# 1. Verificar que el Nodo 2 ya fue removido
pvecm nodes

# 2. Eliminar Nodo 2 del cluster (si aún aparece)
pvecm delnode nodo2

# 3. Detener servicios del cluster
systemctl stop pve-cluster
systemctl stop corosync

# 4. Eliminar configuración del cluster
rm /etc/pve/corosync.conf
rm -rf /etc/corosync/*
rm /etc/pve/cluster.conf 2>/dev/null || true

# 5. Eliminar base de datos del cluster
pmxcfs -l

# 6. Matar procesos restantes
killall corosync 2>/dev/null || true
killall pmxcfs 2>/dev/null || true

# 7. Reiniciar servicios en modo local
systemctl stop pve-cluster corosync
systemctl start pve-cluster

# 8. Verificar que está en modo local
pvecm status
# Deberías ver un error - ESTO ES CORRECTO

# 9. REINICIAR EL NODO 1
echo "Reiniciando Nodo 1 en 10 segundos..."
sleep 10
reboot
```

**ESPERAR** a que el Nodo 1 reinicie completamente (2-5 minutos).

---

## ✅ Fase 2: VERIFICAR NODOS INDEPENDIENTES

### En Nodo 1

```bash
ssh root@nodo1

# Verificar que NO está en cluster
pvecm status
# Debe mostrar: "cluster not ready - no quorum"

# Verificar que los servicios funcionan
systemctl status pvedaemon
systemctl status pveproxy
systemctl status pvestatd

# Verificar acceso a Web UI
# Abrir en navegador: https://IP-NODO-1:8006

# Verificar VMs y Contenedores
qm list
pct list

# Verificar storage
pvesm status
```

### En Nodo 2

```bash
ssh root@nodo2

# Mismas verificaciones
pvecm status  # Debe mostrar error
systemctl status pvedaemon pveproxy pvestatd
qm list
pct list
pvesm status

# Verificar acceso a Web UI
# Abrir en navegador: https://IP-NODO-2:8006
```

---

## 🆕 Fase 3: CREAR NUEVO CLUSTER

### Paso 1: Crear Cluster en Nodo 1 (Principal)

```bash
ssh root@nodo1

# Crear nuevo cluster
# Sintaxis: pvecm create <nombre-del-cluster>
pvecm create mi-cluster-proxmox

# IMPORTANTE: Usa un nombre descriptivo, por ejemplo:
# pvecm create produccion-cluster
# pvecm create homelab-cluster
# pvecm create empresa-cluster

# Verificar creación del cluster
pvecm status

# Deberías ver:
# - Quorum information
# - Nodes: 1
# - Node ID: 1
# - Ring ID: ...
```

### Paso 2: Obtener Información de Unión

```bash
# En Nodo 1, obtener información para unir nodos
pvecm status

# Anotar:
# - Nombre del cluster
# - IP del Nodo 1
```

### Paso 3: Unir Nodo 2 al Cluster

```bash
ssh root@nodo2

# ANTES de unir, verificar conectividad
ping -c 3 IP-NODO-1

# Verificar que SSH funciona entre nodos
ssh root@IP-NODO-1 hostname

# Unir al cluster
# Sintaxis: pvecm add <IP-del-nodo-principal>
pvecm add IP-NODO-1

# Se te pedirá:
# 1. Password del root del Nodo 1
# 2. Confirmar fingerprint SSH (escribe 'yes')

# ESPERAR - Este proceso toma 1-2 minutos
```

### Paso 4: Verificar Cluster Completo

```bash
# En Nodo 1
ssh root@nodo1

pvecm status
# Deberías ver:
# - Quorum information
# - Nodes: 2
# - Online: nodo1, nodo2

pvecm nodes
# Deberías ver ambos nodos listados

# Verificar en Web UI
# Abrir: https://IP-NODO-1:8006
# En el panel izquierdo, deberías ver:
# Datacenter
#   └─ nodo1
#   └─ nodo2
```

```bash
# En Nodo 2
ssh root@nodo2

pvecm status
# Debe mostrar lo mismo que Nodo 1

pvecm nodes
# Debe mostrar ambos nodos
```

---

## 🔧 Fase 4: RECONFIGURAR STORAGE COMPARTIDO

Si tenías storage compartido (NFS, iSCSI, Ceph), debes reconfigurarlo:

### Storage NFS (ejemplo)

```bash
# En Nodo 1 (se replicará automáticamente al Nodo 2)

# Agregar storage NFS
pvesm add nfs backup-nfs \
  --server 192.168.1.100 \
  --export /mnt/backup \
  --content backup,iso,vztmpl

# Verificar
pvesm status
```

### Storage iSCSI (ejemplo)

```bash
pvesm add iscsi my-iscsi \
  --portal 192.168.1.200 \
  --target iqn.2025-01.com.example:storage

# Verificar
pvesm status
```

### Verificar en Ambos Nodos

```bash
# En ambos nodos
pvesm status

# Debe mostrar el mismo storage
```

---

## 🚀 Fase 5: INICIAR VMs Y CONTENEDORES

### Opción A: Iniciar Todo Automáticamente

```bash
# En el nodo donde estén las VMs

# Iniciar todas las VMs
for vmid in $(qm list | awk '{if(NR>1) print $1}'); do
    echo "Iniciando VM $vmid..."
    qm start $vmid
    sleep 5
done

# Iniciar todos los Contenedores
for ctid in $(pct list | awk '{if(NR>1) print $1}'); do
    echo "Iniciando CT $ctid..."
    pct start $ctid
    sleep 3
done
```

### Opción B: Iniciar Selectivamente

```bash
# Iniciar VMs críticas primero
qm start 100
qm start 101

# Verificar que iniciaron correctamente
qm list

# Luego iniciar el resto
```

---

## ✅ Fase 6: VERIFICACIÓN FINAL

### Checklist de Verificación

```bash
# 1. Verificar estado del cluster
pvecm status
# ✓ Debe mostrar 2 nodos online con quorum

# 2. Verificar nodos
pvecm nodes
# ✓ Ambos nodos deben aparecer

# 3. Verificar VMs
qm list
# ✓ Todas las VMs deben aparecer

# 4. Verificar Contenedores
pct list
# ✓ Todos los contenedores deben aparecer

# 5. Verificar Storage
pvesm status
# ✓ Todo el storage debe ser visible

# 6. Verificar servicios
systemctl status pve-cluster
systemctl status corosync
systemctl status pvedaemon
systemctl status pveproxy
# ✓ Todos deben estar active (running)

# 7. Verificar logs por errores
journalctl -u corosync -n 50
journalctl -u pve-cluster -n 50
# ✓ No deben haber errores críticos

# 8. Acceder a Web UI de ambos nodos
# https://IP-NODO-1:8006
# https://IP-NODO-2:8006
# ✓ Debes poder ver el cluster completo desde cualquiera
```

### Verificar Migración de VMs (HA)

```bash
# Probar migración de una VM entre nodos
qm migrate 100 nodo2

# Verificar que migró correctamente
qm list

# Migrar de vuelta
qm migrate 100 nodo1
```

---

## 🔒 Fase 7: RECONFIGURAR SEGURIDAD Y USUARIOS

### Recrear Usuarios (si es necesario)

```bash
# Listar usuarios actuales
pveum user list

# Crear usuarios si se perdieron
pveum user add usuario@pve --email user@example.com
pveum passwd usuario@pve

# Asignar permisos
pveum acl modify / -user usuario@pve -role Administrator
```

### Reconfigurar Firewall

```bash
# Verificar firewall del cluster
cat /etc/pve/firewall/cluster.fw

# Habilitar si está desactivado
# Datacenter → Firewall → Options → Firewall: Yes
```

---

## 📝 Fase 8: DOCUMENTACIÓN POST-RECREACIÓN

```bash
# Guardar estado final del cluster
pvecm status > /root/cluster-status-after.txt
pvecm nodes >> /root/cluster-status-after.txt
qm list > /root/vms-after.txt
pct list > /root/containers-after.txt

# Actualizar documentación en el repositorio
# - configs/vms/inventory.md
# - configs/containers/inventory.md
# - docs/setup-guide.md
```

---

## 🆘 TROUBLESHOOTING

### Problema: "cluster not ready - no quorum"

**Solución**:
```bash
# Verificar que hay al menos 2 nodos online
pvecm nodes

# Verificar servicio corosync
systemctl status corosync

# Ver logs
journalctl -u corosync -f
```

### Problema: "No se puede unir el Nodo 2 al cluster"

**Solución**:
```bash
# En Nodo 2, verificar conectividad
ping IP-NODO-1
ssh root@IP-NODO-1

# Verificar que no hay restos del cluster anterior
pvecm status  # Debe mostrar error

# Si aparece en cluster, limpiar nuevamente:
systemctl stop pve-cluster corosync
rm /etc/pve/corosync.conf
rm -rf /etc/corosync/*
pmxcfs -l
systemctl start pve-cluster
reboot
```

### Problema: "Las VMs no aparecen después de recrear cluster"

**Solución**:
```bash
# Verificar storage
pvesm status

# Las VMs deberían estar en:
ls -la /etc/pve/qemu-server/
ls -la /etc/pve/lxc/

# Si no aparecen, pueden estar en storage local de cada nodo
# Acceder a Web UI de cada nodo por separado
```

### Problema: "Error: unable to resolve hostname"

**Solución**:
```bash
# Verificar /etc/hosts en ambos nodos
cat /etc/hosts

# Debe contener:
# 127.0.0.1 localhost
# IP-NODO-1 nodo1.dominio.com nodo1
# IP-NODO-2 nodo2.dominio.com nodo2

# Editar si es necesario
nano /etc/hosts
```

### Problema: "Sincronización de tiempo"

**Solución**:
```bash
# Los nodos deben tener la hora sincronizada
date

# Verificar NTP
systemctl status chrony
# o
systemctl status systemd-timesyncd

# Sincronizar manualmente si es necesario
timedatectl set-ntp true
```

---

## 📚 COMANDOS DE REFERENCIA RÁPIDA

```bash
# Ver estado del cluster
pvecm status

# Ver nodos del cluster
pvecm nodes

# Ver configuración de corosync
cat /etc/pve/corosync.conf

# Ver logs del cluster
journalctl -u corosync -f
journalctl -u pve-cluster -f

# Verificar quorum
pvecm expected 1  # Si solo hay 1 nodo temporalmente
pvecm expected 2  # Restablecer a 2 nodos

# Forzar quorum (SOLO EN EMERGENCIAS)
pvecm expected 1

# Reiniciar servicios del cluster
systemctl restart corosync
systemctl restart pve-cluster
```

---

## ⚠️ NOTAS IMPORTANTES

1. **No uses `pvecm delnode` en el nodo actual**: Siempre elimina nodos desde OTRO nodo
2. **Backups son CRÍTICOS**: Nunca hagas esto sin backups completos
3. **Acceso físico recomendado**: Ten acceso IPMI/KVM por si pierdes SSH
4. **Tiempo sincronizado**: Los nodos deben tener la hora sincronizada
5. **DNS/Hosts**: Los nodos deben poder resolverse por nombre
6. **Firewall**: Puertos necesarios: 22 (SSH), 8006 (Web UI), 5404-5405 (Corosync)

---

## 📋 CHECKLIST FINAL

- [ ] Cluster nuevo creado correctamente
- [ ] Ambos nodos visibles en Web UI
- [ ] Todas las VMs listadas y funcionando
- [ ] Todos los contenedores listados y funcionando
- [ ] Storage compartido configurado
- [ ] Migración de VMs funciona
- [ ] Backups configurados
- [ ] Usuarios y permisos restaurados
- [ ] Firewall configurado
- [ ] Documentación actualizada en repositorio
- [ ] Backups viejos eliminados después de verificar

---

**Última actualización**: 2025-11-09
