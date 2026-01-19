import { readfile, exec, call } from 'fs';

let get_arch = () => {
	let content = readfile('/etc/openwrt_release');
	let arch = content ? content.match("DISTRIB_ARCH='([^']+)'") : null;
	
	if (arch && arch.match('^aarch64'))
		return 'aarch64';
	if (arch && arch.match('^arm'))
		return 'arm';
	if (arch && arch.match('^mips'))
		return 'mipsel';
	if (arch === 'x86_64')
		return 'x86_64';
	
	return arch || '';
};

let get_current_version = () => {
	let content = readfile('/usr/sbin/uu/uu.conf');
	return content ? content.match('version=([\\d\\.]+)') : null;
};

let get_service_status = () => {
	return exec('/etc/init.d/uu-booster status 2>&1');
};

return {
	status: () => {
		return {
			current_version: get_current_version() || 'Unknown',
			service_status: get_service_status() || 'Not running'
		};
	},
	
	check_version: () => {
		let arch = get_arch();
		let api_response = exec('curl -s "http://router.uu.163.com/api/plugin?type=openwrt-' + arch);
		
		if (!api_response)
			return { success: false, error: 'Failed to get API response' };
		
		let download_url = api_response.match('"url":"([^"]+)"');
		if (!download_url)
			return { success: false, error: 'Failed to extract download URL' };
		
		let version = download_url.match('/v([\\d\\.]+)/');
		return { success: true, latest_version: version };
	},
	
	update: () => {
		let update_result = call('/usr/bin/uu update >/dev/null 2>&1');
		
		let messages = {
			0: 'Update completed successfully',
			1: 'Invalid architecture detected by uu-update script',
			2: 'No response from UU API',
			3: 'Failed to extract download URL from API response',
			4: 'Primary download failed or checksum mismatch',
			5: 'Backup URL failed or checksum mismatch',
			6: 'Failed to download from both primary and backup URLs',
			7: 'Failed to extract archive',
			8: 'uu.conf not found in downloaded archive',
			9: 'uuplugin not found in downloaded archive',
			10: 'Failed to copy files to /usr/sbin/uu',
			11: 'Failed to install uu.conf',
			12: 'Failed to install uuplugin',
			13: 'Failed to start uu-booster service'
		};
		
		let message = messages[update_result] || 'Update failed with unknown error (' + update_result + ')';
		
		return { success: update_result === 0, message };
	}
};
