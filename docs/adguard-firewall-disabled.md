# Solución AdGuard DNS - Firewall Deshabilitado

**Fecha**: 2025-11-19  
**Problema**: Firewall de Proxmox está **disabled/running**  
**Efecto**: Las reglas del LXC 103 no se aplican aunque estén creadas

---

## 🔍 Diagnóstico

Estado del firewall:
```
Status: disabled/running
```

Esto significa:
- El servicio del firewall está corriendo
- Pero está **deshabilitado globalmente** (no aplica reglas)

---

## ✅ Solución 1: Deshabilitar Firewall del LXC 103 (Más Simple)

Si tu red es confiable (LAN privada), la forma más simple es **deshabilitar el firewall para este LXC específico**:

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Crear/editar firewall del LXC 103
nano /etc/pve/firewall/103.fw
```

Cambiar a:
```conf
[OPTIONS]
enable: 0
```

O simplemente eliminar el archivo:
```bash
rm /etc/pve/firewall/103.fw
pve-firewall restart
```

**Probar DNS**:
```bash
dig @192.168.1.120 google.com +short
```

✅ **Esto debería funcionar inmediatamente**

---

## ✅ Solución 2: Habilitar Firewall de Proxmox Globalmente (Más Seguro)

Si prefieres usar firewall (recomendado para producción):

### Opción A: Vía Web UI

1. Abrir Proxmox Web UI: https://192.168.1.78:8006
2. Ir a **Datacenter** (en el árbol izquierdo)
3. Click en **Firewall**
4. Click en **Options**
5. Doble click en **Firewall**
6. Marcar **Enable** (checkbox)
7. Click **OK**

### Opción B: Vía CLI

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Crear/editar configuración del datacenter
nano /etc/pve/firewall/cluster.fw
```

Agregar/modificar:
```conf
[OPTIONS]
enable: 1
policy_in: ACCEPT
policy_out: ACCEPT

[RULES]
# Permitir tráfico interno de la LAN
GROUP local-network

[group local-network]
IN ACCEPT -source 192.168.1.0/24
```

Guardar y reiniciar:
```bash
pve-firewall restart
pve-firewall status
# Debe mostrar: Status: enabled/running
```

**Luego ejecutar nuevamente el script de fix**:
```bash
bash /root/scripts/monitoring/fix-adguard-firewall.sh
```

---

## ⚡ Solución Rápida Recomendada

Para resolver **AHORA MISMO** sin complicaciones:

```bash
ssh root@192.168.1.78

# Eliminar reglas de firewall del LXC 103
rm -f /etc/pve/firewall/103.fw

# Reiniciar firewall
pve-firewall restart

# Probar DNS
dig @192.168.1.120 google.com +short
```

Esto deshabilita el firewall solo para el LXC 103, dejando el resto del sistema como está.

---

## 🧪 Verificación

**DNS debe funcionar**:
```bash
dig @192.168.1.120 google.com +short
# Debe devolver IPs:
# 142.250.80.46
# ...

# Desde Uptime Kuma también
pct exec 105 -- dig @192.168.1.120 google.com +short
```

**Monitor en Uptime Kuma**:
- Ir a http://192.168.1.70:3001
- Monitor "AdGuard DNS Resolver" debe marcar **UP** ✅

---

## 📊 Comparación de Opciones

| Opción | Seguridad | Complejidad | Tiempo |
|--------|-----------|-------------|--------|
| **Deshabilitar firewall LXC 103** | 🟡 Media (OK para LAN privada) | 🟢 Baja | ⚡ 30 segundos |
| **Habilitar firewall globalmente** | 🟢 Alta | 🟡 Media | ⏱️ 5 minutos |

---

## 🎯 Recomendación

Para tu caso (red LAN privada, homelab):

✅ **Opción 1: Deshabilitar firewall del LXC 103**

Es más simple, funciona inmediatamente, y es seguro en una red privada donde ya controlas el acceso físico y por router.

Si en el futuro quieres más seguridad, puedes habilitar el firewall global más adelante.

---

## 🔧 Comandos Finales

```bash
# 1. SSH
ssh root@192.168.1.78

# 2. Eliminar firewall del LXC 103
rm -f /etc/pve/firewall/103.fw

# 3. Reiniciar
pve-firewall restart

# 4. Probar
dig @192.168.1.120 google.com +short

# 5. Verificar en Uptime Kuma
# http://192.168.1.70:3001
# Monitor "AdGuard DNS Resolver" debe estar UP
```

---

## ✅ Después del Fix

Una vez que DNS funcione:

- [ ] Monitor AdGuard DNS Resolver marca UP
- [ ] Sincronizar monitores LXC 105 → 205
- [ ] Desactivar alertas en LXC 205
- [ ] Configurar webhook n8n

---

**Tiempo estimado**: 1 minuto para fix + 5 minutos para resto de tareas = **6 minutos total** 🚀
