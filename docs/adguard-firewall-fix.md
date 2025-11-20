# Fix AdGuard DNS - Firewall Bloqueando Puerto 53

**Fecha**: 2025-11-19  
**Problema**: DNS queries a AdGuard (192.168.1.120:53) hacen timeout  
**Causa**: Firewall de Proxmox bloqueando puerto 53

---

## 🔍 Diagnóstico Realizado

✅ **Servicio AdGuard**: Corriendo correctamente  
✅ **Puerto 53**: Escuchando (UDP y TCP)  
✅ **Conectividad**: Ping funciona  
❌ **DNS Queries**: **TIMEOUT** (firewall bloqueando)

```
dig @192.168.1.120 google.com +short
;; communications error to 192.168.1.120#53: timed out
```

---

## 🛠️ Solución

### Opción A: Script Automatizado (Recomendado)

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Ejecutar script de fix
bash /root/scripts/monitoring/fix-adguard-firewall.sh

# O si está en otra ubicación:
cd /path/to/proxmox/scripts/monitoring
chmod +x fix-adguard-firewall.sh
./fix-adguard-firewall.sh

# Verificar log
tail -50 /var/log/adguard-firewall-fix.log
```

---

### Opción B: Configuración Manual

#### Paso 1: Verificar estado del firewall

```bash
# SSH al nodo proxmox
ssh root@192.168.1.78

# Ver estado del firewall
pve-firewall status

# Ver si existe configuración para LXC 103
cat /etc/pve/firewall/103.fw
```

#### Paso 2: Crear reglas de firewall para LXC 103

```bash
# Crear/editar archivo de firewall
nano /etc/pve/firewall/103.fw
```

Agregar el siguiente contenido:

```conf
[OPTIONS]
enable: 1

[RULES]
# AdGuard Home - DNS
IN ACCEPT -p udp -dport 53 -log nolog -source +datacenter  # DNS UDP
IN ACCEPT -p tcp -dport 53 -log nolog -source +datacenter  # DNS TCP

# AdGuard Home - Web Interface
IN ACCEPT -p tcp -dport 80 -log nolog -source +datacenter   # HTTP
IN ACCEPT -p tcp -dport 3000 -log nolog -source +datacenter # Setup inicial
IN ACCEPT -p tcp -dport 853 -log nolog -source +datacenter  # DNS-over-TLS (opcional)

# ICMP (ping)
IN ACCEPT -p icmp -log nolog

# SSH (si es necesario)
IN ACCEPT -p tcp -dport 22 -log nolog -source +datacenter
```

Guardar con `Ctrl+O`, `Enter`, `Ctrl+X`

#### Paso 3: Aplicar cambios

```bash
# Reiniciar firewall
pve-firewall restart

# Esperar unos segundos
sleep 3

# Verificar que se aplicó
pve-firewall status
```

#### Paso 4: Probar DNS

```bash
# Test directo
dig @192.168.1.120 google.com +short

# Debe devolver IPs, por ejemplo:
# 142.250.80.46
# 142.250.80.14
# ...

# Test con timeout más largo
dig @192.168.1.120 google.com +time=10

# Desde otro LXC (ej. 105)
pct exec 105 -- dig @192.168.1.120 google.com +short
```

---

## 🔧 Solución Alternativa: Deshabilitar Firewall

Si las reglas no funcionan o prefieres deshabilitar el firewall para este LXC:

```bash
# Editar configuración del firewall
nano /etc/pve/firewall/103.fw
```

Cambiar a:
```conf
[OPTIONS]
enable: 0
```

O eliminar el archivo completamente:
```bash
rm /etc/pve/firewall/103.fw
pve-firewall restart
```

**⚠️ ADVERTENCIA**: Solo recomendado si es una red privada/confiable.

---

## 🌐 Verificar Firewall del Datacenter

Si el problema persiste, verificar firewall a nivel datacenter:

```bash
# Ver configuración del datacenter
cat /etc/pve/firewall/cluster.fw

