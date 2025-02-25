--[[pod_format="raw",created="2024-05-24 14:30:37",modified="2025-02-25 23:01:25",revision=1610]]
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