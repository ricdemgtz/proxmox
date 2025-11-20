# Especificaciones de Hardware - Cluster Proxmox

Documentación detallada de las especificaciones de hardware de cada nodo del cluster.

**Última actualización**: 2025-11-09

---

## 📊 Resumen del Cluster

| Especificación | Total Cluster | Nodo 1 (proxmox) | Nodo 2 (proxmedia) |
|----------------|---------------|------------------|-------------------|
| **CPU Cores Totales** | 12 cores (16 threads) | 4 cores (4 threads) | 4 cores (8 threads) |
| **RAM Total** | 24 GB | 12 GB DDR3 | 12 GB DDR3 |
| **Almacenamiento Total** | ~1.75 TB | ~1.5 TB | ~1.2 TB |
| **Interfaces de Red** | 4 (2 por nodo) | 2x 1Gbps | 2x 1Gbps |

---

## 🖥️ Nodo 1 - proxmox

### Información General
- **Hostname**: proxmox
- **IP de Gestión**: 192.168.1.78
- **Versión Proxmox**: 9.0.10
- **Kernel**: 6.14.11-2-pve
- **Fecha de Instalación**: 2025-09-18 

### Hardware del Sistema
- **Fabricante**: 
- **Modelo**: 
- **Serial Number**: 
- **BIOS**: 
  - Versión: 
  - Fecha: 

### Procesador (CPU)
- **Modelo**: 
- **Arquitectura**: 
- **Sockets**: 
- **Cores por Socket**: 
- **Threads Totales**: 
- **Frecuencia Base**: 
- **Frecuencia Max**: 
- **Cache L3**: 
- **Virtualización**: 
  - [ ] Intel VT-x
  - [ ] AMD-V
  - [ ] VT-d / IOMMU

### Memoria (RAM)
- **Capacidad Total**: 
- **Tipo**: (DDR3/DDR4/DDR5)
- **Velocidad**: 
- **ECC**: [ ] Sí [ ] No
- **Módulos Instalados**: 
  
  | Slot | Capacidad | Velocidad | Fabricante | Part Number |
  |------|-----------|-----------|------------|-------------|
  | 1    | | | | |
  | 2    | | | | |
  | 3    | | | | |
  | 4    | | | | |

- **Slots Disponibles**: 
- **Capacidad Máxima**: 

### Almacenamiento

#### Discos Instalados

| Disco | Tipo | Capacidad | Modelo | Serial | Interfaz | Uso |
|-------|------|-----------|--------|--------|----------|-----|
| /dev/sda | SSD/HDD/NVMe | | | | SATA/SAS/NVMe | Sistema/Datos/Backup |
| /dev/sdb | | | | | | |
| /dev/sdc | | | | | | |
| /dev/sdd | | | | | | |

#### Configuración LVM
- **Volume Group**: 
  - Physical Volumes: 
  - Capacidad Total: 
  - Logical Volumes:
    - `pve/root`: GB
    - `pve/data`: GB
    - `pve/swap`: GB

#### Configuración ZFS (si aplica)
- **Pool**: 
- **Tipo RAID**: 
- **Discos**: 
- **Capacidad**: 

#### Configuración RAID Hardware (si aplica)
- **Controladora**: 
- **RAID Level**: 
- **Discos en Array**: 
- **Hot Spare**: [ ] Sí [ ] No

### GPU / Tarjetas Gráficas

| Slot | Fabricante | Modelo | VRAM | Bus | Uso |
|------|------------|--------|------|-----|-----|
| 1    | | | | PCIe x16 | Display/Passthrough/Compute |
| 2    | | | | | |

### Red

#### Interfaces Físicas

| Interfaz | Tipo | Velocidad | MAC Address | Estado | Uso |
|----------|------|-----------|-------------|--------|-----|
| eth0 | Copper/Fiber | 1Gbps/10Gbps | | Up/Down | Gestión/VM/Storage |
| eth1 | | | | | |
| eth2 | | | | | |
| eth3 | | | | | |

#### Configuración de Bridges

| Bridge | Puertos | VLAN | IP | Uso |
|--------|---------|------|----|----|
| vmbr0 | eth0 | - | | Gestión |
| vmbr1 | eth1 | - | | VMs |

#### Configuración de Bonding (si aplica)
- **Bond0**: 
  - Interfaces: 
  - Modo: (balance-rr/active-backup/802.3ad)
  - MTU: 

