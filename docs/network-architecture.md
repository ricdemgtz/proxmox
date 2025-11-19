# Arquitectura de Red - Cluster Proxmox

Documentación completa de la topología de red del cluster Proxmedia.

## 📊 Diagrama de Red

```
Internet
    |
    ├─── Router/Gateway (192.168.1.1)
    |
    └─── Red LAN: 192.168.1.0/24
         |
         ├─── Nodo Proxmox #1 (proxmox) ─────── 192.168.1.78
         |    │
         |    ├─── LXC 100 (proxy) ─────────── 192.168.1.100
         |    │    └─── Docker:
         |    │         ├─── nginx-proxy-manager (80, 81, 443)
         |    │         ├─── cloudflared (9090 local)
         |    │         ├─── portainer (8000, 9443)
         |    │         └─── helloworld
         |    │
         |    ├─── LXC 101 (apps) ─────────── 192.168.1.101
         |    │    └─── Docker:
         |    │         ├─── vaultwarden (8080→80)
         |    │         └─── portainer (9443)
         |    │
         |    ├─── LXC 102 (media) ───────── 192.168.1.102
         |    │    └─── Docker:
         |    │         ├─── immich-server (2283)
         |    │         ├─── immich-db (5432)
         |    │         ├─── immich-redis (6379)
         |    │         ├─── immich-ml
         |    │         └─── portainer (9443)
         |    │
         |    ├─── LXC 103 (adguard) ──────── 192.168.1.120
         |    │    └─── AdGuard Home (DNS)
         |    │
         |    ├─── LXC 105 (uptimekuma) ───── 192.168.1.70
         |    │    └─── Uptime Kuma (monitoring)
         |    │
         |    └─── VM 104 (haos) ───────────── 192.168.1.??? (pendiente qemu-guest-agent)
         |         └─── Home Assistant OS
         |
         └─── Nodo Proxmox #2 (proxmedia) ─── 192.168.1.82
              │
              └─── LXC 200 (mediaserver) ──── 192.168.1.50
                   └─── Docker:
                        ├─── jellyfin (8096, 8920)
                        ├─── jellyseerr (5055)
                        ├─── radarr (7878)
                        ├─── sonarr (8989)
                        ├─── prowlarr (9696)
                        ├─── bazarr (6767)
                        ├─── qbittorrent (8080, 6881)
                        └─── portainer (9443)
```

## 🌐 Tabla de Direcciones IP

### Infraestructura del Cluster

| Dispositivo | Tipo | IP Local | IP Tailscale | Función | Estado |
|-------------|------|----------|--------------|---------|--------|
| proxmox | Nodo Proxmox | 192.168.1.78 | 100.96.253.120 | Nodo principal del cluster | Online |
| proxmedia | Nodo Proxmox | 192.168.1.82 | 100.79.135.103 | Nodo secundario del cluster | Online |

### Contenedores LXC

| CT ID | Nombre | IP Local | IP Tailscale | MAC | DHCP/Static | Nodo |
|-------|--------|----------|--------------|-----|-------------|------|
| 100 | proxy | 192.168.1.100 | - | - | DHCP | proxmox |
| 101 | apps | 192.168.1.101 | - | - | DHCP | proxmox |
| 102 | media | 192.168.1.102 | - | - | DHCP | proxmox |
| 103 | adguard | 192.168.1.120 | 100.109.98.48 | - | DHCP | proxmox |
| 105 | uptimekuma | 192.168.1.70 | 100.101.238.45 | BC:24:11:CA:F1:FC | DHCP | proxmox |
| 200 | mediaserver | 192.168.1.50 | 100.78.240.75 | - | DHCP | proxmedia |

### Máquinas Virtuales

| VM ID | Nombre | IP | DHCP/Static | Estado | Nodo |
|-------|--------|-----|-------------|--------|------|
| 104 | haos | Pendiente | DHCP | Running | proxmox |

**Nota**: VM 104 requiere instalación de qemu-guest-agent para reportar IP

## 🔌 Mapa de Puertos por Servicio

### LXC 100 - Proxy (192.168.1.100)

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| 80 | Nginx Proxy Manager | TCP | LAN | HTTP |
| 81 | Nginx Proxy Manager Admin | TCP | LAN | Panel de administración |
| 443 | Nginx Proxy Manager | TCP | LAN/WAN | HTTPS |
| 8000 | Portainer | TCP | LAN | Gestión Docker |
| 9443 | Portainer | TCP | LAN | Gestión Docker HTTPS |
| 9090 | Cloudflared (local) | TCP | Localhost | Metrics/Admin |

