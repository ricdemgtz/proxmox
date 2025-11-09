# Mejores Prácticas de Seguridad / Security Best Practices

Esta guía cubre las mejores prácticas de seguridad para el servidor Proxmox.

## 🔒 Seguridad del Sistema Base

### 1. Mantener el Sistema Actualizado

```bash
# Actualizar regularmente
apt update
apt dist-upgrade

# Configurar actualizaciones automáticas de seguridad (opcional)
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

### 2. Firewall

#### Habilitar Firewall de Proxmox

```bash
# Desde Web UI:
# Datacenter → Firewall → Options → Firewall: Yes

# Configurar reglas básicas:
# - INPUT: DROP por defecto
# - Permitir: SSH (22), Web UI (8006)
# - Permitir: VNC (5900-5999) solo desde IPs confiables
```

#### Firewall del Host con iptables

```bash
# Ver reglas actuales
iptables -L -n -v

# Ejemplo de reglas básicas (guardar en script)
cat > /etc/network/if-pre-up.d/firewall << 'EOF'
#!/bin/sh
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Establecidas
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Web UI
iptables -A INPUT -p tcp --dport 8006 -j ACCEPT

# ICMP (ping)
iptables -A INPUT -p icmp -j ACCEPT
EOF

chmod +x /etc/network/if-pre-up.d/firewall
```

### 3. SSH Hardening

```bash
# Editar configuración SSH
nano /etc/ssh/sshd_config

# Configuraciones recomendadas:
Port 22                              # Cambiar a puerto no estándar (opcional)
PermitRootLogin prohibit-password    # Solo con key, no password
PasswordAuthentication no            # Desactivar passwords (usar keys)
PubkeyAuthentication yes             # Permitir autenticación con keys
MaxAuthTries 3                       # Intentos máximos
ClientAliveInterval 300              # Timeout de sesión inactiva
ClientAliveCountMax 2                # Número de checks antes de desconectar
AllowUsers admin                     # Limitar usuarios (opcional)

# Reiniciar SSH
systemctl restart sshd
```

#### Configurar SSH Keys

```bash
# En tu máquina local, generar key
ssh-keygen -t ed25519 -C "tu@email.com"

# Copiar key al servidor
ssh-copy-id root@servidor

# O manualmente
# En el servidor:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys  # Pegar public key
chmod 600 ~/.ssh/authorized_keys
```

### 4. Fail2Ban

```bash
# Instalar
apt install fail2ban