### Otros Dispositivos PCI

| Tipo | Modelo | Uso |
|------|--------|-----|
| Controladora RAID | | |
| HBA | | |
| Tarjeta de Red Adicional | | |
| Otros | | |

### Sensores y Temperatura
- **Temperatura CPU (idle)**: °C
- **Temperatura CPU (carga)**: °C
- **Velocidad ventiladores**: RPM
- **Temperatura discos**: °C

### Rendimiento (pveperf)
```
# Pegar output de pveperf aquí
```

### Consumo Eléctrico
- **Idle**: W
- **Carga normal**: W
- **Carga máxima**: W
- **PSU**: W (Certificación: 80+ Bronze/Silver/Gold/Platinum)

---

## 🖥️ Nodo 2

### Información General
- **Hostname**: 
- **IP de Gestión**: 
- **Versión Proxmox**: 
- **Kernel**: 
- **Fecha de Instalación**: 2025-09-18

### Hardware del Sistema
- **Fabricante**: Dell Inc.
- **Modelo**: OptiPlex 9020
- **Serial Number**: 8QCTZ72
- **BIOS**: 
  - Versión: A14
  - Fecha: 09/14/2015

### Procesador (CPU)
- **Modelo**: Intel Core i5-4590 @ 3.30GHz
- **Arquitectura**: x86_64 (Haswell)
- **Sockets**: 1
- **Cores por Socket**: 4
- **Threads Totales**: 4 (sin HyperThreading)
- **Frecuencia Base**: 3.30 GHz
- **Frecuencia Max**: 3.70 GHz
- **Cache L3**: 6 MiB
- **Virtualización**: 
  - [x] Intel VT-x
  - [x] VT-d / IOMMU

### Memoria (RAM)
- **Capacidad Total**: 12 GB
- **Tipo**: DDR3
- **Velocidad**: 1333 MT/s
- **ECC**: No
- **Módulos Instalados**: 4
  
  | Slot | Capacidad | Velocidad | Fabricante | Part Number |
  |------|-----------|-----------|------------|-------------|
  | 1    | 2 GB | 1333 MT/s | Nanya | NT2GC64B8HC0NF-CG |
  | 2    | 4 GB | 1600 MT/s | Micron | 8JTF51264AZ-1G6E1 |
  | 3    | 2 GB | 1333 MT/s | Nanya | NT2GC64B8HC0NF-CG |
  | 4    | 4 GB | 1600 MT/s | Kingston | 9905584-003.A00LF |

- **Slots Disponibles**: 0 de 4
- **Capacidad Máxima**: 32 GB

### Almacenamiento

#### Discos Instalados

| Disco | Tipo | Capacidad | Modelo | Serial | Interfaz | Uso |
|-------|------|-----------|--------|--------|----------|-----|
| /dev/sda | SSD | 111.8 GB | SSD 120GB | SN-on-the-lable | SATA | Sistema (LVM) |
| /dev/sdb | HDD | 465.76 GB | TOSHIBA MQ01ABF0 | - | SATA | Backups |
| /dev/sdc | HDD | 931.51 GB | TOSHIBA MQ04ABF1 | - | SATA | Storage (ZFS) |

#### Configuración LVM
- **Volume Group**: pve
  - Physical Volumes: /dev/sda3
  - Capacidad Total**: 110.79 GB
  - **Logical Volumes**:
    - `pve/root`: 37.70 GB (ext4, sistema)
    - `pve/swap`: 8.00 GB (swap)
    - `pve/data`: 49.34 GB (thin pool para VMs)
    - `pve/vm-100-disk-0`: 8 GB (VM)
    - `pve/vm-102-disk-0`: 16 GB (VM)
    - `pve/vm-103-disk-0`: 8 GB (VM)

#### Configuración ZFS
- **Pool**: rpool (en /dev/sdc)
- **Tipo**: Single disk
- **Capacidad**: 931.5 GB
- **Uso**: Storage para VMs/Contenedores

### GPU / Tarjetas Gráficas

| Slot | Fabricante | Modelo | VRAM | Bus | Uso |
|------|------------|--------|------|-----|-----|
| Integrada | Intel | HD Graphics (Haswell) | Compartida | - | Display |

### Red

#### Interfaces Físicas

| Interfaz | Tipo | Velocidad | MAC Address | Estado | Uso |
|----------|------|-----------|-------------|--------|-----|
| eno1 | Ethernet | 1 Gbps | - | Up | Bridge vmbr0 (Gestión) |

