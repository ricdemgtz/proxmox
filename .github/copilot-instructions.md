````instructions
# Proxmox Infrastructure Management - AI Agent Instructions

## Repository Purpose

This is a **configuration-as-code** repository for managing a Proxmox Virtual Environment (VE) **cluster**. It contains automation scripts, configurations, documentation, and inventory tracking—NOT the Proxmox software itself. All content is in Spanish (documentation, comments, logs).

## Cluster Architecture

**Current Deployment** (as of Nov 2025):
- **Cluster Name**: `proxmedia` 
- **Nodes**: 2-node cluster (`proxmox` @ 192.168.1.78, `proxmedia` @ 192.168.1.82)
- **Quorum**: 2 votes required, knet transport with corosync
- **Workload Distribution**:
  - `proxmox` node: Hosts LXC 100-105 (proxy, apps, media, adguard, uptimekuma) + VM 104 (haos)
  - `proxmedia` node: Hosts LXC 200 (mediaserver with Docker stack)

## Repository Structure

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

**Backup Script Workflow**:
1. Check disk space (`check_disk_space()` - requires 50GB minimum)
2. Backup VMs using `vzdump` with snapshot mode
3. Backup containers similarly
4. Cleanup old backups based on `RETENTION_DAYS` (default: 7)

### Inventory Management

`configs/vms/inventory.md` and `configs/containers/inventory.md` are **living documents** tracking:
- VM/CT IDs (100-199 = production, 200+ = development, 9000+ = templates)
- IP addresses to prevent conflicts
- Resource allocation (vCPU, RAM, disk)
- Privileged status (containers only—avoid privileged for security)

**CRITICAL**: When creating VMs/containers, update these tables immediately.

**Current Container Inventory** (from cluster data):
- LXC 100: proxy (192.168.1.100) - nginx-proxy-manager, cloudflared, portainer
- LXC 101: apps (192.168.1.101) - vaultwarden
- LXC 102: media (192.168.1.102) - immich stack (server, db, redis, ML)
- LXC 103: adguard (192.168.1.120) - AdGuard DNS blocker
- LXC 105: uptimekuma (192.168.1.70) - monitoring service
- LXC 200: mediaserver (192.168.1.50) - jellyfin, radarr, sonarr, qbittorrent stack

### Docker-in-LXC Pattern

**Multiple containers run Docker stacks** - this is a key architectural pattern:

1. **Container Config Requirements** (see LXC 105 config):
```bash
features: keyctl=1,nesting=1,fuse=1  # Enable nested containerization
lxc.apparmor.profile: unconfined
lxc.cgroup2.devices.allow: a
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```

2. **Inspecting Docker containers in LXC**:
```bash
# SSH into Proxmox node
pct exec <ctid> -- docker ps  # List containers
pct exec <ctid> -- docker inspect <container>  # Inspect
```

3. **Port Mapping**: Docker containers bind to LXC IP (e.g., `192.168.1.100:80-81->80-81/tcp`)

### Security Constraints

From `.gitignore` and `security-best-practices.md`:
- **Never commit**: `*.key`, `*.pem`, `*.password`, `credentials.conf`, actual backup files
- **Unprivileged containers by default**: `pct create <id> --unprivileged 1` (unless justified)
- **SSH hardening**: All docs assume key-based auth, fail2ban installed, custom ports
- **Firewall-first**: Always enable Proxmox firewall before deploying VMs/containers
- **2FA Recommended**: For administrative users via Web UI

### Cluster Operations

**Quorum Management**:
```bash
pvecm status        # Check cluster status, quorum, nodes
pvecm nodes         # List cluster nodes
pvecm expected 1    # Force quorum (EMERGENCY ONLY)
```

**Cluster Recreation** (see `docs/cluster-recreation-guide.md`):
- Comprehensive 8-phase process for cluster teardown/rebuild
- **Phase order is critical**: Always remove secondary node first, then primary
- Requires backups of `/etc/pve/`, `/etc/network/interfaces`, all VMs/containers
- Post-recreation: reconfigure storage, verify VMs, test migration

**Migration**:
```bash
qm migrate <vmid> <target-node>   # Migrate VM to other node
pct migrate <ctid> <target-node>  # Migrate container
```

### Common Proxmox Commands

```bash
# VMs (QEMU)
qm list                    # List all VMs
qm start/stop/status <vmid>
qm config <vmid>           # Show VM config
qm clone <vmid> <newid>    # Clone VM
qm unlock <vmid>           # Unlock stuck VM
vzdump <vmid>              # Backup VM

# Containers (LXC)
pct list                   # List all containers
pct start/stop/status <ctid>
pct enter <ctid>           # Shell into container
pct exec <ctid> -- <cmd>   # Execute command
pct unlock <ctid>          # Unlock stuck container

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
4. **Validate before commit**: Configs should be syntactically valid (`bash -n` for scripts)

### Monitoring Script Customization

`monitor-resources.sh` uses threshold variables:
```bash
ALERT_CPU_THRESHOLD=80
ALERT_RAM_THRESHOLD=85
ALERT_DISK_THRESHOLD=90
```

The `send_alert()` function is a **stub**—users must implement email/Telegram/Discord integration. Comments show examples but no actual implementation exists.

### System Information Collection

`scripts/maintenance/collect-system-info.sh` generates comprehensive reports:
- Hardware specs (CPU, RAM, disks, GPU, network cards)
- Proxmox configuration (VMs, containers, storage, cluster)
- Performance benchmarks (`pveperf`)
- Outputs both TXT and HTML reports to `/tmp/proxmox-system-info/`

Use this when documenting new hardware or troubleshooting.

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
  - `/etc/pve/corosync.conf` - Cluster configuration

## Troubleshooting Patterns

From `troubleshooting.md`, the diagnostic flow is:
1. **Check service status**: `systemctl status pveproxy/pvedaemon/pve-cluster`
2. **Inspect logs**: `journalctl -u <service> -f` or `tail -f /var/log/syslog`
3. **Verify resources**: `df -h`, `free -h`, `pvesm status`
4. **Unlock if stuck**: `qm unlock <vmid>` or `pct unlock <ctid>`
5. **Restart services**: `systemctl restart pveproxy pvedaemon pve-cluster`

For network issues: `brctl show`, `ip addr show`, restart bridges with `ifdown/ifup`.

**Cluster-specific issues**:
- "cluster not ready - no quorum": Check `pvecm status`, verify both nodes online
- Time sync critical: Nodes must have synchronized clocks (check `chrony` or `systemd-timesyncd`)
- Firewall ports: 22 (SSH), 8006 (Web UI), 5404-5405 (Corosync)

## Anti-Patterns to Avoid

- ❌ Don't use `sudo` in scripts (they run as root on Proxmox)
- ❌ Don't hardcode IPs/passwords (use variables or external secrets)
- ❌ Don't create privileged containers without documenting why in inventory
- ❌ Don't commit actual backup files (use `backups/README.md` for procedures)
- ❌ Don't use English in user-facing docs (Spanish is the standard)
- ❌ Don't remove cluster nodes in wrong order (secondary first, always)
- ❌ Don't interrupt cluster recreation mid-process (complete all phases)

## When in Doubt

- Check existing scripts in `scripts/` for patterns
- Reference `docs/setup-guide.md` for Proxmox-specific commands
- Consult `docs/security-best-practices.md` before modifying security configs
- Update inventory files whenever VMs/containers change
- Review `docs/cluster-recreation-guide.md` before any cluster modifications

````
