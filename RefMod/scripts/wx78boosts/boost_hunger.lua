--胃增益电路

local hunger_strongstomach = GetModConfigData("hunger_strongstomach")
local hunger_fastcharge = GetModConfigData("hunger_fastcharge")
local hunger_fastchargecost = GetModConfigData("hunger_fastchargecost") or 10

local bee_3in1 = GetModConfigData("bee_3in1")

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_hunger1_tag = net_bool(inst.GUID, "WMB_hunger1_tag", "WMB_hunger1_tag.dirty")
	inst.WMB_hunger1_tag:set(false)
	
	inst.WMB_hunger2_tag = net_bool(inst.GUID, "WMB_hunger2_tag", "WMB_hunger2_tag.dirty")
	inst.WMB_hunger2_tag:set(false)
end)
AddPrefabPostInit("wx78_classified", function(inst)
	inst.WMB_hunger1_tag = net_bool(inst.GUID, "WMB_hunger1_tag", "WMB_hunger1_tag.dirty")
	inst.WMB_hunger1_tag:set(false)
	
	inst.WMB_hunger2_tag = net_bool(inst.GUID, "WMB_hunger2_tag", "WMB_hunger2_tag.dirty")
	inst.WMB_hunger2_tag:set(false)
end)

local function SetHunger1(wx, bool)
	if wx.player_classified and wx.player_classified.WMB_hunger1_tag then
		wx.player_classified.WMB_hunger1_tag:set(bool)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_hunger1_tag then
		wx.wx78_classified.WMB_hunger1_tag:set(bool)
	end
end
local function HasHunger1(wx)
	if wx.player_classified and wx.player_classified.WMB_hunger1_tag then
		if wx.player_classified.WMB_hunger1_tag:value() then
			return true
		end
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_hunger1_tag then
		if wx.wx78_classified.WMB_hunger1_tag:value() then
			return true
		end
	end
	return false
end

local function SetHunger2(wx, bool)
	if wx.player_classified and wx.player_classified.WMB_hunger2_tag then
		wx.player_classified.WMB_hunger2_tag:set(bool)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_hunger2_tag then
		wx.wx78_classified.WMB_hunger2_tag:set(bool)
	end
end
local function HasHunger2(wx)
	if wx.player_classified and wx.player_classified.WMB_hunger2_tag then
		if wx.player_classified.WMB_hunger2_tag:value() then
			return true
		end
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_hunger2_tag then
		if wx.wx78_classified.WMB_hunger2_tag:value() then
			return true
		end
	end
	return false
end

local function GetHungerLevel(wx)
	if HasHunger2(wx) then
		return 2
	end
	
	if HasHunger1(wx) then
		return 1
	end
	
	return 0
end

--胃增益电路激活
local function hunger1_activate(modu, wx)
	wx.WMB_hunger1num = (wx.WMB_hunger1num or 0) + 1
	
	SetHunger1(wx, true)
end
local function hunger_activate(modu, wx)
	wx.WMB_hungernum = (wx.WMB_hungernum or 0) + 1
	
	SetHunger2(wx, true)
end

--胃增益电路关闭
local function hunger1_deactivate(modu, wx)
	wx.WMB_hunger1num = math.max(0, (wx.WMB_hunger1num or 0) - 1)
	
	if wx.WMB_hunger1num <= 0 then
		SetHunger1(wx, false)
	end
end
local function hunger_deactivate(modu, wx)
	wx.WMB_hungernum = math.max(0, (wx.WMB_hungernum or 0) - 1)
	
	if wx.WMB_hungernum <= 0 then
		SetHunger2(wx, false)
	end	
end


--胃增益电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "maxhunger1" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			hunger1_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			hunger1_deactivate(modu, wx)
		end
	end
	if modu.name == "maxhunger" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			hunger_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			hunger_deactivate(modu, wx)
		end
	end
end