### LXC 101 - Apps (192.168.1.101)

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| 8080 | Vaultwarden | TCP | LAN | Gestor de contraseñas |
| 9443 | Portainer | TCP | LAN | Gestión Docker HTTPS |

### LXC 102 - Media (192.168.1.102)

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| 2283 | Immich Server | TCP | LAN | Gestión de fotos |
| 9443 | Portainer | TCP | LAN | Gestión Docker HTTPS |

**Puertos internos Docker** (no expuestos):
- 5432: PostgreSQL
- 6379: Redis

### LXC 103 - AdGuard (192.168.1.120)

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| 53 | DNS | TCP/UDP | LAN | Servidor DNS con bloqueo de ads |
| 80 | AdGuard Web UI | TCP | LAN | Panel de administración |

### LXC 105 - Uptime Kuma (192.168.1.70)

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| 3001 | Uptime Kuma | TCP | LAN | Dashboard de monitoreo |

### LXC 200 - Mediaserver (192.168.1.50)

| Puerto | Servicio | Protocolo | Acceso | Descripción |
|--------|----------|-----------|--------|-------------|
| 5055 | Jellyseerr | TCP | LAN | Peticiones de contenido |
| 6767 | Bazarr | TCP | LAN | Gestión de subtítulos |
| 6881 | qBittorrent | TCP/UDP | LAN/WAN | Puerto BitTorrent |
| 7878 | Radarr | TCP | LAN | Gestión de películas |
| 8080 | qBittorrent WebUI | TCP | LAN | Interfaz web |
| 8096 | Jellyfin HTTP | TCP | LAN | Streaming de medios |
| 8920 | Jellyfin HTTPS | TCP | LAN | Streaming HTTPS |
| 8989 | Sonarr | TCP | LAN | Gestión de series |
| 9696 | Prowlarr | TCP | LAN | Gestión de indexers |

## 🔐 Seguridad de Red

### Firewall de Proxmox

**Puertos abiertos en nodos**:
- 22 (SSH): Administración remota
- 8006 (Web UI): Interfaz web de Proxmox
- 5404-5405 (Corosync): Comunicación del cluster

### Consideraciones de Seguridad

1. **Segmentación**: Actualmente todos los servicios están en la misma VLAN (192.168.1.0/24)
2. **Acceso Externo**: Solo a través de Nginx Proxy Manager (LXC 100) y Cloudflare Tunnel
3. **DNS Interno**: AdGuard Home (192.168.1.120) puede actuar como DNS primario
4. **Aislamiento**: Contenedores Docker usan redes bridge internas

### Recomendaciones de Seguridad

- [ ] Configurar IP estática para servicios críticos (actualmente usan DHCP)
- [ ] Implementar VLANs para segmentar tráfico (ej: VLAN management, VLAN services, VLAN guest)
- [ ] Configurar firewall por contenedor en Proxmox
- [ ] Habilitar fail2ban en nodos Proxmox
- [ ] Restringir acceso SSH a IPs específicas
- [ ] Configurar 2FA en Proxmox Web UI

## 📡 Redes Docker Internas

### LXC 100 - Proxy

```
Bridge Networks:
├─── proxy_proxy_net (172.18.0.0/16)
│    ├─── nginx-proxy-manager (172.18.0.3)
│    ├─── cloudflared (172.18.0.4)
│    └─── helloworld (172.18.0.2)
└─── bridge (172.17.0.0/16)
     └─── portainer (172.17.0.2)
```

### LXC 101 - Apps

```
Bridge Networks:
├─── vault_default (172.18.0.0/16)
│    └─── vaultwarden (172.18.0.2)
└─── bridge (172.17.0.0/16)
     └─── portainer (172.17.0.2)
```

### LXC 102 - Media

```
Bridge Networks:
├─── immich_immich-net (172.18.0.0/16)
│    ├─── immich-redis (172.18.0.2)
│    ├─── immich-machine-learning (172.18.0.3)
│    ├─── immich-db (172.18.0.4)
│    └─── immich-server (172.18.0.5)
└─── bridge (172.17.0.0/16)
     └─── portainer (172.17.0.2)
```

### LXC 200 - Mediaserver

