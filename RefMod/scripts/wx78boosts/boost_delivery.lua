--运输机

TUNING.SKILLS.WX78.DELIVERYDRONE_SPEED = (GetModConfigData("delivery_spd") or 1) * TUNING.SKILLS.WX78.DELIVERYDRONE_SPEED

--微光
if GetModConfigData("delivery_glow") then

	--照明电路的颜色
	local LIGHT_R, LIGHT_G, LIGHT_B = 235 / 255, 121 / 255, 12 / 255

	local function Glow(inst)
		if not inst.Light then		
			inst.entity:AddLight()
			inst.Light:SetRadius(0.78)
			inst.Light:SetIntensity(0.90)
			inst.Light:SetFalloff(0.50)
			inst.Light:SetColour(LIGHT_R, LIGHT_G, LIGHT_B)
			inst.Light:Enable(true)
		end
		--if not TheWorld.ismastersim then return inst end
	end
	AddPrefabPostInit("wx78_drone_delivery", Glow)
	AddPrefabPostInit("wx78_drone_delivery_small", Glow)

end

