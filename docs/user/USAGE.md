# Usage Guide

## Command Reference

The `uu` command provides a simple interface for managing UU Game Booster on your OpenWRT router.

### Service Management

The `uu` script provides convenience commands for common operations. For full service control, use the init script directly:

```bash
# Status and restart (available via uu)
uu status
uu restart

# Start, stop, enable, disable (use init script)
/etc/init.d/uu-booster start
/etc/init.d/uu-booster stop
/etc/init.d/uu-booster enable
/etc/init.d/uu-booster disable
```

#### `uu status`

Check the current status of the UU Booster service.

```bash
uu status
```

**Output:**
```
UU Booster Status: Running
Version: 9.2.10
PID: 1234
```

This command queries the OpenWRT procd service manager to show if the service is running.

#### `uu restart`

Restart the UU Booster service.

```bash
uu restart
```

This is useful after configuration changes or to recover from errors.

This is equivalent to:
```bash
/etc/init.d/uu-booster restart
```

### Update Management

#### `uu check`

Check if a newer version of UU Booster binary is available.

```bash
uu check
```

**Output:**
```
Current version: 9.2.10
Latest version: 9.2.11
Update available: Yes
```

This command queries the NetEase API to compare your current version with the latest available version.

#### `uu update`

Download and install the latest version of UU Booster binary.

```bash
uu update
```

**Output:**
```
Checking for updates...
New version available: 9.2.11
Downloading from http://...
Validating MD5 checksum...
Installing...
Restarting service...
Update complete!
```

The update process:
1. Checks for available updates
2. Downloads the new binary from NetEase API
3. Validates the MD5 checksum
4. Installs the new version
5. Restarts the service

If the update fails, the service will continue running with the previous version.

## Configuration

### Configuration File Location

The main configuration file is located at:
```
/usr/sbin/uu/uu.conf
```

### Configuration Options

The configuration file contains settings such as:
- `version` - Current version of the UU plugin
- `device_id` - Unique device identifier
- Other plugin-specific settings

**Note**: Most configuration is handled automatically by the plugin. Manual editing is typically not required.

### Viewing Configuration

To view the current configuration:

```bash
cat /usr/sbin/uu/uu.conf
```

### Preserving Device ID

When reinstalling or updating, the device UUID is preserved to maintain your account linkage:

```bash
# The device UUID is stored in:
/usr/sbin/uu/.uuplugin_uuid

# On package removal, it's backed up to:
/etc/uu/.uuplugin_uuid
```

This ensures you don't lose your device association when updating or reinstalling.

## Firewall Rules

The package automatically configures firewall rules necessary for UU Booster to function.

### Viewing Firewall Rules

```bash
# View UU Booster firewall section
uci show firewall.uu

# View related firewall rules
uci show firewall | grep uu
```

### Firewall Rules Structure

The package creates:

1. **UU Zone**: A dedicated zone for UU traffic with masquerading enabled
2. **LAN to UU**: Forwarding rule from LAN zone to UU zone
3. **UU to LAN**: Forwarding rule from UU zone to LAN zone

### Manual Firewall Configuration

If automatic firewall configuration fails, you can manually add rules:

```bash
# Create UU zone
uci set firewall.uu=zone
uci set firewall.uu.name=uu
uci set firewall.uu.input=ACCEPT
uci set firewall.uu.output=ACCEPT
uci set firewall.uu.forward=ACCEPT
uci set firewall.uu.masq=1
uci set firewall.uu.network=uu

# Add forwarding from LAN to UU
uci set firewall.lan_to_uu=forwarding
uci set firewall.lan_to_uu.src=lan
uci set firewall.lan_to_uu.dest=uu

# Add forwarding from UU to LAN
uci set firewall.uu_to_lan=forwarding
uci set firewall.uu_to_lan.src=uu
uci set firewall.uu_to_lan.dest=lan

# Commit changes
uci commit firewall
/etc/init.d/firewall reload
```

## Service Integration

### Procd Integration

The UU Booster service is integrated with OpenWRT's procd system for reliable service management.

**Service Details:**
- Service name: `uu-booster`
- Start priority: 98 (late startup)
- Respawn: Enabled (restarts on failure)
- Logs: Both stdout and stderr are captured

### Viewing Service Status

```bash
# Check if service is enabled
/etc/init.d/uu-booster enabled

# Check service status
/etc/init.d/uu-booster status

# View detailed service information
procd status uu-booster
```

### Managing Service

Alternative methods using init scripts:

```bash
# Using init script directly
/etc/init.d/uu-booster start
/etc/init.d/uu-booster stop
/etc/init.d/uu-booster restart
/etc/init.d/uu-booster status

# Enable/disable on boot
/etc/init.d/uu-booster enable
/etc/init.d/uu-booster disable
```

## Viewing Logs

### System Logs

All UU Booster messages are logged to the system log:

```bash
# View all UU Booster logs
logread | grep uu

# View real-time logs
logread -f | grep uu

# View with timestamps
logread -e uu
```

### Service-Specific Logs

The service logs both stdout and stderr:

```bash
# Check if logread shows service output
logread | grep "uu-booster"
```

### Saving Logs to File

To save logs for analysis:

```bash
logread | grep uu > /tmp/uu-logs.txt

# Or save all logs
logread > /tmp/full-logs.txt
```

## Common Usage Scenarios

### Scenario 1: First-Time Setup