#### Configuración de Bridges

| Bridge | Puertos | VLAN | IP | Uso |
|--------|---------|------|----|----|
| vmbr0 | eno1 | - | 192.168.1.78/24 | Gestión y VMs |

### Rendimiento (pveperf)
```
CPU BOGOMIPS:      26339.00
REGEX/SECOND:      2014853
HD SIZE:           37.67 GB (/dev/mapper/pve-root)
BUFFERED READS:    365.04 MB/sec
AVERAGE SEEK TIME: 0.09 ms
FSYNCS/SECOND:     1842.54
DNS EXT:           44.99 ms
DNS INT:           3.08 ms
```

---

## 🖥️ Nodo 2 - proxmedia

### Información General
- **Hostname**: proxmedia
- **IP de Gestión**: 192.168.1.82
- **Versión Proxmox**: 9.0.3
- **Kernel**: 6.14.8-2-pve
- **Fecha de Instalación**: 2025-11-09

### Hardware del Sistema
- **Fabricante**: Dell Inc.
- **Modelo**: Inspiron 7559 (Laptop Gaming)
- **Serial Number**: JZHLKD2
- **BIOS**: 
  - Versión: 1.3.0
  - Fecha: 12/01/2018

### Procesador (CPU)
- **Modelo**: Intel Core i7-6700HQ @ 2.60GHz
- **Arquitectura**: x86_64 (Skylake)
- **Sockets**: 1
- **Cores por Socket**: 4
- **Threads Totales**: 8 (HyperThreading habilitado)
- **Frecuencia Base**: 2.60 GHz
- **Frecuencia Max**: 3.50 GHz
- **Cache L3**: 6 MiB
- **Virtualización**: 
  - [x] Intel VT-x
  - [x] VT-d / IOMMU

### Memoria (RAM)
- **Capacidad Total**: 12 GB
- **Tipo**: DDR3
- **Velocidad**: 1600 MT/s
- **ECC**: No
- **Módulos Instalados**: 2
  
  | Slot | Capacidad | Velocidad | Fabricante | Part Number |
  |------|-----------|-----------|------------|-------------|
  | 1    | 8 GB | 1600 MT/s | Hynix | HMT41GS6DFR8A-PB |
  | 2    | 4 GB | 1600 MT/s | Hynix | HMT451S6BFR8A-PB |

- **Slots Disponibles**: 0 de 2
- **Capacidad Máxima**: 16 GB

### Almacenamiento

#### Discos Instalados

| Disco | Tipo | Capacidad | Modelo | Serial | Interfaz | Uso |
|-------|------|-----------|--------|--------|----------|-----|
| /dev/sda | SSD | 119.2 GB | SSD 128GB | AA000000000000001520 | SATA | Sistema (LVM) |
| /dev/sdb | HDD | 931.5 GB | TOSHIBA MQ02ABD100H | 76DUTA8NT | SATA | Storage |
| /dev/sdc | USB | 114.6 GB | SanDisk 3.2Gen1 | - | USB 3.2 | Boot/Instalador |

#### Configuración LVM
- **Volume Group**: pve
  - Physical Volumes: /dev/sda3
  - Capacidad Total: 118.24 GB
  - **Logical Volumes**:
    - `pve/root`: 39.56 GB (ext4, sistema)
    - `pve/swap`: 8.00 GB (swap)
    - `pve/data`: 53.93 GB (thin pool para VMs)

#### Configuración RAID Hardware
- **Sin RAID**: Discos individuales

### GPU / Tarjetas Gráficas

| Slot | Fabricante | Modelo | VRAM | Bus | Uso |
|------|------------|--------|------|-----|-----|
| Integrada | Intel | HD Graphics 530 | Compartida | - | Display |
| Dedicada | NVIDIA | GeForce GTX 960M | 4 GB | PCIe x16 | Disponible para Passthrough |

### Red

#### Interfaces Físicas

| Interfaz | Tipo | Velocidad | MAC Address | Estado | Uso |
|----------|------|-----------|-------------|--------|-----|
| enp4s0 | Ethernet | 1 Gbps | f4:8e:38:ea:9f:bb | Up | Bridge vmbr0 |
| wlp5s0 | WiFi | - | b8:81:98:c3:0c:5d | Down | No usado |

#### Configuración de Bridges

