--照明电路

local lightSpdMult = GetModConfigData("light_spd")

TUNING.WX78_LIGHT_RADIUS_PER_MODULE = GetModConfigData("light_radius") or TUNING.WX78_LIGHT_RADIUS_PER_MODULE

--从原版复制而来
local LIGHT_R, LIGHT_G, LIGHT_B = 235 / 255, 121 / 255, 12 / 255
local function light_change(inst, wx, light_rad)
    wx._lightmodule_radius = (wx._lightmodule_radius or 0) + light_rad
    if wx._lightmodule_radius < 0.001 then -- Floating point precision epsilon with all of these adds and subtracts of floats.
        wx._lightmodule_radius = 0
    end
    if wx.Light then
        if wx._lightmodule_radius == 0 then
            -- Reset properties to the electrocute light properties, since that's the player_common default.
            wx.Light:SetRadius(0.5)
            wx.Light:SetIntensity(0.8)
            wx.Light:SetFalloff(0.65)
            wx.Light:SetColour(255 / 255, 255 / 255, 236 / 255)

            wx.Light:Enable(false)
        else
            wx.Light:SetRadius(math.pow(wx._lightmodule_radius, 0.8))
            -- If we had 0 before, set up the light properties.
            if wx._lightmodule_radius > 0 then
                wx.Light:SetIntensity(0.90)
                wx.Light:SetFalloff(0.50)
                wx.Light:SetColour(LIGHT_R, LIGHT_G, LIGHT_B)

                wx.Light:Enable(true)
            end
        end
    end
end

--照明电路激活
local function light_activate(modu, wx)
	wx.WMB_lightnum = (wx.WMB_lightnum or 0) + 1

	light_change(inst, wx, TUNING.WX78_LIGHT_RADIUS_PER_MODULE)

	--移速加成
    if wx.components.locomotor then
        wx.components.locomotor:SetExternalSpeedMultiplier(wx, "WMB_lightspdmult", lightSpdMult)
    end
end

--照明电路关闭
local function light_deactivate(modu, wx)
	wx.WMB_lightnum = math.max(0, (wx.WMB_lightnum or 0) - 1)

	light_change(inst, wx, -TUNING.WX78_LIGHT_RADIUS_PER_MODULE)

	--取消移速加成
	if wx.WMB_lightnum <= 0 then
		if wx.components.locomotor then
			wx.components.locomotor:SetExternalSpeedMultiplier(wx, "WMB_lightspdmult", 1)
		end
	end
end

--照明电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "light" then
		modu.activatefn = light_activate
		modu.deactivatefn = light_deactivate
	end
end

-- AddPrefabPostInit("wx78module_light", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- light_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- light_deactivate(modu, wx)
		-- end
    -- end
-- end)

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_light", function(modu)
    if TheWorld.ismastersim  then
	
		local oldfn = modu.ListenForEvent
		function modu:ListenForEvent(event, ...)
			if event == "onactivateskill_server" or event == "ondeactivateskill_server" or event == "leaderchanged" then
				return
			end
			return oldfn(self, event, ...)
		end	
		
		local oldfn = modu.RemoveEventCallback
		function modu:RemoveEventCallback(event, ...)
			if event == "onactivateskill_server" or event == "ondeactivateskill_server" or event == "leaderchanged" then
				return
			end
			return oldfn(self, event, ...)		
		end
		
    end
end)