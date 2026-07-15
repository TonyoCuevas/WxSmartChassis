--豆增压电路
--(胃增益电路饥饿充电功能在对应的文件中)

local beeHeal = GetModConfigData("bee_heal")
local beeHealPeriod = GetModConfigData("bee_healperiod")
local beeNegSanImmune = GetModConfigData("bee_negsanimmune")

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

local health_activate, health_deactivate = function()end, function()end
local sanity_activate, sanity_deactivate = function()end, function()end
local hunger_activate, hunger_deactivate = function()end, function()end

--三合一
if GetModConfigData("bee_3in1") then
	for _,modu in pairs(module_definitions) do
		if modu.name == "maxhealth2" then
			health_activate = modu.activatefn
			health_deactivate = modu.deactivatefn
		end

		if modu.name == "maxsanity" then
			sanity_activate = modu.activatefn
			sanity_deactivate = modu.deactivatefn
		end	
		
		if modu.name == "maxhunger" then
			hunger_activate = modu.activatefn
			hunger_deactivate = modu.deactivatefn
		end	
	end
else
	for _,modu in pairs(module_definitions) do
		if modu.name == "maxsanity" then
			sanity_activate = modu.activatefn
			sanity_deactivate = modu.deactivatefn
		end	
	end	
end

--豆增压电路恢复效果
local function bee_tick(wx, modu)
	if wx.WMB_beenum and wx.WMB_beenum > 0 and wx.components.health and not wx.components.health:IsDead() then
		wx.components.health:DoDelta(wx.WMB_beenum * beeHeal, false, modu.prefab, true)
	end
end

--豆增压电路激活
local function bee_activate(modu, wx, isloading, ...)
    wx.WMB_beenum = (wx.WMB_beenum or 0) + 1

	--恢复效果
	if wx.WMB_beenum == 1 then
		if wx.WMB_beeregen ~= nil then wx.WMB_beeregen:Cancel() end
		wx.WMB_beeregen = wx:DoPeriodicTask(beeHealPeriod, bee_tick, nil, modu)
	end
	
	--噩梦光环免疫
	if beeNegSanImmune and wx.components.sanity then
		wx.components.sanity.neg_aura_modifiers:SetModifier(modu, 0)
	end

	health_activate(modu, wx, isloading, ...)
	sanity_activate(modu, wx, isloading, ...)
	hunger_activate(modu, wx, isloading, ...)
end

--豆增压电路关闭
local function bee_deactivate(modu, wx, ...)
    wx.WMB_beenum = math.max(0, (wx.WMB_beenum or 0) - 1)

	if wx.WMB_beenum <= 0 then
		--移除恢复效果
		if wx.WMB_beeregen ~= nil then
			wx.WMB_beeregen:Cancel()
			wx.WMB_beeregen = nil
		end

		--移除噩梦光环免疫
		if beeNegSanImmune and wx.components.sanity then
			wx.components.sanity.neg_aura_modifiers:RemoveModifier(modu)
		end
	end

	health_deactivate(modu, wx, ...)
	sanity_deactivate(modu, wx, ...)
	hunger_deactivate(modu, wx, ...)
end

for _,modu in pairs(module_definitions) do
	if modu.name == "bee" then
		modu.activatefn = bee_activate
		modu.deactivatefn = bee_deactivate
	end
end

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_bee", function(modu)
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