-- AddPrefabPostInit("wx78module_maxhunger1", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- hunger1_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- hunger1_deactivate(modu, wx)
		-- end
    -- end
-- end)
-- AddPrefabPostInit("wx78module_maxhunger", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- hunger_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- hunger_deactivate(modu, wx)
		-- end
    -- end
-- end)

--强大的胃
if hunger_strongstomach then

local function TooStrong(wx)
	if not TheWorld.ismastersim then return wx end
	if wx.components.eater then
		local oldfn = wx.components.eater.custom_stats_mod_fn
		wx.components.eater.custom_stats_mod_fn = function(wx, health_delta, hunger_delta, sanity_delta, food, feeder)
			if oldfn then		
				health_delta, hunger_delta, sanity_delta = oldfn(wx, health_delta, hunger_delta, sanity_delta, food, feeder)
			end
			local level = GetHungerLevel(wx)
			
			--食物不扣除属性
			if level > 0 then
				if health_delta < 0 then health_delta = 0 end
				if hunger_delta < 0 then hunger_delta = 0 end
				if sanity_delta < 0 then sanity_delta = 0 end
			end
			
			--超级版翻倍属性
			if level >= 2 then
				health_delta = health_delta * 1.5
				hunger_delta = hunger_delta * 1.5
				sanity_delta = sanity_delta * 1.5
			end
			
			return health_delta, hunger_delta, sanity_delta
		end		
	end
end

AddPlayerPostInit(TooStrong)
AddPrefabPostInit("wx78_possessedbody", TooStrong) --附身底盘兼容

end


--饥饿充电
if hunger_fastcharge then

--检测胃增益电路(兼容集成电路模组)
local function CheckHungerModu(wx)
	if not wx.components.upgrademoduleowner then return false end
	
	--集成电路mod的大型集成电路已经无限电了
	if wx.IC3_fastchargetask ~= nil and wx.components.upgrademoduleowner:GetModuleTypeCount("dh_large_ic") > 0 then
		return false
	end 	
	
	--先检测最直接的
	if GetHungerLevel(wx) > 0 then
		return true
	end
	
    for _,modu in pairs(wx.components.upgrademoduleowner:GetAllModules()) do
        if modu.prefab == "wx78module_maxhunger1" or modu.prefab == "wx78module_maxhunger" then
            return true
        end

		--豆增压电路兼容
		if bee_3in1 and modu.prefab == "wx78module_bee" then
			return true
		end
		
		--再消化电路兼容
		if modu.prefab == "wx78module_digestion" and modu.components.wmb_mimic then
			local prefab = modu.components.wmb_mimic.mimic_prefab
			if prefab == "wx78module_maxhunger1" 
				or prefab == "wx78module_maxhunger"
				or (bee_3in1 and prefab == "wx78module_bee")
			then
				return true
			end
		end
		
		--集成电路mod兼容
		if modu.components.dh_ic_updatable ~= nil then
			for _,name in pairs(modu.components.dh_ic_updatable.ic_inserted_name_list) do
				if name == "maxhunger1" or name == "maxhunger" or (bee_3in1 and name == "wx78module_bee") then
					return true
				end
			end
		end
    end	
	
	return false
end

AddComponentPostInit("upgrademoduleowner", function(UpgradeModuleOwner)
	local wx = UpgradeModuleOwner.inst
	if wx.WMB_fastchargetask ~= nil then wx.WMB_fastchargetask:Cancel() wx.WMB_fastchargetask = nil end
	wx.WMB_fastchargetask = wx:DoPeriodicTask(3, function(wx)
		if wx.components.upgrademoduleowner and not wx.components.upgrademoduleowner:ChargeIsMaxed() then	
			if CheckHungerModu(wx) and wx.components.hunger and wx.components.hunger:GetPercent() >= 0.78 then
				wx.components.hunger:DoDelta(-hunger_fastchargecost, false)
				wx.components.upgrademoduleowner:AddCharge(1)
			end
		end
	end)
end)

end

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_maxhunger1", function(modu)
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
AddPrefabPostInit("wx78module_maxhunger", function(modu)
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

