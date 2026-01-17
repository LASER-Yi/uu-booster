local http = require "luci.http"
local sys = require "luci.sys"

m = Map("uu-booster", translate("UU Game Booster"))

s = m:section(NamedSection, "main", "main", translate("Version Information"))
s.addremove = false
s.anonymous = true

current_version = ""
if nixio.fs.access("/etc/uu-booster.conf") then
	local f = io.popen("cat /etc/uu-booster.conf")
	local content = f:read("*a")
	f:close()
	current_version = content:match("version=([%d%.]+)") or "Unknown"
end

current = s:option(DummyValue, "current_version", translate("Current Version"))
current.rawhtml = true
current.template = "uu-booster/current_version"

latest = s:option(DummyValue, "latest_version", translate("Latest Version"))
latest.rawhtml = true
latest.template = "uu-booster/latest_version"

service_status = s:option(DummyValue, "service_status", translate("Service Status"))
service_status.rawhtml = true
service_status.template = "uu-booster/service_status"

return m
