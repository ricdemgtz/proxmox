# Configuraciones de Red / Network Configurations

Este directorio contiene las configuraciones de red del servidor Proxmox.

## Archivos de Configuración

### interfaces.conf
Configuración de las interfaces de red del host Proxmox.

Ejemplo de estructura:
- Interfaces físicas (eth0, eth1, etc.)
- Bridges (vmbr0, vmbr1, etc.)
- VLANs
- Bonding/agregación de enlaces

### firewall.conf
Reglas de firewall para el host y las VMs/Containers.

### dns.conf
Configuración de servidores DNS.

### routes.conf
Rutas estáticas adicionales si son necesarias.

## Mejores Prácticas

1. **Documenta cada cambio**: Incluye comentarios en los archivos de configuración
2. **Versiona antes de aplicar**: Siempre haz commit antes de aplicar cambios en producción
3. **Prueba en desarrollo**: Si es posible, prueba cambios en un entorno de desarrollo primero
4. **Backup de configuración actual**: Antes de modificar, guarda una copia de la configuración actual

## Aplicar Configuraciones

```bash
# Verificar configuración de red
cat /etc/network/interfaces

# Aplicar cambios (CUIDADO: puede interrumpir la conexión)
systemctl restart networking

# O reiniciar interfaz específica
ifdown vmbr0 && ifup vmbr0
```

## Seguridad

- No incluyas contraseñas de VPN o WiFi en estos archivos
- Usa variables o referencias a archivos de secretos externos
- Revisa que no se expongan IPs internas sensibles