```
Bridge Networks:
├─── mediaserver_default (172.18.0.0/16)
│    ├─── jellyfin (172.18.0.2)
│    ├─── qbittorrent (172.18.0.3)
│    ├─── jellyseerr (172.18.0.4)
│    ├─── sonarr (172.18.0.5)
│    ├─── prowlarr (172.18.0.6)
│    ├─── radarr (172.18.0.7)
│    └─── bazarr (172.18.0.8)
└─── bridge (default)
     └─── portainer
```

## 🔧 Configuración de Red en Proxmox

### Bridge vmbr0

Todos los contenedores y VMs están conectados al bridge principal `vmbr0`:

```conf
auto vmbr0
iface vmbr0 inet static
    address 192.168.1.78/24  # (o .82 en proxmedia)
    gateway 192.168.1.1
    bridge-ports <interface física>
    bridge-stp off
    bridge-fd 0
```

### Configuración de Red en LXC

Ejemplo de configuración de red para LXC 105 (Uptime Kuma):

```conf
net0: name=eth0,bridge=vmbr0,hwaddr=BC:24:11:CA:F1:FC,ip=dhcp,ip6=auto,type=veth
```

- **bridge=vmbr0**: Conectado al bridge principal
- **ip=dhcp**: Obtiene IP automáticamente (debería ser estática para producción)
- **type=veth**: Virtual Ethernet pair

## 📋 Checklist de Configuración de Red

### Para Nuevos Contenedores/VMs

- [ ] Asignar IP en rango disponible (verificar inventario)
- [ ] Documentar en `configs/containers/inventory.md` o `configs/vms/inventory.md`
- [ ] Configurar hostname descriptivo
- [ ] Configurar DNS (apuntar a AdGuard 192.168.1.120 si aplica)
- [ ] Abrir puertos necesarios en firewall
- [ ] Configurar reverse proxy en NPM si requiere acceso externo
- [ ] Actualizar monitoreo en Uptime Kuma
- [ ] Documentar en este archivo

### Rangos de IPs Recomendados

Para mantener organización:

| Rango | Propósito | Ejemplo |
|-------|-----------|---------|
| .1 - .50 | Infraestructura (routers, switches, APs) | Router: .1 |
| .50 - .99 | Servicios y aplicaciones | Mediaserver: .50, Uptime Kuma: .70 |
| .100 - .149 | Contenedores LXC (producción) | Proxy: .100, Apps: .101, etc. |
| .150 - .199 | VMs y servicios especiales | HAOS: .??? |
| .200 - .254 | DHCP pool / dispositivos temporales | - |

## 🔍 Comandos Útiles de Red

### Desde Proxmox Host

```bash
# Ver configuración de red
ip addr show
cat /etc/network/interfaces

# Ver bridges
brctl show

# Ver tabla de rutas
ip route show

# Ping a todos los servicios
ping -c 3 192.168.1.100  # proxy
ping -c 3 192.168.1.101  # apps
ping -c 3 192.168.1.102  # media
ping -c 3 192.168.1.120  # adguard
ping -c 3 192.168.1.70   # uptimekuma
ping -c 3 192.168.1.50   # mediaserver
```

### Desde dentro de un LXC

```bash
# Ver IP del contenedor
pct exec 105 -- ip addr show eth0

# Ver gateway
pct exec 105 -- ip route show

# Test de conectividad
pct exec 105 -- ping -c 3 8.8.8.8

# Ver DNS configurado
pct exec 105 -- cat /etc/resolv.conf
```

### Escaneo de red

```bash
# Desde host o contenedor con nmap
nmap -sn 192.168.1.0/24  # Scan de hosts activos

# Ver puertos abiertos de un servicio
nmap -p- 192.168.1.100  # Scan completo del proxy
```

## 🌍 Acceso Externo

### A través de Cloudflare Tunnel (Recomendado)

```
Internet → Cloudflare → cloudflared (LXC 100) → nginx-proxy-manager → Servicios
```

**Ventajas**:
- No requiere abrir puertos en router
- Protección DDoS de Cloudflare
- SSL/TLS automático
- Oculta IP real del servidor

### A través de Port Forwarding (No recomendado)

Si se usa port forwarding directo:

```
Internet → Router:443 → 192.168.1.100:443 (NPM) → Servicios
```

## � Dominios y Túneles Configurados

### Nginx Proxy Manager - Rutas Publicadas

Configurados en LXC 100 (proxy) - 192.168.1.100:

