module("luci.controller.uu-booster", package.seeall)

function index()
	entry({"admin", "services", "uu-booster"}, cbi("uu-booster"), _("UU Booster"), 30).dependent = false
	entry({"admin", "services", "uu-booster", "check_version"}, call("action_check_version")).leaf = true
	entry({"admin", "services", "uu-booster", "uu-update"}, call("action_update")).leaf = true
	entry({"admin", "services", "uu-booster", "status"}, call("action_status")).leaf = true
 end

function action_check_version()
	local arch = luci.sys.exec("grep '^DISTRIB_ARCH' /etc/openwrt_release | awk -F \"'\" '{print $2}'")
	
	local uu_arch = arch
	
	if uu_arch:match("^aarch64") then
		uu_arch = "aarch64"
	elseif uu_arch:match("^arm") then
		uu_arch = "arm"
	elseif uu_arch:match("^mips") then
		uu_arch = "mipsel"
	elseif uu_arch == "x86_64" then
		uu_arch = "x86_64"
	end
	
	local api_response = luci.sys.exec("curl -s 'http://router.uu.163.com/api/plugin?type=openwrt-" .. uu_arch .. "'")
	
	luci.http.prepare_content("application/json")
	
	if api_response == "" then
		luci.http.write_json({
			success = false,
			error = "Failed to get API response"
		})
		return
	end
	
	local download_url = api_response:match("\"url\":\"([^\"]+)\"")
	
	if not download_url or download_url == "" then
		luci.http.write_json({
			success = false,
			error = "Failed to extract download URL from API response"
		})
		return
	end
	
	local version = download_url:match("/v([%d%.]+)/")
	
	if version then
		luci.http.write_json({
			success = true,
			latest_version = version
		})
	else
		luci.http.write_json({
			success = false,
			error = "Failed to parse version from URL"
		})
	end
end

function action_update()
	local arch = luci.sys.exec("grep '^DISTRIB_ARCH' /etc/openwrt_release | awk -F \"'\" '{print $2}'")
	
	local uu_arch = arch
	
	if uu_arch:match("^aarch64") then
		uu_arch = "aarch64"
	elseif uu_arch:match("^arm") then
		uu_arch = "arm"
	elseif uu_arch:match("^mips") then
		uu_arch = "mipsel"
	elseif uu_arch == "x86_64" then
		uu_arch = "x86_64"
	end
	
	luci.http.prepare_content("application/json")
	
	local result = {
		success = false,
		message = ""
	}
	
	local api_response = luci.sys.exec("curl -s 'http://router.uu.163.com/api/plugin?type=openwrt-" .. uu_arch .. "'")
	
	if api_response == "" then
		result.success = false
		result.message = "Failed to get API response"
		luci.http.write_json(result)
		return
	end
	
	local update_output = luci.sys.exec("/usr/bin/uu-update update 2>&1")
	local update_result = luci.sys.call("/usr/bin/uu-update update >/dev/null 2>&1")
	
	if update_result == 0 then
		result.success = true
		result.message = "Update completed successfully"
	elseif update_result == 1 then
		result.success = false
		result.message = "Invalid architecture detected by uu-update script"
	elseif update_result == 2 then
		result.success = false
		result.message = "No response from UU API"
	elseif update_result == 3 then
		result.success = false
		result.message = "Failed to extract download URL from API response"
	elseif update_result == 4 then
		result.success = false
		result.message = "Primary download failed or checksum mismatch"
	elseif update_result == 5 then
		result.success = false
		result.message = "Backup URL failed or checksum mismatch"
	elseif update_result == 6 then
		result.success = false
		result.message = "Failed to download from both primary and backup URLs"
	elseif update_result == 7 then
		result.success = false
		result.message = "Failed to extract archive"
	elseif update_result == 8 then
		result.success = false
		result.message = "uu.conf not found in downloaded archive"
	elseif update_result == 9 then
		result.success = false
		result.message = "uuplugin not found in downloaded archive"
	elseif update_result == 10 then
		result.success = false
		result.message = "Failed to copy files to /usr/sbin/uu"
	elseif update_result == 11 then
		result.success = false
		result.message = "Failed to install uu.conf"
	elseif update_result == 12 then
		result.success = false
		result.message = "Failed to install uuplugin"
	elseif update_result == 13 then
		result.success = false
		result.message = "Failed to start uu-booster service"
	else
		result.success = false
		result.message = "Update failed with unknown error (" .. update_result .. ")"
	end
	
	luci.http.write_json(result)
 end

function action_status()
	local current_version = ""
	
	if luci.fs.access("/etc/uu-booster.conf") then
		local conf_content = luci.fs.readfile("/etc/uu-booster.conf")
		current_version = conf_content:match("version=([%d%.]+)")
	end
	
	local service_status = luci.sys.exec("/etc/init.d/uu-booster status 2>&1")
	
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		current_version = current_version or "Unknown",
		service_status = service_status or "Not running"
	})
 end
