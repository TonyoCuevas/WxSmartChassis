--强化电路


local health_absorb = GetModConfigData("health_absorb")
local health_antistiff = GetModConfigData("health_antistiff")

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_health1_tag = net_bool(inst.GUID, "WMB_health1_tag", "WMB_health1_tag.dirty")
	inst.WMB_health1_tag:set(false)
	
	inst.WMB_health2_tag = net_bool(inst.GUID, "WMB_health2_tag", "WMB_health2_tag.dirty")
	inst.WMB_health2_tag:set(false)
end)
AddPrefabPostInit("wx78_classified", function(inst)
	inst.WMB_health1_tag = net_bool(inst.GUID, "WMB_health1_tag", "WMB_health1_tag.dirty")
	inst.WMB_health1_tag:set(false)
	
	inst.WMB_health2_tag = net_bool(inst.GUID, "WMB_health2_tag", "WMB_health2_tag.dirty")
	inst.WMB_health2_tag:set(false)
end)

local function AddHealth1Tag(wx)
	if wx.player_classified and wx.player_classified.WMB_health1_tag then
		wx.player_classified.WMB_health1_tag:set(true)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_health1_tag then
		wx.wx78_classified.WMB_health1_tag:set(true)
	end
end
local function RemoveHealth1Tag(wx)
	if wx.player_classified and wx.player_classified.WMB_health1_tag then
		wx.player_classified.WMB_health1_tag:set(false)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_health1_tag then
		wx.wx78_classified.WMB_health1_tag:set(false)
	end
end
local function HasHelath1Tag(wx)
	if wx.player_classified and wx.player_classified.WMB_health1_tag then
		if wx.player_classified.WMB_health1_tag:value() then
			return true
		end
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_health1_tag then
		if wx.wx78_classified.WMB_health1_tag:value() then
			return true
		end
	end
	return false
end

local function AddHealth2Tag(wx)
	if wx.player_classified and wx.player_classified.WMB_health2_tag then
		wx.player_classified.WMB_health2_tag:set(true)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_health2_tag then
		wx.wx78_classified.WMB_health2_tag:set(true)
	end
end
local function RemoveHealth2Tag(wx)
	if wx.player_classified and wx.player_classified.WMB_health2_tag then
		wx.player_classified.WMB_health2_tag:set(false)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_health2_tag then
		wx.wx78_classified.WMB_health2_tag:set(false)
	end
end
local function HasHelath2Tag(wx)
	if wx.player_classified and wx.player_classified.WMB_health2_tag then
		if wx.player_classified.WMB_health2_tag:value() then
			return true
		end
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_health2_tag then
		if wx.wx78_classified.WMB_health2_tag:value() then
			return true
		end
	end
	return false
end


--强化电路激活
local function health1_activate(modu, wx, isloading)
	wx.WMB_health1num = (wx.WMB_health1num or 0) + 1
	
	if health_antistiff then	
		AddHealth1Tag(wx)
	end

	--减伤
    if wx.components.health then
        wx.components.health.externalabsorbmodifiers:SetModifier("WMB_health1absorb", health_absorb)
    end
	
	--移除技能树减伤
	if wx.components.combat then
		wx.components.combat.externaldamagetakenmultipliers:RemoveModifier(wx, "maxhealthmoduleskill")
	end
end
local function health_activate(modu, wx, isloading)
	wx.WMB_healthnum = (wx.WMB_healthnum or 0) + 1

	if health_antistiff then	
		AddHealth2Tag(wx)
	end

	--减伤
    if wx.components.health then
        wx.components.health.externalabsorbmodifiers:SetModifier("WMB_healthabsorb", health_absorb*2)
    end
	
	--移除技能树减伤
	if wx.components.combat then
		wx.components.combat.externaldamagetakenmultipliers:RemoveModifier(wx, "maxhealthmoduleskill")
	end	
end

--强化电路关闭
local function health1_deactivate(modu, wx)
	wx.WMB_health1num = math.max(0, (wx.WMB_health1num or 0) - 1)

	--取消减伤
	if wx.WMB_health1num <= 0 then
		if wx.components.health then
			wx.components.health.externalabsorbmodifiers:SetModifier("WMB_health1absorb", 0)
		end
		RemoveHealth1Tag(wx)
	end
	
	--移除技能树减伤
	if wx.components.combat then
		wx.components.combat.externaldamagetakenmultipliers:RemoveModifier(wx, "maxhealthmoduleskill")
	end		
