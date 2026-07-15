--合唱盒电路

local musicSpdMult = GetModConfigData("music_spd")
local musicBeatCombo = GetModConfigData("music_beatcombo")
local musicWet = GetModConfigData("music_wet")
local musicSanityAuraTable = {0, 100/2700, 100/1350, 100/900, 117/900, 100/600, 100/300}
local musicMusic = GetModConfigData("music_music")
local musicVolume = GetModConfigData("music_volume")
local music_no_follower = GetModConfigData("music_no_follower")
local music_farm = GetModConfigData("music_farm")

--精神光环修改
local musicSanityAura = musicSanityAuraTable[GetModConfigData("music_sanityaura")] or 100/900
TUNING.WX78_MUSIC_SANITYAURA = musicSanityAura
TUNING.WX78_MUSIC_DAPPERNESS = musicSanityAura

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

local heat_activate, heat_deactivate = function()end, function()end
local cold_activate, cold_deactivate = function()end, function()end
local music_heat_cold = GetModConfigData("music_heat_cold")

--冷热协调
if music_heat_cold then
	for _,modu in pairs(module_definitions) do
		if modu.name == "heat" then
			heat_activate = modu.activatefn
			heat_deactivate = modu.deactivatefn
		end

		if modu.name == "cold" then
			cold_activate = modu.activatefn
			cold_deactivate = modu.deactivatefn
		end	
	end
end

--合唱盒电路潮湿目标
local function music_onhitother(wx, data)
	if data and data.target and not data.redirected and not data.target:HasOneOfTags({"moistureimmunity", "wet"}) and not data.target:GetIsWet() then
		local target = data.target
		local did = false

		if target.components.moisture ~= nil then
			if target ~= wx then			
				local waterproofness = target.components.moisture:GetWaterproofness()
				target.components.moisture:DoDelta(10 * (1 - waterproofness))
				did = true
			end
		end
		if target.components.inventoryitem ~= nil then
			target.components.inventoryitem:AddMoisture(10)
			did = true
		end
		
		--硬核潮湿
		if not did or not target.components.moisture then
			target:AddTag("wet")
			target:DoTaskInTime(6, function(inst)
				if not (TheWorld.state.iswet and not inst:HasTag("rainimmunity")) or not (inst:HasTag("swimming") and not inst:HasTag("likewateroffducksback")) then
					target:RemoveTag("wet")
				end
			end)
		end
		
		--水花特效
		local fx = SpawnPrefab("waterballoon_splash")
		fx.Transform:SetScale(0.5, 0.5, 0.5)
		fx.Transform:SetPosition(target.Transform:GetWorldPosition())
	end	
end

--自动取消后摇
local function music_onattackother(wx, data)
	if data and data.target and not data.redirected then
		--排除旋风斩
		if wx.sg and not wx.sg:HasStateTag("spinning") then
			wx.sg:RemoveStateTag("attack")
			wx.sg:RemoveStateTag("abouttoattack")
			
			--摇摆转向(无意义动作)
			local x1,y1,z1 = wx.Transform:GetWorldPosition()
			local x2,y2,z2 = data.target.Transform:GetWorldPosition()
			wx:ForceFacePoint(2*x1-x2, 2*y1-y2, 2*z1-z2)
		end
	end		
end


--更新温度上下限
local MIN_TEMP = TUNING.MIN_ENTITY_TEMP
local MAX_TEMP = TUNING.MAX_ENTITY_TEMP
local function update_temperature_temps(wx)
	local num = wx.WMB_musicnum or 0
	if num > 1 then num = 1 end

    if wx.components.temperature then
		local tempchange = num * TUNING.WX78_MINTEMPCHANGEPERMODULE
        wx.components.temperature.mintemp = math.clamp(MIN_TEMP + tempchange, MIN_TEMP, MAX_TEMP)
        wx.components.temperature.maxtemp = math.clamp(MAX_TEMP - tempchange, MIN_TEMP, MAX_TEMP)
    end
end

