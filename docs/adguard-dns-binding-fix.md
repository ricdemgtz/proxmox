# Fix Final AdGuard DNS - No Responde

**Fecha**: 2025-11-19  
**Problema**: DNS timeout incluso SIN firewall  
**Causa más probable**: AdGuard escuchando solo en 127.0.0.1 (localhost)

---

## 🔍 Diagnóstico Rápido

Ejecuta esto primero para ver dónde está escuchando AdGuard:

```bash
ssh root@192.168.1.78

# Ver en qué interfaz escucha AdGuard
pct exec 103 -- ss -ulnp | grep ':53'
```

**Busca esto en la salida**:

❌ **Problema** (escuchando solo en localhost):
```
UNCONN 0 0    127.0.0.1:53    0.0.0.0:*
```

✅ **Correcto** (escuchando en todas las interfaces):
```
UNCONN 0 0    0.0.0.0:53      0.0.0.0:*
```
o
```
UNCONN 0 0    *:53            *:*
```

---

## ✅ Solución: Cambiar Binding a 0.0.0.0

### Opción A: Script Automatizado

```bash
ssh root@192.168.1.78

# Ejecutar script de fix
bash /root/scripts/monitoring/fix-adguard-binding.sh

# Ver log
tail -30 /var/log/adguard-binding-fix.log
```

### Opción B: Manual

```bash
ssh root@192.168.1.78

# 1. Entrar al LXC
pct enter 103

# 2. Editar configuración de AdGuard
nano /opt/AdGuardHome/AdGuardHome.yaml

# 3. Buscar (Ctrl+W) "bind_host"
# Cambiar de:
#   bind_host: 127.0.0.1
# A:
#   bind_host: 0.0.0.0

# 4. Guardar (Ctrl+O, Enter, Ctrl+X)

# 5. Reiniciar servicio
systemctl restart AdGuardHome

# 6. Salir del LXC
exit

# 7. Probar DNS
dig @192.168.1.120 google.com +short
```

---

## 🧪 Verificación Alternativa

Si el problema persiste, verifica si AdGuard está usando otro puerto o configuración:

```bash
# Ver toda la configuración de AdGuard
pct exec 103 -- cat /opt/AdGuardHome/AdGuardHome.yaml | grep -A 10 "bind"

# Ver procesos escuchando
pct exec 103 -- netstat -tulpn | grep AdGuard

# Test desde DENTRO del LXC
pct exec 103 -- dig @127.0.0.1 google.com +short
pct exec 103 -- dig @192.168.1.120 google.com +short
```

---

## 🔧 Solución Alternativa: Reinstalar AdGuard

Si nada funciona, reinstalar AdGuard con configuración limpia:

```bash
# Entrar al LXC
pct enter 103

# Detener servicio
systemctl stop AdGuardHome

# Backup de configuración actual
cp -r /opt/AdGuardHome /opt/AdGuardHome.backup

# Editar configuración manualmente o reinstalar
# Ver: https://github.com/AdguardTeam/AdGuardHome#getting-started

# Reiniciar
systemctl start AdGuardHome
exit
```

---

## 📊 Verificar Web UI de AdGuard

Otra forma de diagnosticar:

1. Abrir http://192.168.1.120 en navegador
2. Login a AdGuard Home
3. Ir a **Settings** → **DNS settings**
4. Verificar:
   - **Listen interfaces**: Debe estar en "All interfaces" o específicamente en la IP del LXC
   - **Port**: Debe ser 53

---

## ⚡ Fix Rápido (Una Línea)

```bash
ssh root@192.168.1.78 "pct exec 103 -- bash -c 'sed -i \"s/bind_host: 127.0.0.1/bind_host: 0.0.0.0/g\" /opt/AdGuardHome/AdGuardHome.yaml && systemctl restart AdGuardHome' && sleep 3 && dig @192.168.1.120 google.com +short"
```

Esto hace todo en un comando:
1. Cambia bind_host a 0.0.0.0
2. Reinicia AdGuard
3. Espera 3 segundos
4. Prueba DNS

---

## 📝 Checklist de Diagnóstico

- [ ] Verificar que AdGuard está corriendo: `pct exec 103 -- systemctl status AdGuardHome`
- [ ] Verificar puerto 53 escuchando: `pct exec 103 -- ss -ulnp | grep ':53'`
- [ ] Verificar binding (debe ser 0.0.0.0): `pct exec 103 -- grep bind_host /opt/AdGuardHome/AdGuardHome.yaml`
- [ ] Test desde dentro del LXC: `pct exec 103 -- dig @127.0.0.1 google.com +short`
- [ ] Test desde fuera: `dig @192.168.1.120 google.com +short`
- [ ] Verificar firewall deshabilitado: `cat /etc/pve/firewall/103.fw` (no debe existir)
- [ ] Verificar logs: `pct exec 103 -- journalctl -u AdGuardHome -n 50`

---

## 🎯 Resultado Esperado

```bash
$ dig @192.168.1.120 google.com +short
142.250.80.46
142.250.80.14
...
```

Una vez que funcione:
- ✅ Monitor de Uptime Kuma marca UP
- ✅ Continuar con sincronización y resto de tareas

---

## 💡 Causa Raíz Probable

AdGuard Home se instala por defecto escuchando en `127.0.0.1:53` (solo localhost) por seguridad. Para funcionar como DNS de red, necesita escuchar en `0.0.0.0:53` (todas las interfaces).

Este es un comportamiento común en instalaciones de seguridad para evitar exponer el DNS accidentalmente.
