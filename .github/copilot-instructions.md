# Proxmox Infrastructure Management - AI Agent Instructions

## Repository Purpose

This is a **configuration-as-code** repository for managing a Proxmox Virtual Environment (VE) server. It contains automation scripts, configurations, documentation, and inventory tracking—NOT the Proxmox software itself. All content is in Spanish (documentation, comments, logs).

## Architecture & Structure

```
configs/          # Declarative configurations (version-controlled examples/templates)
├── network/      # interfaces.conf.example - bridges, VLANs, bonding
├── storage/      # storage.cfg.example - NFS, iSCSI, LVM definitions
├── vms/          # inventory.md - VM registry (ID, IP, resources, purpose)
└── containers/   # inventory.md - LXC container registry

scripts/          # Executable Bash automation (runs on Proxmox host)
├── backup/       # vzdump wrappers with retention policies
├── monitoring/   # Resource checks with configurable thresholds
└── maintenance/  # Update, cleanup, service health checks

docs/             # Operational guides in Spanish
```

**Key Pattern**: Configs are templates/examples (`.example` suffix) due to security. Actual configs live on the Proxmox host (`/etc/pve/`, `/etc/network/interfaces`). Scripts are designed to run directly on the Proxmox host via SSH.

## Critical Workflows

### Shell Script Patterns

All scripts in `scripts/` follow this structure:
- **Shebang**: `#!/bin/bash` with `set -e` for error handling
- **Logging**: Custom `log()` function writing to `/var/log/proxmox-*.log` with timestamps
- **Config Section**: Hardcoded variables at top (BACKUP_DIR, thresholds, retention days)
- **Functions**: Modular functions for each task, called by `main()` at end
- **No External Dependencies**: Use built-in Proxmox commands (`qm`, `pct`, `vzdump`, `pvesm`, `pveum`)

Example from `backup-vms.sh`:
```bash
# Users populate VMS="100 101" and CONTAINERS="200 201" at top
BACKUP_MODE="snapshot"  # or "suspend", "stop"
COMPRESSION="zstd"      # Proxmox-specific compressor

vzdump "$vmid" --mode "$BACKUP_MODE" --compress "$COMPRESSION" --dumpdir "$BACKUP_DIR"
```

### Inventory Management

`configs/vms/inventory.md` and `configs/containers/inventory.md` are **living documents** tracking:
- VM/CT IDs (100-199 = production, 200+ = development, 9000+ = templates)
- IP addresses to prevent conflicts
- Resource allocation (vCPU, RAM, disk)
- Privileged status (containers only—avoid privileged for security)

When creating VMs/containers, update these tables immediately.

### Security Constraints

From `.gitignore` and `security-best-practices.md`:
- **Never commit**: `*.key`, `*.pem`, `*.password`, `credentials.conf`, actual backup files
- **Unprivileged containers by default**: `pct create <id> --unprivileged 1` (unless justified)
- **SSH hardening**: All docs assume key-based auth, fail2ban installed, custom ports
- **Firewall-first**: Always enable Proxmox firewall before deploying VMs/containers

### Common Proxmox Commands

```bash
# VMs (QEMU)
qm list                    # List all VMs
qm start/stop/status <vmid>
qm config <vmid>           # Show VM config
qm clone <vmid> <newid>    # Clone VM
vzdump <vmid>              # Backup VM

# Containers (LXC)
pct list                   # List all containers
pct start/stop/status <ctid>
pct enter <ctid>           # Shell into container
pct exec <ctid> -- <cmd>   # Execute command

# Storage
pvesm status               # List storage
pvesm list <storage-name>  # Show contents

# Users/Permissions
pveum user add <user>@pve
pveum acl modify <path> -user <user> -role <role>
```

## Development Guidelines

### When Editing Scripts

1. **Test non-destructively first**: Use `echo` commands or `--dry-run` flags when available
2. **Check disk space before backups**: See `check_disk_space()` in `backup-vms.sh`
3. **Use retention policies**: Never accumulate indefinite backups (see `RETENTION_DAYS`)
4. **Maintain idempotency**: Scripts should be safe to re-run

### When Creating Configurations

1. **Use `.example` suffix**: Real configs contain sensitive data (IPs, credentials)
2. **Document in Spanish**: Match existing `# Configuración de...` comment style
3. **Reference official docs**: Include Proxmox Wiki links for complex setups
4. **Validate before commit**: Configs should be syntactically valid (bash -n for scripts)

### Monitoring Script Customization

`monitor-resources.sh` uses threshold variables:
```bash
ALERT_CPU_THRESHOLD=80
ALERT_RAM_THRESHOLD=85
ALERT_DISK_THRESHOLD=90
```

The `send_alert()` function is a **stub**—users must implement email/Telegram/Discord integration. Comments show examples but no actual implementation exists.

## Documentation Conventions

- **Language**: All documentation in Spanish (technical terms in English where standard)
- **Format**: Markdown with emoji section headers (`🚀`, `🔒`, `⚠️`)
- **Code blocks**: Always specify language (```bash, ```markdown)
- **Examples**: Provide concrete examples, not placeholders (see `setup-guide.md` for actual commands)
- **Checklists**: Use `- [ ]` task lists for procedural guides

## Integration Points

- **Proxmox Web UI**: Port 8006 (HTTPS) - scripts complement, not replace GUI
- **System logs**: Check `/var/log/daemon.log` (Proxmox services), `/var/log/auth.log` (SSH/fail2ban)
- **Configuration paths**:
  - `/etc/pve/storage.cfg` - Storage definitions
  - `/etc/network/interfaces` - Network config
  - `/etc/pve/qemu-server/<vmid>.conf` - VM configs
  - `/etc/pve/lxc/<ctid>.conf` - Container configs

## Troubleshooting Patterns

From `troubleshooting.md`, the diagnostic flow is:
1. **Check service status**: `systemctl status pveproxy/pvedaemon/pve-cluster`
2. **Inspect logs**: `journalctl -u <service> -f` or `tail -f /var/log/syslog`
3. **Verify resources**: `df -h`, `free -h`, `pvesm status`
4. **Unlock if stuck**: `qm unlock <vmid>` or `pct unlock <ctid>`
5. **Restart services**: `systemctl restart pveproxy pvedaemon pve-cluster`

For network issues: `brctl show`, `ip addr show`, restart bridges with `ifdown/ifup`.

## Anti-Patterns to Avoid

- ❌ Don't use `sudo` in scripts (they run as root on Proxmox)
- ❌ Don't hardcode IPs/passwords (use variables or external secrets)
- ❌ Don't create privileged containers without documenting why
- ❌ Don't commit actual backup files (use `backups/README.md` for procedures)
- ❌ Don't use English in user-facing docs (Spanish is the standard)

## When in Doubt

- Check existing scripts in `scripts/` for patterns
- Reference `docs/setup-guide.md` for Proxmox-specific commands
- Consult `docs/security-best-practices.md` before modifying security configs
- Update inventory files whenever VMs/containers change
