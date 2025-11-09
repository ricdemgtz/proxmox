# Instalación de GitHub Copilot CLI en Proxmox

Esta guía explica cómo instalar y configurar GitHub Copilot CLI en tu nodo de Proxmox.

## 📋 Requisitos Previos

- Acceso SSH a tu nodo de Proxmox
- Permisos de administrador (root)
- Cuenta de GitHub con acceso a GitHub Copilot
- Conexión a internet

## 🚀 Instalación

### 1. Instalar Node.js

GitHub Copilot CLI requiere Node.js. Proxmox está basado en Debian, así que usaremos NodeSource para obtener una versión actualizada.

```bash
# Actualizar el sistema
apt update

# Instalar dependencias necesarias
apt install -y curl ca-certificates gnupg

# Descargar e instalar el repositorio de NodeSource (Node.js 20.x LTS)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

# Instalar Node.js
apt install -y nodejs

# Verificar la instalación
node --version
npm --version
```

### 2. Instalar GitHub Copilot CLI

Una vez que Node.js esté instalado, puedes instalar GitHub Copilot CLI globalmente:

```bash
# Instalar GitHub Copilot CLI
npm install -g @githubnext/github-copilot-cli

# Verificar la instalación
github-copilot-cli --version
```

### 3. Autenticación con GitHub

Necesitas autenticarte con tu cuenta de GitHub que tenga acceso a Copilot:

```bash
# Iniciar el proceso de autenticación
github-copilot-cli auth

# Esto abrirá un enlace en tu navegador o te proporcionará un código
# Sigue las instrucciones en pantalla para completar la autenticación
```

**Nota**: Si estás conectado por SSH sin interfaz gráfica, copia el enlace proporcionado y ábrelo en un navegador en tu computadora local.

### 4. Configurar Alias (Opcional pero Recomendado)

Para usar Copilot CLI de manera más conveniente, puedes configurar alias en tu shell:

```bash
# Agregar alias a tu .bashrc
cat >> ~/.bashrc << 'EOF'

# GitHub Copilot CLI aliases
eval "$(github-copilot-cli alias -- "$0")"
EOF

# Recargar la configuración
source ~/.bashrc
```

Después de configurar los alias, tendrás disponibles:
- `??` - Para hacer preguntas generales
- `git?` - Para preguntas relacionadas con Git
- `gh?` - Para preguntas relacionadas con GitHub CLI

## 💡 Uso Básico

### Hacer Preguntas Generales

```bash
# Usando el comando completo
github-copilot-cli what-the-shell "¿cómo listar todos los contenedores LXC en Proxmox?"

# O usando el alias (si lo configuraste)
?? "¿cómo listar todos los contenedores LXC en Proxmox?"
```

### Preguntas sobre Git

```bash
# Usando el alias
git? "¿cómo deshacer el último commit sin perder cambios?"
```

### Preguntas sobre GitHub

```bash
# Usando el alias
gh? "¿cómo crear un pull request desde la línea de comandos?"
```

## 🔧 Configuración Avanzada

### Configurar el Modelo

Puedes configurar preferencias adicionales:

```bash
# Ver configuración actual
github-copilot-cli config

# Establecer preferencias (si está disponible)
# github-copilot-cli config set <key> <value>
```

### Actualizar GitHub Copilot CLI

Para mantener Copilot CLI actualizado:

```bash
# Actualizar a la última versión
npm update -g @githubnext/github-copilot-cli

# Verificar la versión
github-copilot-cli --version
```

## 🛠️ Ejemplos Prácticos en Proxmox

### Gestión de VMs

```bash
?? "¿cómo crear una VM desde la línea de comandos en Proxmox?"
?? "¿cómo clonar una VM en Proxmox?"
?? "¿cómo cambiar la cantidad de RAM de una VM en Proxmox?"
```

### Gestión de Contenedores

```bash
?? "¿cómo crear un contenedor LXC en Proxmox?"
?? "¿cómo entrar a un contenedor LXC en Proxmox?"
?? "¿cómo hacer backup de un contenedor en Proxmox?"
```

### Gestión de Almacenamiento

```bash
?? "¿cómo agregar un disco NFS en Proxmox?"
?? "¿cómo ver el uso de almacenamiento en Proxmox?"
```

### Gestión de Red

```bash
?? "¿cómo crear un bridge de red en Proxmox?"
?? "¿cómo configurar una VLAN en Proxmox?"
```

## ⚠️ Solución de Problemas

### Error: comando no encontrado

Si después de instalar obtienes "command not found":

```bash
# Verificar que npm esté en el PATH
which npm

# Verificar la ubicación de paquetes globales de npm
npm config get prefix

# Agregar al PATH si es necesario
echo 'export PATH="$PATH:/usr/local/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Error de autenticación

Si tienes problemas para autenticarte:

```bash
# Limpiar credenciales anteriores
rm -rf ~/.config/github-copilot

# Volver a autenticar
github-copilot-cli auth
```

### Error de permisos

Si obtienes errores de permisos al instalar:

```bash
# Cambiar el directorio de npm global (alternativa a usar sudo)
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH="$PATH:~/.npm-global/bin"' >> ~/.bashrc
source ~/.bashrc

# Ahora reinstalar sin sudo
npm install -g @githubnext/github-copilot-cli
```

### Node.js desactualizado

Si tu versión de Node.js es muy antigua:

```bash
# Desinstalar versión antigua
apt remove nodejs

# Limpiar paquetes
apt autoremove

# Reinstalar siguiendo los pasos de la sección "Instalar Node.js"
```

## 🔒 Consideraciones de Seguridad

- **Credenciales**: GitHub Copilot CLI almacena tokens de autenticación en `~/.config/github-copilot`
- **Datos**: Las preguntas enviadas a Copilot son procesadas por los servicios de GitHub
- **Privacidad**: No compartas información sensible en tus preguntas (contraseñas, claves, etc.)
- **Acceso**: Asegúrate de que solo usuarios autorizados tengan acceso a tu nodo de Proxmox

## 📚 Recursos Adicionales

- [GitHub Copilot CLI Documentation](https://githubnext.com/projects/copilot-cli/)
- [GitHub Copilot](https://github.com/features/copilot)
- [Node.js Documentation](https://nodejs.org/en/docs/)
- [NPM Documentation](https://docs.npmjs.com/)

## ✅ Checklist de Instalación

- [ ] Node.js instalado y funcionando
- [ ] GitHub Copilot CLI instalado globalmente
- [ ] Autenticación con GitHub completada
- [ ] Alias configurados (opcional)
- [ ] Comando de prueba ejecutado con éxito
- [ ] Configuración verificada

## 📝 Notas

- GitHub Copilot CLI está en constante desarrollo, algunas características pueden cambiar
- Necesitas una suscripción activa de GitHub Copilot para usar esta herramienta
- La herramienta funciona mejor en inglés, pero también soporta otros idiomas
- Para mejores resultados, sé específico en tus preguntas

---

**Última actualización**: 2025-11-09
