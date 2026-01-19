# Troubleshooting

## ⚠️ Important Note

This project has only been tested on OpenWRT 24.10.1. If you are using a different version and encounter issues, please open a GitHub Issue with:
- Your OpenWRT version (`cat /etc/openwrt_release`)
- Router model and architecture
- Detailed error messages or logs
- Steps to reproduce the problem

Your feedback helps improve compatibility across OpenWRT versions!

---

## Installation Issues

### Problem: Package Installation Fails

**Symptoms:**
```
Collected errors:
 * pkg_check_dependencies: uubad
 * Package dependency check failed.
```

**Solutions:**

1. **Check OpenWRT version compatibility**
   ```bash
   cat /etc/openwrt_release
   ```
   Ensure you're running OpenWRT 21.03 or higher.

2. **Verify kmod-tun is available**
   ```bash
   opkg list | grep kmod-tun
   ```

3. **Update package lists**
   ```bash
   opkg update
   opkg install uu-booster_*.ipk
   ```

4. **Check disk space**
   ```bash
   df -h
   ```
   Ensure at least 5MB free space is available.

### Problem: Binary Download Fails

**Symptoms:**
```
Downloading and installing UU Booster binary...
Failed to download from primary URL
```

**Solutions:**

1. **Check internet connectivity**
   ```bash
   ping -c 3 router.uu.163.com
   ```

2. **Verify API is accessible**
   ```bash
   curl -v http://router.uu.163.com/api/plugin?type=openwrt-x86_64
   ```

3. **Check firewall/DNS**
   ```bash
   # Check DNS resolution
   nslookup router.uu.163.com

   # Check firewall rules
   iptables -L -n | grep OUTPUT
   ```

4. **Manual retry**
   ```bash
   /usr/bin/uu update
   ```

5. **Check logs**
   ```bash
   logread | grep uu-booster
   ```

### Problem: Architecture Detection Fails

**Symptoms:**
```
Unknown architecture: xyz123
```

**Solutions:**

1. **Check your architecture manually**
   ```bash
   cat /etc/openwrt_release | grep DISTRIB_ARCH
   ```

2. **Verify supported architectures**
   - aarch64_*
   - arm_*
   - mipsel_*
   - x86_64