end
local function health_deactivate(modu, wx)
	wx.WMB_healthnum = math.max(0, (wx.WMB_healthnum or 0) - 1)

	--取消减伤
	if wx.WMB_healthnum <= 0 then
		if wx.components.health then
			wx.components.health.externalabsorbmodifiers:SetModifier("WMB_healthabsorb", 0)
		end
		RemoveHealth2Tag(wx)
	end
	
	--移除技能树减伤
	if wx.components.combat then
		wx.components.combat.externaldamagetakenmultipliers:RemoveModifier(wx, "maxhealthmoduleskill")
	end		
end


--强化电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "maxhealth" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			health1_activate(modu, wx, isloading)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			health1_deactivate(modu, wx)
		end
	end
	if modu.name == "maxhealth2" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			health_activate(modu, wx, isloading)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			health_deactivate(modu, wx)
		end
	end
end

-- AddPrefabPostInit("wx78module_maxhealth", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- health1_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- health1_deactivate(modu, wx)
		-- end
    -- end
-- end)
-- AddPrefabPostInit("wx78module_maxhealth2", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- health_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- health_deactivate(modu, wx)
		-- end
    -- end
-- end)

--检测强化电路
local function GetHealthLevel(wx)
	if HasHelath2Tag(wx) then
		return 2
	end	
	
	if HasHelath1Tag(wx) then
		return 1
	end

	return 0
end

--受击硬直抗性
local function CheckHealthModu(sg)
	if sg.events and sg.events.attacked then
		local oldfn = sg.events.attacked.fn
		sg.events.attacked.fn = function(inst, ...)
			if GetHealthLevel(inst) > 0 or inst:HasTag("playerghost") then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
	end
	
	--防滑倒
	if sg.events and sg.events.feetslipped then
		local oldfn = sg.events.feetslipped.fn
		sg.events.feetslipped.fn = function(inst, ...)
			if GetHealthLevel(inst) > 0 or inst:HasTag("playerghost") then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
	end	
	
	--超级版防击飞(忽略大蠕虫和恶液的解控)
    if sg.events and sg.events.knockback then
		local oldfn = sg.events.knockback.fn
		sg.events.knockback.fn = function(inst, ...)
			if not (inst.sg:HasStateTag("devoured") or inst.sg:HasStateTag("suspended")) and (GetHealthLevel(inst) > 1 or inst:HasTag("playerghost")) then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
    end	
	
	--超级版防恶液黏住
    if sg.states and sg.states.suspended then
		local oldfn = sg.states.suspended.onenter
		sg.states.suspended.onenter = function(inst, ...)
			if GetHealthLevel(inst) > 1 or inst:HasTag("playerghost") then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
    end	
	
end

AddStategraphPostInit("wilson", CheckHealthModu)
AddStategraphPostInit("wilson_client", CheckHealthModu)
AddStategraphPostInit("wx78_possessedbody", CheckHealthModu) --附身底盘兼容
AddStategraphPostInit("wx", CheckHealthModu) --WX自动化兼容


--防滑倒
AddComponentPostInit("slipperyfeet", function(SlipperyFeet)
	local oldfn = SlipperyFeet.OnUpdate
	function SlipperyFeet:OnUpdate(...)
		local inst = self.inst
		if GetHealthLevel(inst) > 0 then
			self.slippiness = 0
			return
		elseif oldfn then
			return oldfn(self, ...)
		end
	end
end)

--超级版防钢羊等黏住
AddComponentPostInit("pinnable", function(Pinnable)
	local oldfn = Pinnable.Stick
	function Pinnable:Stick(...)
		if GetHealthLevel(self.inst) > 1 or self.inst:HasTag("playerghost") then
			return
		end
		return oldfn(self, ...)
	end
end)

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_maxhealth", function(modu)
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
AddPrefabPostInit("wx78module_maxhealth2", function(modu)
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