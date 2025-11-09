# Guía Rápida: Documentar Especificaciones del Cluster Proxmox

Esta guía te ayudará a recopilar toda la información de hardware de tus dos nodos Proxmox.

## 🚀 Pasos Rápidos

### 1. Preparar los Scripts en Cada Nodo

En **cada nodo** del cluster, copia el script de recopilación:

```bash
# Opción A: Si tienes git instalado en los nodos
cd /root
git clone https://github.com/ricdemgtz/proxmox.git
chmod +x proxmox/scripts/maintenance/collect-system-info.sh

# Opción B: Copiar manualmente vía SCP desde tu máquina
scp scripts/maintenance/collect-system-info.sh root@nodo1:/root/
scp scripts/maintenance/collect-system-info.sh root@nodo2:/root/
```

### 2. Ejecutar en el Nodo 1

```bash
ssh root@nodo1

# Hacer ejecutable el script
chmod +x /root/collect-system-info.sh

# Ejecutar
/root/collect-system-info.sh

# Esperar a que termine (puede tomar 1-2 minutos)
```

### 3. Ejecutar en el Nodo 2

```bash
ssh root@nodo2

# Hacer ejecutable el script
chmod +x /root/collect-system-info.sh

# Ejecutar
/root/collect-system-info.sh
```

### 4. Descargar los Reportes

Desde tu máquina local:

```bash
# Descargar reporte del Nodo 1
scp root@nodo1:/tmp/proxmox-system-info/system-report-*.txt ./nodo1-specs.txt
scp root@nodo1:/tmp/proxmox-system-info/system-report-*.html ./nodo1-specs.html

# Descargar reporte del Nodo 2
scp root@nodo2:/tmp/proxmox-system-info/system-report-*.txt ./nodo2-specs.txt
scp root@nodo2:/tmp/proxmox-system-info/system-report-*.html ./nodo2-specs.html
```

## 📊 Información que Obtendrás

El script recopila automáticamente:

### Hardware Básico
- ✅ Fabricante y modelo del servidor
- ✅ BIOS/UEFI versión
- ✅ Serial number

### Procesador (CPU)
- ✅ Modelo exacto del procesador
- ✅ Número de sockets
- ✅ Cores físicos por socket
- ✅ Threads totales
- ✅ Flags de virtualización (VT-x/AMD-V)
- ✅ Arquitectura

### Memoria (RAM)
- ✅ Capacidad total
- ✅ Número de módulos instalados
- ✅ Velocidad de cada módulo (MHz)
- ✅ Fabricante y número de parte
- ✅ Slots disponibles vs. usados

### Almacenamiento
- ✅ Lista completa de discos (HDD/SSD/NVMe)
- ✅ Capacidad de cada disco
- ✅ Modelo y serial de cada disco
- ✅ Tipo de interfaz (SATA/SAS/NVMe)
- ✅ Información SMART
- ✅ Configuración LVM (PV, VG, LV)
- ✅ ZFS pools (si aplica)

### GPU / Tarjetas Gráficas
- ✅ Tarjetas gráficas instaladas
- ✅ Modelo y fabricante
- ✅ NVIDIA GPUs (si nvidia-smi está disponible)

### Red
- ✅ Interfaces de red físicas
- ✅ Velocidad de cada interfaz (1Gbps, 10Gbps, etc.)
- ✅ MAC addresses
- ✅ Configuración de bridges
- ✅ Configuración de VLANs (si aplica)

### Configuración Proxmox
- ✅ Versión de Proxmox VE
- ✅ Configuración de storage
- ✅ VMs existentes
- ✅ Contenedores existentes
- ✅ Configuración de cluster
- ✅ Benchmark de rendimiento

## 🔍 Comandos Específicos para Cada Componente

Si necesitas información adicional específica, usa estos comandos:

### CPU Detallada
```bash
lscpu
cat /proc/cpuinfo
dmidecode -t processor
```

### RAM Detallada
```bash
dmidecode -t memory
free -h
```