local function music_farm_tick(wx, modu)
	local x,y,z = wx.Transform:GetWorldPosition()
	local showFX = false
	
	--利用动画状态判断耕地是否需要浇水
	local water_farm = false
	for _,ent in ipairs(TheSim:FindEntities(x, 0, z, 6, { "DECOR", "NOCLICK" })) do
		if ent.prefab == "nutrients_overlay" and ent.AnimState then
			if ent.AnimState:GetCurrentAnimationTime() < 0.78 then
				water_farm = true
				break
			end
		end
	end	
	
	--为耕地浇水
	if water_farm then
		local _x, _z
		for k1 = -3, 3, 3 do
			_x = x + k1
			for k2 = -3, 3, 3 do
				_z = z + k2
				if TheWorld.components.farming_manager and TheWorld.Map:IsFarmableSoilAtPoint(_x, 0, _z) then
					TheWorld.components.farming_manager:AddSoilMoistureAtPoint(_x, 0, _z, 33)
					showFX = true
				end 
			end
		end	
	end
	
	--为作物浇水
	local plant_found = false
	for _,ent in ipairs(TheSim:FindEntities(x, 0, z, 3, {"witherable"}, { "DECOR", "INLIMBO" })) do
		if ent.components.witherable ~= nil and ent.components.witherable:IsWithered() then
			ent.components.witherable:Protect(78)
			plant_found = true
			showFX = true
		end
	end
	
	--灭火
	if plant_found then
		local fires = TheSim:FindEntities(x, y, z, 3, nil,  {"INLIMBO", "lighter"}, {"fire", "smolder"})
		for _,fire in pairs(fires) do
			if fire.components.burnable and (fire.components.burnable:IsBurning() or fire.components.burnable:IsSmoldering()) then			
				fire.components.burnable:Extinguish(true, 0)
				showFX = true
			end
		end		
	end
	
	--水花特效
	if showFX then	
		local fx = SpawnPrefab("waterballoon_splash")
		fx.Transform:SetPosition(wx.Transform:GetWorldPosition())
	end
end

--合唱盒电路激活
local function music_activate(modu, wx, ...)
	wx.WMB_musicnum = (wx.WMB_musicnum or 0) + 1

    if modu.WMB_onhitother == nil then
        modu.WMB_onhitother = music_onhitother
    end

    if modu.WMB_music_onattackother == nil then
        modu.WMB_music_onattackother = music_onattackother
    end	

	if musicWet and wx.WMB_musicnum == 1 then
		modu:ListenForEvent("onhitother", modu.WMB_onhitother, wx)

		if musicBeatCombo == 1 then
			modu:ListenForEvent("onattackother", modu.WMB_music_onattackother, wx)
		end
	end

	if music_farm and wx.WMB_musicnum == 1 then
		if wx.WMB_music_farm_task ~= nil then wx.WMB_music_farm_task:Cancel() end
		wx.WMB_music_farm_task = wx:DoPeriodicTask(5, music_farm_tick, nil, modu)
	end

	--移速加成
    if wx.components.locomotor then
        wx.components.locomotor:SetExternalSpeedMultiplier(wx, "WMB_musicspeedmult", musicSpdMult)
    end
	
	--战斗加成
	if wx.components.combat then
		if musicBeatCombo == 2 then
			wx.components.combat.externaldamagemultipliers:SetModifier("WMB_musicdmgmult", 1.25)
		end
	end
	
	--音乐更换
	if musicMusic == 1 then
		wx.SoundEmitter:SetVolume("music_sound", musicVolume)
	else
		wx.SoundEmitter:KillSound("music_sound")
	end
	if musicMusic == 2 then
		wx.SoundEmitter:PlaySound("wmbmusic/undertale/mttex", "wmb_music")
		wx.SoundEmitter:SetVolume("wmb_music", musicVolume)
	end
	
	--关闭招募(把招募上限改为0)
	if music_no_follower and wx.components.leaderrollcall then
		wx.components.leaderrollcall:SetMaxFollowers(0)
	end
	
	--冷热协调
	if music_heat_cold then	
		heat_activate(modu, wx, ...)
		cold_activate(modu, wx, ...)
		update_temperature_temps(wx)
	end
end

--合唱盒电路关闭
local function music_deactivate(modu, wx, ...)
	wx.WMB_musicnum = math.max(0, (wx.WMB_musicnum or 0) - 1)

	modu:RemoveEventCallback("onhitother", modu.WMB_onhitother, wx)
	modu:RemoveEventCallback("onattackother", modu.WMB_music_onattackother, wx)

	--取消移速加成和战斗加成
	if wx.WMB_musicnum <= 0 then
		if wx.components.locomotor then
			wx.components.locomotor:SetExternalSpeedMultiplier(wx, "WMB_musicspeedmult", 1)
		end	
		if wx.components.combat then
			wx.components.combat.externaldamagemultipliers:SetModifier("WMB_musicdmgmult", 1)
		end		
		wx.SoundEmitter:KillSound("wmb_music")
		
		if wx.WMB_music_farm_task ~= nil then
			wx.WMB_music_farm_task:Cancel()
			wx.WMB_music_farm_task = nil
		end		
		
		--关闭招募(把招募上限改为0)
		if music_no_follower and wx.components.leaderrollcall then
			wx:RemoveComponent("leaderrollcall")
		end	
	end
	
	--音乐更换
	if musicMusic ~= 1 then
		wx.SoundEmitter:KillSound("music_sound")
	end	
	
	--冷热协调
	if music_heat_cold then	
		heat_deactivate(modu, wx, ...)
		cold_deactivate(modu, wx, ...)
		update_temperature_temps(wx)
	end	
end


--合唱盒电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "music" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			music_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			music_deactivate(modu, wx)
		end
	end
end

-- AddPrefabPostInit("wx78module_music", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- music_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- music_deactivate(modu, wx)
		-- end
    -- end
-- end)

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_music", function(modu)
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