3. **If your architecture is not supported**
   - [Open an Issue](https://github.com/LASER-Yi/uu-booster/issues) with:
     - Your architecture string
     - Router model
     - CPU information: `cat /proc/cpuinfo`

### Problem: MD5 Checksum Mismatch

**Symptoms:**
```
MD5 checksum mismatch: expected xxx..., got yyy...
```

**Solutions:**

1. **Wait and retry**
   The download may have been corrupted. Run:
   ```bash
   /usr/bin/uu update
   ```

2. **Check available disk space**
   ```bash
   df -h /tmp
   ```
   Ensure sufficient space for download.

3. **Verify network stability**
   ```bash
   ping -c 10 router.uu.163.com
   ```

4. **Manual download**
   See [USAGE.md](USAGE.md#manual-binary-download) for manual download instructions.

5. **Report issue**
   If problem persists, [open an Issue](https://github.com/LASER-Yi/uu-booster/issues).

### Problem: Permission Denied Errors

**Symptoms:**
```
mkdir: cannot create directory '/usr/sbin/uu': Permission denied
```

**Solutions:**

1. **Ensure running as root**
   ```bash
   whoami
   # Should output: root
   ```

2. **Check directory permissions**
   ```bash
   ls -la /usr/sbin/
   ```

3. **Manually create directory if needed**
   ```bash
   mkdir -p /usr/sbin/uu
   chmod 755 /usr/sbin/uu
   ```

---

## Service Issues

### Problem: Service Won't Start

**Symptoms:**
```
/etc/init.d/uu-booster start
Starting uu-booster... failed
```

**Solutions:**

1. **Check if binary exists**
   ```bash
   ls -la /usr/sbin/uu/uuplugin
   ```

2. **Check if binary is executable**
   ```bash
   file /usr/sbin/uu/uuplugin
   chmod +x /usr/sbin/uu/uuplugin
   ```

3. **Check if kmod-tun is loaded**
   ```bash
   lsmod | grep tun
   # If not loaded:
   insmod tun
   ```

4. **Check configuration file**
   ```bash
   cat /usr/sbin/uu/uu.conf
   ```

5. **Check service status**
   ```bash
   /etc/init.d/uu-booster status
   ```

6. **View detailed logs**
   ```bash
   logread | grep uu-booster
   ```

7. **Try starting manually**
   ```bash
   /usr/sbin/uu/uuplugin /usr/sbin/uu/uu.conf
   ```

### Problem: Service Crashes Immediately

**Symptoms:**
Service starts but crashes within seconds.

**Solutions:**

1. **Check logs for errors**
   ```bash
   logread | grep uu-booster
   logread -f | grep uu-booster  # Watch in real-time
   ```

2. **Check for conflicts**
   ```bash
   # Check if port is already in use
   netstat -an | grep :<port>

   # Check for other VPN services
   ps aux | grep vpn
   ```

3. **Verify dependencies**
   ```bash
   # Check tun module
   lsmod | grep tun

   # Check required libraries
   ldd /usr/sbin/uu/uuplugin
   ```

4. **Check memory availability**
   ```bash
   free -h
   ```

### Problem: Service Runs But No Effect

**Symptoms:**
Service shows as running but gaming traffic not accelerated.

**Solutions:**

1. **Check if UU plugin is actually active**
   ```bash
   ps aux | grep uuplugin
   ```

2. **Check firewall rules**
   ```bash
   uci show firewall.uu
   iptables -L -n | grep uu
   ```

3. **Verify network interface**
   ```bash
   ip link show
   # Look for tun interface
   ```

4. **Check if devices are connected**
   The UU plugin only accelerates connected devices.

5. **Check UU account status**
   Ensure your UU account is active and has available quota.

---

## Update Issues

### Problem: Update Check Fails

**Symptoms:**
```
uu check
Error checking for updates: ...
```

**Solutions:**

1. **Check internet connectivity**
   ```bash
   ping -c 3 router.uu.163.com
   ```

2. **Test API manually**
   ```bash
   curl http://router.uu.163.com/api/plugin?type=openwrt-x86_64
   ```

3. **Check logs**
   ```bash
   logread | grep uu
   ```

### Problem: Update Download Fails

**Symptoms:**
```
uu update
Failed to download from primary URL
```

**Solutions:**

1. **Check network stability**
   ```bash
   ping -c 10 router.uu.163.com
   ```

2. **Check disk space**
   ```bash
   df -h /tmp
   ```

3. **Verify API response**
   ```bash
   curl http://router.uu.163.com/api/plugin?type=openwrt-x86_64
   ```

4. **Manual update**
   See [USAGE.md](USAGE.md#manual-binary-download).

### Problem: Update Succeeds But Service Won't Start

**Symptoms:**
Update completes but service fails to start.

**Solutions:**

1. **Check new binary**
   ```bash
   ls -la /usr/sbin/uu/uuplugin
   file /usr/sbin/uu/uuplugin
   ```

2. **Check configuration compatibility**
   ```bash
   cat /usr/sbin/uu/uu.conf
   ```

3. **Check logs**
   ```bash
   logread | grep uu-booster
   ```

4. **Rollback to previous version**
   If you have of previous binary, restore it.

5. **Report issue**
   [Open an Issue](https://github.com/LASER-Yi/uu-booster/issues) with version details.

---

## Network Issues

### Problem: Cannot Connect to UU Servers

**Symptoms:**
```
Failed to download from http://router.uu.163.com/...
```

**Solutions:**

1. **Check DNS resolution**
   ```bash
   nslookup router.uu.163.com
   ```

2. **Test HTTP connectivity**
   ```bash
   curl -v http://router.uu.163.com/api/plugin?type=openwrt-x86_64
   ```

3. **Check firewall rules**
   ```bash
   iptables -L OUTPUT -n -v
   ```

4. **Try alternative DNS**
   ```bash
   # Test with public DNS
   nslookup router.uu.163.com 8.8.8.8
   ```

5. **Check for proxy/VPN interference**
   Disable any proxy or VPN temporarily to test.

### Problem: Firewall Blocks UU Traffic

**Symptoms:**
Service runs but devices can't connect to UU acceleration.

**Solutions:**

1. **Check firewall rules**
   ```bash
   uci show firewall.uu
   iptables -L -n | grep uu
   ```

2. **Reload firewall**
   ```bash
   /etc/init.d/firewall reload
   ```

3. **Verify zone configuration**
   ```bash
   uci show firewall | grep -A 10 firewall.uu
   ```

4. **Check forwarding rules**
   ```bash
   uci show firewall | grep forwarding
   ```

5. **Manual firewall rules**
   See [USAGE.md](USAGE.md#manual-firewall-configuration).

### Problem: High Latency After Installation

**Symptoms:**
Network performance degrades after installing UU Booster.

**Solutions:**

1. **Check if UU service is causing issues**
   ```bash
   /etc/init.d/uu-booster stop
   # Test if performance improves
   ```

2. **Check for conflicts with other services**
   ```bash
   ps aux | grep -E "vpn|qos|sqm"
   ```

3. **Check routing table**
   ```bash
   ip route show
   ```

4. **Disable and re-enable**
   ```bash
   uu restart
   ```

---

## Performance Issues

### Problem: High CPU Usage

**Symptoms:**
`uuplugin` process uses excessive CPU.

**Solutions:**

1. **Check CPU usage**
   ```bash
   top | grep uuplugin
   ```

2. **Check number of connected devices**
   Too many devices may cause high CPU usage.

3. **Check for bugs in UU plugin**
   Report to NetEase if plugin itself has issues.

4. **Monitor over time**
   ```bash
   top -d 5 | grep uuplugin
   ```

### Problem: High Memory Usage

**Symptoms:**
`uuplugin` process uses excessive memory.

**Solutions:**

1. **Check memory usage**
   ```bash
   ps aux | grep uuplugin
   free -h
   ```

2. **Restart service**
   ```bash
   uu restart
   ```

3. **Check for memory leaks**
   Monitor over time. If memory grows continuously, report issue.

---

## Debugging

### Viewing Logs

**All UU Booster logs:**
```bash
logread | grep uu
```

**Real-time logs:**
```bash
logread -f | grep uu
```

**Service-specific logs:**
```bash
logread | grep uu-booster
```

**Save logs to file:**
```bash
logread | grep uu > /tmp/uu-logs.txt
```

### Checking Service Status

**Service status:**
```bash
/etc/init.d/uu-booster status
```

**Detailed procd status:**
```bash
procd status uu-booster
```

**Process information:**
```bash
ps aux | grep uuplugin
```

### Testing Binary Manually

**Test binary directly:**
```bash
/usr/sbin/uu/uuplugin /usr/sbin/uu/uu.conf
```

**Check for errors:**
```bash
/usr/sbin/uu/uuplugin /usr/sbin/uu/uu.conf 2>&1 | tee /tmp/test.log
```

### Verifying Installation

**Check all components:**
```bash
echo "=== Binary ==="
ls -la /usr/sbin/uu/uuplugin

echo "=== Config ==="
ls -la /usr/sbin/uu/uu.conf

echo "=== Init Script ==="
ls -la /etc/init.d/uu-booster

echo "=== UUID ==="
ls -la /usr/sbin/uu/.uuplugin_uuid
```

---

## Common Solutions

### Quick Fixes for Common Problems

**Fix 1: Restart Everything**
```bash
uu restart
/etc/init.d/firewall reload
```

**Fix 2: Reinstall Package**
```bash
opkg remove uu-booster
opkg install uu-booster_*.ipk
```

**Fix 3: Update Binary**
```bash
uu update
```

**Fix 4: Clear and Restart**
```bash
/etc/init.d/uu-booster stop
rm -rf /usr/sbin/uu/*
uu update
/etc/init.d/uu-booster start
```

### Reset to Factory State

If all else fails, reset to initial state:

```bash
# Stop service
/etc/init.d/uu-booster stop

# Remove package
opkg remove uu-booster

# Clean up remaining files
rm -rf /usr/sbin/uu
rm -rf /etc/uu

# Remove firewall rules
uci delete firewall.uu
uci delete firewall.lan_to_uu
uci delete firewall.uu_to_lan
uci commit firewall
/etc/init.d/firewall reload

# Reinstall
opkg install uu-booster_*.ipk
```

---

## Getting Additional Help

### When to Open an Issue

Open a GitHub Issue when:
- Solutions in this guide don't work
- You encounter unexpected behavior
- You're using an untested OpenWRT version
- You find bugs or errors

### Information to Include

When opening an issue, provide:

1. **OpenWRT Version**
   ```bash
   cat /etc/openwrt_release
   ```

2. **Router Model and Architecture**
   ```bash
   cat /proc/cpuinfo | grep "model name"
   cat /etc/openwrt_release | grep DISTRIB_ARCH
   ```

3. **UU Booster Version**
   ```bash
   uu status
   ```

4. **Error Messages**
   ```bash
   logread | grep uu-booster > /tmp/uu-error.log
   cat /tmp/uu-error.log
   ```

5. **Steps to Reproduce**
   Describe exactly what you did and what happened.

6. **Screenshots**
   If relevant, include screenshots of error messages or configuration.

### Issue Template

```markdown
## Description
[Brief description of issue]

## Environment
- OpenWRT Version: [output of `cat /etc/openwrt_release`]
- Router Model: [your router model]
- Architecture: [output of `cat /etc/openwrt_release | grep DISTRIB_ARCH`]
- UU Booster Version: [output of `uu status`]

## Steps to Reproduce
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior
[What you expected to happen]

## Actual Behavior
[What actually happened]

## Error Messages
```
[Paste error logs here]
```

## Additional Information
[Any other relevant information]
```

### Contact

- **GitHub Issues**: https://github.com/LASER-Yi/uu-booster/issues

---

## FAQ

### Q: Does this work with OpenWRT 22.03 or earlier?

A: This project has only been tested on OpenWRT 24.10.1. Earlier versions may work but haven't been tested. Please open an issue if you test on other versions.

### Q: Can I use this with any router?

A: The package supports aarch64, arm, mipsel, and x86_64 architectures. Check if your router is supported by running `cat /etc/openwrt_release | grep DISTRIB_ARCH`.

### Q: Do I need a UU account?

A: Yes, you need an active UU Game Booster account. This package only manages plugin installation and updates.

### Q: Will this affect my other network services?

A: UU Booster creates its own network namespace and shouldn't interfere with other services. However, if you experience issues, try disabling the service temporarily.

### Q: How do I know if it's working?

A: Check `uu status` to see if the service is running. You should also see reduced latency and improved stability in supported games through the UU app.

### Q: Can I run multiple instances?

A: No, only one instance of UU Booster should run at a time on a router.

### Q: What happens if I uninstall?

A: The service stops, binary is removed, and firewall rules are cleaned up. Your device UUID is preserved in `/etc/uu/.uuplugin_uuid` for future reinstalls.