### Discos Detallados
```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,SERIAL
fdisk -l
smartctl -a /dev/sda  # Cambiar sda por tu disco
```

### GPU Detallada
```bash
lspci | grep -i vga
lspci -v -s $(lspci | grep VGA | cut -d' ' -f1)
nvidia-smi  # Si tienes NVIDIA
```

### Red Detallada
```bash
ip addr show
ethtool eth0  # Cambiar eth0 por tu interfaz
brctl show
```

### Storage de Proxmox
```bash
pvesm status
cat /etc/pve/storage.cfg
pvs
vgs
lvs
```

## 📝 Documentar en el Repositorio

Una vez que tengas los reportes, actualiza los archivos de inventario:

### 1. Actualizar `docs/setup-guide.md`

Edita la sección "Información del Servidor" con los datos de cada nodo:

```markdown
## Nodo 1
- **Hostname**: pve-node1
- **IP de Gestión**: 192.168.1.11
- **CPU**: Intel Xeon E5-2680 v4 @ 2.40GHz (28 cores, 56 threads)
- **RAM**: 128GB DDR4 ECC
- **Discos**: 
  - 2x 500GB SSD (RAID1 para sistema)
  - 4x 4TB HDD (RAID10 para VMs)

## Nodo 2
- **Hostname**: pve-node2
- **IP de Gestión**: 192.168.1.12
- **CPU**: Intel Xeon E5-2680 v4 @ 2.40GHz (28 cores, 56 threads)
- **RAM**: 128GB DDR4 ECC
- **Discos**: 
  - 2x 500GB SSD (RAID1 para sistema)
  - 4x 4TB HDD (RAID10 para VMs)
```

### 2. Crear Archivo de Especificaciones

Crea un nuevo archivo en `docs/hardware-specs.md` con toda la información detallada.

## 🔧 Paquetes Adicionales Recomendados

Si algunos comandos no están disponibles, instala:

```bash
# SMART monitoring
apt install smartmontools

# Temperatura y sensores
apt install lm-sensors
sensors-detect  # Configurar sensores

# Detalles de hardware
apt install lshw

# Benchmarking adicional
apt install sysbench fio iperf3
```

## ⚡ Script de Una Línea

Para ejecutar todo de una vez en ambos nodos:

```bash
# Desde tu máquina local
for node in nodo1 nodo2; do
    ssh root@$node "wget https://raw.githubusercontent.com/ricdemgtz/proxmox/main/scripts/maintenance/collect-system-info.sh -O /tmp/collect-info.sh && chmod +x /tmp/collect-info.sh && /tmp/collect-info.sh"
    scp root@$node:/tmp/proxmox-system-info/system-report-*.txt ./${node}-report.txt
done
```

## 📋 Checklist

- [ ] Scripts copiados a ambos nodos
- [ ] Script ejecutado en Nodo 1
- [ ] Script ejecutado en Nodo 2
- [ ] Reportes descargados de ambos nodos
- [ ] Información de CPU documentada
- [ ] Información de RAM documentada
- [ ] Información de discos documentada
- [ ] Información de red documentada
- [ ] GPU documentada (si aplica)
- [ ] Configuración de cluster documentada
- [ ] `docs/setup-guide.md` actualizado
- [ ] Inventario de VMs/containers actualizado

## 🆘 Solución de Problemas

### "smartctl: command not found"
```bash
apt install smartmontools
```

### "sensors: command not found"
```bash
apt install lm-sensors
sensors-detect
```

### "Permission denied"
```bash
chmod +x collect-system-info.sh
```

### No puedo acceder por SSH
```bash
# Verificar que SSH está corriendo
systemctl status sshd

# Verificar firewall
iptables -L -n | grep 22
```

## 📚 Referencias

- Script principal: `scripts/maintenance/collect-system-info.sh`
- README de mantenimiento: `scripts/maintenance/README.md`
- Guía de setup: `docs/setup-guide.md`
