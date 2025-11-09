# Guía de Configuración Inicial de Proxmox

Esta guía documenta la configuración inicial del servidor Proxmox.

## 📋 Información del Servidor

**Actualiza esta sección con tu información:**

- **Hostname**: [nombre del servidor]
- **IP de Gestión**: [IP principal]
- **Versión de Proxmox**: [versión]
- **Fecha de Instalación**: [fecha]
- **Hardware**: 
  - CPU: [modelo y cores]
  - RAM: [cantidad]
  - Discos: [configuración]

## 🚀 Instalación Inicial

### 1. Instalación del Sistema Base

```bash
# Descargar ISO de Proxmox VE
# https://www.proxmox.com/en/downloads

# Crear USB booteable o montar en servidor
# Seguir wizard de instalación
```

### 2. Configuración Post-Instalación

#### Actualizar el Sistema
```bash
# Configurar repositorios (sin suscripción enterprise)
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Comentar repositorio enterprise
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Actualizar
apt update
apt dist-upgrade -y
```

#### Configurar Red
```bash
# Editar /etc/network/interfaces
nano /etc/network/interfaces

# Aplicar cambios
systemctl restart networking
```

#### Configurar Hostname y DNS
```bash
# Editar /etc/hosts
nano /etc/hosts

# Ejemplo:
# 127.0.0.1 localhost.localdomain localhost
# 192.168.1.10 pve.example.com pve

# Configurar DNS
nano /etc/resolv.conf
```

### 3. Configurar Almacenamiento

#### LVM-Thin (Predeterminado)
Ya configurado durante la instalación.

#### Agregar Almacenamiento Adicional
```bash
# Listar discos disponibles
lsblk

# Crear partición/LV según necesidad
# Agregar a Proxmox via Web UI o CLI
pvesm add <tipo> <id> --options
```

### 4. Configurar Firewall

```bash
# Habilitar firewall en Web UI:
# Datacenter → Firewall → Options → Firewall: Yes

# Permitir puertos necesarios:
# - 8006 (Web UI)
# - 22 (SSH)
# - 3128 (SPICE Proxy)
# - 5900-5999 (VNC)
```

### 5. Seguridad Básica

#### SSH
```bash
# Editar configuración SSH
nano /etc/ssh/sshd_config

# Recomendaciones:
# PermitRootLogin yes  # Cambiar a 'no' después de crear usuario
# PasswordAuthentication yes  # Cambiar a 'no' si usas keys
# Port 22  # Considerar cambiar puerto

systemctl restart sshd
```

#### Fail2Ban (Opcional pero Recomendado)
```bash
apt install fail2ban

# Configurar para Proxmox
cat > /etc/fail2ban/filter.d/proxmox.conf << 'EOF'
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST>
ignoreregex =
EOF

cat > /etc/fail2ban/jail.d/proxmox.conf << 'EOF'
[proxmox]
enabled = true
port = https,http,8006
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
bantime = 3600
EOF

systemctl enable fail2ban
systemctl start fail2ban
```

### 6. Configurar Usuarios y Permisos

```bash
# Crear usuario administrador (opcional)
pveum user add admin@pve
pveum passwd admin@pve
pveum acl modify / -user admin@pve -role Administrator
```

### 7. Configurar Email/Notificaciones

```bash
# Instalar postfix para emails
apt install postfix mailutils

# Configurar destino de emails en GUI:
# Datacenter → Options → Email from address
```

## 🔧 Configuraciones Avanzadas

### High Availability (HA)

Si tienes múltiples nodos:

```bash
# Crear cluster en nodo principal
pvecm create CLUSTER_NAME

# Unir nodos adicionales
pvecm add IP_DEL_NODO_PRINCIPAL
```

### Backup Automático

```bash
# Configurar en Web UI:
# Datacenter → Backup → Add

# O vía CLI:
vzdump --all --mode snapshot --compress zstd --storage local
```

### GPU Passthrough (Opcional)

Para pasar GPU física a VM:

```bash
# Editar GRUB
nano /etc/default/grub
# Agregar: GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
# O para AMD: GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on"

update-grub

# Cargar módulos
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules
echo "vfio_pci" >> /etc/modules
echo "vfio_virqfd" >> /etc/modules

update-initramfs -u -k all
reboot
```

## ✅ Checklist de Configuración Inicial

- [ ] Sistema base instalado y actualizado
- [ ] Red configurada correctamente
- [ ] Hostname y DNS configurados
- [ ] Almacenamiento configurado
- [ ] Firewall habilitado y configurado
- [ ] SSH asegurado
- [ ] Fail2Ban instalado (opcional)
- [ ] Usuarios y permisos configurados
- [ ] Email/notificaciones configuradas
- [ ] Primer backup configurado
- [ ] Documentación actualizada

## 📚 Siguientes Pasos

1. Leer **networking.md** para configuraciones avanzadas de red
2. Revisar **storage.md** para opciones de almacenamiento
3. Configurar **backup-recovery.md** para proteger tus datos
4. Implementar **security-best-practices.md**

## 🔗 Referencias

- [Proxmox Installation Guide](https://pve.proxmox.com/wiki/Installation)
- [Proxmox Network Configuration](https://pve.proxmox.com/wiki/Network_Configuration)
- [Proxmox Storage](https://pve.proxmox.com/wiki/Storage)