| # | Dominio | Destino (IP:Puerto) | SSL | Propósito |
|---|---------|---------------------|-----|-----------|
| 1 | nas.disccheep.com | http://196.168.1.100:80 | ❌ | NAS Storage |
| 2 | pmv.disccheep.com | https://192.168.1.78:8006 | ✅ | Proxmox Web UI |
| 3 | test.disccheep.com | http://nginx-proxy-manager:80 | ❌ | Testing NPM |
| 4 | vault.disccheep.com | http://192.168.1.101:8080 | ❌ | Vaultwarden |
| 5 | immich.disccheep.com | http://192.168.1.100:80 | ❌ | Immich (debe ser .102) |
| 6 | fin.disccheep.com | http://192.168.1.50:8096 | ❌ | Jellyfin |

**Notas**:
- Todos los dominios *.disccheep.com apuntan al túnel de Cloudflare
- Entrada #5 (immich) tiene IP incorrecta, debería apuntar a 192.168.1.102:2283
- Solo pmv.disccheep.com tiene SSL configurado

### Red Tailscale (VPN Mesh)

Red privada virtual para acceso remoto seguro:

| Dispositivo | IP Tailscale | IP Local | Estado | Uso |
|-------------|--------------|----------|--------|-----|
| proxmox | 100.96.253.120 | 192.168.1.78 | Active | Acceso SSH remoto al nodo principal |
| proxmedia | 100.79.135.103 | 192.168.1.82 | Active | Acceso SSH remoto al nodo secundario |
| mediaserver (LXC 200) | 100.78.240.75 | 192.168.1.50 | Active | Acceso directo a Jellyfin y servicios media |
| adguard (LXC 103) | 100.109.98.48 | 192.168.1.120 | Idle | Configuración DNS remota |
| uptimekuma (LXC 105) | 100.101.238.45 | 192.168.1.70 | Active | Dashboard de monitoreo remoto |

**Ventajas de Tailscale**:
- Acceso punto a punto cifrado sin abrir puertos en el router
- IP persistente para cada dispositivo (100.x.x.x)
- Funciona como backup si Cloudflare Tunnel falla
- Latencia más baja que túneles HTTP

**Comando de conexión SSH vía Tailscale**:
```bash
# Conectar a nodo proxmox desde cualquier lugar
ssh root@100.96.253.120

# Conectar a nodo proxmedia
ssh root@100.79.135.103

# Acceder a Jellyfin vía Tailscale (bypass NPM)
http://100.78.240.75:8096
```

## �📊 Ancho de Banda Estimado

| Servicio | Uso Normal | Uso Pico | Notas |
|----------|-----------|----------|-------|
| Jellyfin | 5-20 Mbps | 50+ Mbps | Depende de transcodificación |
| Immich | 1-5 Mbps | 10 Mbps | Uploads de fotos |
| Vaultwarden | < 1 Mbps | 1 Mbps | Tráfico mínimo |
| qBittorrent | Variable | 100+ Mbps | Limitar según necesidad |
| Proxmox Cluster | < 1 Mbps | 10 Mbps | Sync y migraciones |

## 📝 Notas Importantes

1. **DHCP vs Estática**: Todos los LXC usan DHCP. Para producción, se recomienda IPs estáticas configuradas en `/etc/pve/lxc/<ctid>.conf`

2. **Gateway**: Todos los dispositivos usan 192.168.1.1 como gateway predeterminado

3. **DNS**: Considerar configurar AdGuard (192.168.1.120 / 100.109.98.48) como DNS primario para todos los contenedores

4. **Cluster Communication**: Los nodos se comunican por la misma red LAN en puertos 5404-5405 (Corosync)

5. **Port Conflicts**: Múltiples servicios usan puerto 9443 (Portainer), pero en IPs diferentes

6. **IPv6**: Configurado como auto en algunos contenedores pero probablemente no usado

7. **Acceso Externo**: Tres métodos disponibles:
   - **Cloudflare Tunnel** (Principal): Túnel seguro vía cloudflared en LXC 100
   - **Tailscale VPN** (Backup/Admin): Acceso directo punto a punto
   - **Port Forwarding** (Deshabilitado): No recomendado

8. **Configuración NPM**: Revisar entrada #5 (immich.disccheep.com) - apunta a IP incorrecta

9. **Tailscale**: 5 dispositivos conectados activamente a la red mesh privada

10. **IP Pública**: 187.207.106.17 (visible en conexiones Tailscale directas)

---

**Última actualización**: 2025-11-19
**Administrador**: Ricardo Gutierrez
**Cluster**: proxmedia (2 nodos)