After installation, verify everything is working:

```bash
# Check service status
uu status

# View service logs
logread | grep uu-booster

# Verify configuration
cat /usr/sbin/uu/uu.conf

# Check firewall rules
uci show firewall.uu
```

### Scenario 2: Regular Updates

Periodically check for and install updates:

```bash
# Check for updates
uu check

# If update available, install it
uu update

# Verify update
uu status
```

### Scenario 3: Troubleshooting

If you experience issues:

```bash
# Restart the service
uu restart

# Check status
uu status

# View logs
logread | grep uu-booster

# Test binary manually
/usr/sbin/uu/uuplugin /usr/sbin/uu/uu.conf
```

### Scenario 4: Pre-Upgrade Check

Before upgrading OpenWRT:

```bash
# Check current version
uu status

# Note down version for comparison after upgrade

# After OpenWRT upgrade, verify service still works:
uu status
```

## Advanced Usage

### Manual Binary Download

If automatic download fails, you can manually download the binary:

```bash
# Determine your architecture
ARCH=$(cat /etc/openwrt_release | grep DISTRIB_ARCH | awk -F "'" '{print $2}')

# Download from NetEase API
API_TYPE="openwrt-${ARCH%%-*}"
URL=$(curl -s "http://router.uu.163.com/api/plugin?type=$API_TYPE" | sed -n 's/.*"url":"\([^"]*\)".*/\1/p')

# Download and install
curl -o /tmp/uuplugin.tar.gz "$URL"
tar -xzf /tmp/uuplugin.tar.gz -C /usr/sbin/uu/
```

### Testing API Connection

Test if the UU API is accessible:

```bash
# Test API response
curl "http://router.uu.163.com/api/plugin?type=openwrt-x86_64"
```

Expected response:
```json
{
  "md5": "768cd1bc4ddee165d5aea91f4d03427a",
  "status": "ok",
  "url": "http://uurouter.gdl.netease.com/...",
  "url_bak": "http://uurouter.gdl04.netease.com/..."
}
```

### Checking Dependencies

Verify required modules are loaded:

```bash
# Check tun module
lsmod | grep tun

# If not loaded, load it
insmod tun

# Make it persistent
echo "tun" >> /etc/modules.d/uu-booster
```

### Service Health Check

Create a simple health check:

```bash
#!/bin/sh
# Check if service is running
if ! /etc/init.d/uu-booster status | grep -q "running"; then
    echo "Service is not running"
    exit 1
fi

# Check if binary exists
if [ ! -f /usr/sbin/uu/uuplugin ]; then
    echo "Binary not found"
    exit 1
fi

# Check if config exists
if [ ! -f /usr/sbin/uu/uu.conf ]; then
    echo "Config not found"
    exit 1
fi

echo "Health check passed"
exit 0
```

Save as `/usr/bin/uu-health` and make executable:
```bash
chmod +x /usr/bin/uu-health
```

## Performance Monitoring

### Monitoring Resource Usage

```bash
# Check CPU and memory usage
top | grep uuplugin

# Check process details
ps aux | grep uuplugin

# Check memory usage specifically
ps aux | grep uuplugin | awk '{print "Memory:", $6, "KB"}'
```

### Monitoring Network Connections

```bash
# Check network connections
netstat -an | grep uuplugin

# Check for listening ports
netstat -an | grep LISTEN | grep uu

# Check active connections
netstat -an | grep ESTABLISHED | grep uu
```

### Monitoring Logs in Real-Time

```bash
# Watch UU Booster logs in real-time
logread -f | grep uu
```

## Integration with Other Services

### DNS Integration

If you use custom DNS, ensure it's properly configured for UU Booster:

```bash
# Check DNS settings
uci show dhcp

# Ensure DNS resolution works
nslookup router.uu.163.com
```

### VPN Compatibility

If you use VPN on your router:

- UU Booster creates its own network namespace
- Ensure VPN rules don't interfere with UU Booster traffic
- You may need to add specific firewall rules to exclude UU Booster traffic from VPN

**Example: Exclude UU Booster traffic from VPN**

```bash
# Add rule to exclude UU traffic from VPN (adjust as needed)
# This is a general example, actual configuration depends on your VPN setup
```

### QoS Integration

If you use QoS on your router:

- Ensure UU Booster traffic is properly classified
- You may want to give UU traffic higher priority
- Check that QoS rules don't interfere with UU acceleration

## Backup and Restore

### Backing Up Configuration

```bash
# Backup UU Booster configuration
tar -czf /tmp/uu-backup-$(date +%Y%m%d).tar.gz /usr/sbin/uu/ /etc/uu/ /etc/init.d/uu-booster

# Copy to safe location
scp /tmp/uu-backup-*.tar.gz user@backup-server:/backups/
```

### Restoring Configuration

```bash
# Stop service
uu stop

# Restore from backup
tar -xzf uu-backup-YYYYMMDD.tar.gz -C /

# Start service
uu start
```

## Getting Help

If you encounter any issues:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. [Open an Issue on GitHub](https://github.com/LASER-Yi/uu-booster/issues)
3. Provide detailed information about your issue

### Information to Include

When reporting issues, provide:

```bash
# OpenWRT version
cat /etc/openwrt_release

# UU Booster version
uu status

# Service logs
logread | grep uu-booster > /tmp/uu-error.log

# Configuration
cat /usr/sbin/uu/uu.conf
```