# Ver si hay reglas bloqueando
nano /etc/pve/firewall/cluster.fw
```

Asegurar que tenga algo como:
```conf
[OPTIONS]
enable: 1
policy_in: ACCEPT
policy_out: ACCEPT

[RULES]
# Permitir tráfico interno
GROUP cluster-in -i vmbr0
GROUP cluster-out -i vmbr0

[group cluster-in]
IN ACCEPT -source 192.168.1.0/24

[group cluster-out]
OUT ACCEPT -dest 192.168.1.0/24
```

---

## 🔍 Diagnóstico Adicional

Si después de configurar el firewall el problema persiste:

### 1. Verificar binding de AdGuard

```bash
pct exec 103 -- cat /opt/AdGuardHome/AdGuardHome.yaml | grep bind
```

Debe mostrar:
```yaml
bind_hosts:
  - 0.0.0.0
bind_port: 53
```

Si está en `127.0.0.1`, cambiar a `0.0.0.0`:

```bash
pct exec 103 -- nano /opt/AdGuardHome/AdGuardHome.yaml

# Cambiar:
# bind_hosts:
#   - 127.0.0.1
#
# Por:
# bind_hosts:
#   - 0.0.0.0

# Reiniciar servicio
pct exec 103 -- systemctl restart AdGuardHome
```

### 2. Verificar desde dentro del LXC

```bash
# Entrar al LXC
pct enter 103

# Test local
dig @127.0.0.1 google.com +short
dig @192.168.1.120 google.com +short

# Ver logs en tiempo real
journalctl -u AdGuardHome -f
```

### 3. Verificar con tcpdump

```bash
# Capturar tráfico en puerto 53
pct exec 103 -- tcpdump -i eth0 port 53 -n

# En otra terminal, hacer consulta
dig @192.168.1.120 google.com
```

---

## 📊 Actualizar Monitor en Uptime Kuma

Una vez resuelto el problema de firewall:

### Opción 1: Mantener Monitor DNS

1. Ir a http://192.168.1.70:3001
2. Editar monitor "AdGuard DNS Resolver"
3. Ajustar:
   - **Intervalo**: 60s (en vez de 30s)
   - **Timeout**: 10s
   - **Reintentos**: 2
4. Guardar y verificar que marca OK

### Opción 2: Cambiar a Monitor HTTP (Alternativa)

Si el monitor DNS sigue dando problemas:

1. Tipo: **HTTP(s)**
2. URL: `http://192.168.1.120` (WebUI de AdGuard)
3. Códigos aceptados: 200-299
4. Intervalo: 60s

Esto verifica que AdGuard está vivo aunque no prueba específicamente el DNS.

### Opción 3: Monitor Combinado

Crear dos monitores:
- **AdGuard - Ping**: Verifica conectividad (ya existe)
- **AdGuard - WebUI**: HTTP al puerto 80
- **AdGuard DNS Resolver**: DNS query (ajustar timeout)

---

## ✅ Verificación Final

```bash
# 1. Firewall configurado
cat /etc/pve/firewall/103.fw

# 2. Firewall aplicado
pve-firewall status

# 3. DNS funciona
dig @192.168.1.120 google.com +short
dig @192.168.1.120 cloudflare.com +short

# 4. Desde otro LXC
pct exec 105 -- dig @192.168.1.120 google.com +short

# 5. Verificar logs de AdGuard
pct exec 103 -- journalctl -u AdGuardHome -n 20 --no-pager
```

**Resultado esperado**:
```
$ dig @192.168.1.120 google.com +short
142.250.80.46
142.250.80.14
...
```

---

## 📝 Resumen

**Problema**: Firewall de Proxmox bloqueaba puerto 53  
**Solución**: Crear reglas en `/etc/pve/firewall/103.fw` para permitir DNS  
**Resultado**: AdGuard DNS ahora accesible desde toda la red

**Archivo clave**: `/etc/pve/firewall/103.fw`

---

## 🔗 Relacionado

- Script automatizado: `scripts/monitoring/fix-adguard-firewall.sh`
- Diagnóstico: `scripts/monitoring/diagnostico-adguard.sh`
- Documentación: `docs/security-best-practices.md`