| Bridge | Puertos | VLAN | IP | Uso |
|--------|---------|------|----|----|
| vmbr0 | enp4s0 | - | 192.168.1.82/24 | Gestión y VMs |

### Sensores y Temperatura
- **Temperatura CPU (idle)**: N/A (lm-sensors no instalado)
- **Temperatura CPU (carga)**: N/A
- **Nota**: Es un laptop, monitorear temperaturas regularmente

### Rendimiento (pveperf)
```
CPU BOGOMIPS:      20799.92
HD SIZE:           39.56 GB (/dev/mapper/pve-root)
```

### Consumo Eléctrico
- **Laptop**: Dell Inspiron 7559
- **PSU**: Adaptador 130W
- **Batería**: Integrada (puede funcionar sin energía externa)

---

## 🔌 Infraestructura de Red del Cluster

### Switch
- **Switch**: Router principal con switch integrado
- **Gateway**: 192.168.1.254
- **Red**: 192.168.1.0/24

### UPS / Respaldo Eléctrico
- **Modelo UPS**: No documentado
- **Nota**: Nodo 2 (laptop) tiene batería integrada

---

## 📝 Notas Adicionales

### Peculiaridades del Hardware
- **Nodo 1 (proxmox)**: Desktop Dell OptiPlex, RAM mixta de diferentes fabricantes
- **Nodo 2 (proxmedia)**: Laptop Dell Inspiron gaming con GPU NVIDIA GTX 960M disponible para passthrough
- Ambos nodos tienen virtualización Intel VT-x habilitada
- Los dos tienen discos SSD para el sistema y HDDs adicionales para storage

### Limitaciones Conocidas
- **Nodo 1**: RAM heterogénea (diferentes velocidades limitadas a 1333 MT/s)
- **Nodo 2**: Solo 2 slots RAM (máximo 16 GB)
- **Nodo 2**: Es un laptop - vigilar temperaturas bajo carga
- Red limitada a 1 Gbps en ambos nodos

### Expansiones Futuras Planeadas
- Considerar upgrade de RAM en ambos nodos
- Evaluar agregar más storage (NAS/SAN compartido)
- Implementar 10 Gbps si se requiere más ancho de banda

### Garantías y Soporte
- **Nodo 1 (OptiPlex 9020)**: 
  - Fabricado: ~2014
  - Fuera de garantía
- **Nodo 2 (Inspiron 7559)**: 
  - Fabricado: ~2015-2016
  - Fuera de garantía

---

## 📚 Archivos de Referencia

- Reporte completo Nodo 1: `docs/proxmox-specs.txt`
- Reporte completo Nodo 2: `docs/proxmedia-specs.txt`
- Reporte HTML Nodo 1: `docs/proxmox-specs.html`
- Script de recopilación: `scripts/maintenance/collect-system-info.sh`
- Configuración de red: `configs/network/interfaces.conf.example`
- Configuración de storage: `configs/storage/storage.cfg.example`


---

## 🔌 Infraestructura de Red del Cluster

### Switches
- **Switch Principal**: 
  - Modelo: 
  - Puertos: 
  - Velocidad: 
  - VLANs configuradas: 

### Almacenamiento Compartido (si aplica)
- **Tipo**: (NFS/iSCSI/Ceph)
- **Servidor**: 
- **Capacidad**: 
- **Conectividad**: 

### UPS / Respaldo Eléctrico
- **Modelo UPS**: 
- **Capacidad**: VA / W
- **Autonomía**: minutos
- **Conexión**: USB/Serial/Red

---

## 📝 Notas Adicionales

### Peculiaridades del Hardware
- 

### Limitaciones Conocidas
- 

### Expansiones Futuras Planeadas
- 

### Garantías y Soporte
- **Nodo 1**: 
  - Garantía hasta: 
  - Contrato de soporte: 
- **Nodo 2**: 
  - Garantía hasta: 
  - Contrato de soporte: 

---

## 📚 Archivos de Referencia

- Reporte completo Nodo 1: `/tmp/proxmox-system-info/system-report-nodo1-TIMESTAMP.txt`
- Reporte completo Nodo 2: `/tmp/proxmox-system-info/system-report-nodo2-TIMESTAMP.txt`
- Script de recopilación: `scripts/maintenance/collect-system-info.sh`
- Configuración de red: `configs/network/interfaces.conf.example`
- Configuración de storage: `configs/storage/storage.cfg.example`
