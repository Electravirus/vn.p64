--[[pod_format="raw",created="2024-05-24 14:30:37",modified="2025-02-14 15:27:11",revision=1159]]
window{width=450;height=200}

include "vn.lua"
include "script.lua"

function _update()
	vn:update_all()
end

function _draw()
	cls()
	vn:draw_all()
	
end