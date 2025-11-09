# Especificaciones de Hardware - Cluster Proxmox

Documentación detallada de las especificaciones de hardware de cada nodo del cluster.

**Última actualización**: [FECHA]

---

## 📊 Resumen del Cluster

| Especificación | Total Cluster | Nodo 1 | Nodo 2 |
|----------------|---------------|--------|--------|
| **CPU Cores Totales** | - | - | - |
| **RAM Total** | - | - | - |
| **Almacenamiento Total** | - | - | - |
| **Interfaces de Red** | - | - | - |

---

## 🖥️ Nodo 1

### Información General
- **Hostname**: 
- **IP de Gestión**: 
- **Versión Proxmox**: 
- **Kernel**: 
- **Fecha de Instalación**: 

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
- **Fecha de Instalación**: 

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