# Configurar para Proxmox
cat > /etc/fail2ban/jail.d/proxmox.conf << 'EOF'
[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[proxmox]
enabled = true
port = https,http,8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
bantime = 3600
EOF

# Crear filtro para Proxmox
cat > /etc/fail2ban/filter.d/proxmox.conf << 'EOF'
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST>
ignoreregex =
EOF

# Reiniciar fail2ban
systemctl restart fail2ban

# Ver estado
fail2ban-client status
fail2ban-client status sshd
```

### 5. Autenticación de Dos Factores (2FA)

```bash
# Configurar desde Web UI:
# Datacenter → Permissions → Two Factor

# O para usuario específico:
# Datacenter → Permissions → Users → [usuario] → TFA
```

## 🔐 Seguridad de VMs y Contenedores

### Contenedores No-Privilegiados

**SIEMPRE** usa contenedores no-privilegiados cuando sea posible:

```bash
# Al crear contenedor, deseleccionar "unprivileged"
# O vía CLI:
pct create <ctid> <template> --unprivileged 1
```

### Aislamiento de Red

```bash
# Crear bridge aislado para VMs/CTs que no necesitan internet
auto vmbr1
iface vmbr1 inet static
    address 10.0.0.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

### Firewall por VM/CT

```bash
# Habilitar firewall para VM específica
# Web UI: VM → Firewall → Options → Firewall: Yes

# Configurar reglas específicas
# VM → Firewall → Add → [configurar reglas]
```

## 🛡️ Seguridad de la Red

### VLANs

Separar tráfico con VLANs:

```bash
# Ejemplo de VLAN en interfaces
auto vmbr0.10
iface vmbr0.10 inet manual
    vlan-raw-device vmbr0

auto vmbr0.20
iface vmbr0.20 inet manual
    vlan-raw-device vmbr0
```

### Limitar Acceso a Web UI

```bash
# Limitar acceso a IPs específicas vía iptables
iptables -A INPUT -p tcp --dport 8006 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 8006 -j DROP
```

## 🔑 Gestión de Usuarios y Permisos

### Principio de Menor Privilegio

```bash
# Crear usuario con permisos limitados
pveum user add usuario@pve --email user@example.com

# Asignar rol específico (no Administrator)
pveum acl modify /vms/100 -user usuario@pve -role PVEVMUser

# Roles disponibles:
# - PVEAdmin: Admin de Proxmox (no root)
# - PVEVMAdmin: Admin de VMs
# - PVEVMUser: Usuario de VMs
# - PVEAuditor: Solo lectura
```

### Autenticación LDAP/AD (Opcional)

```bash
# Configurar desde Web UI:
# Datacenter → Permissions → Realms → Add

# O vía CLI:
pveum realm add ad --type ad --domain example.com --server dc.example.com
```

## 🔒 Cifrado y Certificados

### Certificados SSL

#### Let's Encrypt (Si tienes dominio público)

```bash
# Configurar cuenta ACME
pvenode acme account register default mail@example.com

# Ordenar certificado
pvenode config set --acme domains=pve.example.com

# Obtener certificado
pvenode acme cert order
```

#### Certificado Personalizado

```bash
# Copiar certificados
cp cert.pem /etc/pve/local/pveproxy-ssl.pem
cp key.pem /etc/pve/local/pveproxy-ssl.key

# Reiniciar proxy
systemctl restart pveproxy
```

### Encriptar Backups (Opcional)

```bash
# Encriptar backup con GPG
vzdump <vmid> --stdout | gpg -c > backup.gpg

# Desencriptar
gpg -d backup.gpg | qmrestore - <vmid>
```

## 🔍 Auditoría y Monitoreo

### Logs de Auditoría

```bash
# Ver logs de autenticación
grep -i failed /var/log/auth.log

# Ver accesos a Web UI
tail -f /var/log/pveproxy/access.log

# Ver cambios en cluster
tail -f /var/log/pve-firewall.log
```

### Monitoreo de Integridad

```bash
# Instalar AIDE (Advanced Intrusion Detection Environment)
apt install aide

# Inicializar base de datos
aideinit

# Verificar cambios
aide --check
```

## 📋 Checklist de Seguridad

### Configuración Inicial
- [ ] Sistema actualizado a última versión
- [ ] Firewall habilitado y configurado
- [ ] SSH hardening aplicado
- [ ] SSH keys configuradas, passwords deshabilitados
- [ ] Fail2Ban instalado y configurado
- [ ] 2FA habilitado para usuarios administrativos
- [ ] Certificado SSL válido instalado

### Operación Continua
- [ ] Actualizaciones de seguridad aplicadas regularmente
- [ ] Logs revisados semanalmente
- [ ] Backups encriptados y almacenados de forma segura
- [ ] Auditoría de usuarios y permisos trimestral
- [ ] Pruebas de penetración anuales (opcional)

### VMs y Contenedores
- [ ] Contenedores no-privilegiados por defecto
- [ ] Firewall habilitado por VM/CT
- [ ] Aislamiento de red apropiado
- [ ] Sistemas operativos guest actualizados

## 🚨 Respuesta a Incidentes

### Si Detectas Actividad Sospechosa

1. **No eliminar evidencia**: Preservar logs
2. **Aislar**: Desconectar sistema afectado de la red
3. **Documentar**: Registrar todo lo observado
4. **Investigar**: Revisar logs, procesos, conexiones
5. **Remediar**: Eliminar amenaza, parchear vulnerabilidad
6. **Revisar**: Analizar cómo ocurrió el incidente

### Comandos de Diagnóstico

```bash
# Ver conexiones activas
ss -tulpn

# Ver procesos
ps aux

# Ver usuarios conectados
w
last

# Ver intentos de login fallidos
lastb

# Ver modificaciones recientes
find /etc -type f -mtime -7 -ls
```

## 📚 Recursos Adicionales

- [Proxmox Security](https://pve.proxmox.com/wiki/Security)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

## 📝 Registro de Auditoría

Mantén un registro de auditorías de seguridad:

| Fecha | Tipo de Auditoría | Hallazgos | Acciones Tomadas |
|-------|-------------------|-----------|------------------|
| - | - | - | - |

---

**IMPORTANTE**: La seguridad es un proceso continuo, no un estado. Revisa y actualiza regularmente tus medidas de seguridad.
