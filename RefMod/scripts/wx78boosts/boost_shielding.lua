--格挡电路

TUNING.WX78_SHIELDING_ARMOR = GetModConfigData("shielding_absorption") or TUNING.WX78_SHIELDING_ARMOR
TUNING.WX78_SHIELDING_COOLDOWN = GetModConfigData("shielding_cd") or TUNING.WX78_SHIELDING_COOLDOWN
TUNING.WX78_SHIELDING_TOTAL_DAMAGE = GetModConfigData("shielding_capacity") or TUNING.WX78_SHIELDING_TOTAL_DAMAGE

local shielding_armor = GetModConfigData("shielding_armor")
local shielding_absorption_armor = GetModConfigData("shielding_absorption_armor") or 0.75

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_shield_tag = net_bool(inst.GUID, "WMB_shield_tag", "WMB_shield_tag.dirty")
	inst.WMB_shield_tag:set(false)
end)

--格挡电路激活
local function shielding_activate(modu, wx, isloading)
	wx.WMB_shieldingnum = (wx.WMB_shieldingnum or 0) + 1
	
	if wx.player_classified and wx.player_classified.WMB_shield_tag then
		wx.player_classified.WMB_shield_tag:set(true)
	end
end

--格挡电路关闭
local function shielding_deactivate(modu, wx)
	wx.WMB_shieldingnum = math.max(0, (wx.WMB_shieldingnum or 0) - 1)

	--官方没有考虑多个格挡电路的情况
	if wx.WMB_shieldingnum > 0 then
		if wx.wx78_classified ~= nil then
			wx.wx78_classified:AddInherentAction(ACTIONS.TOGGLEWXSHIELDING)
		end
	else
		if wx.player_classified and wx.player_classified.WMB_shield_tag then
			wx.player_classified.WMB_shield_tag:set(false)
		end
	end
end

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "shielding" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			shielding_activate(modu, wx, isloading)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			shielding_deactivate(modu, wx)
		end
	end
end

--让护甲也享受减伤
AddComponentPostInit("armor", function(Armor)
	local oldfn = Armor.TakeDamage or function() end
	function Armor:TakeDamage(damage_amount, ...)
		local owner = (self.inst.components.inventoryitem and self.inst.components.inventoryitem.owner) or nil
		if damage_amount > 0 and owner and owner.sg then
		
			--格挡时
			if owner.sg:HasStateTag("wxshielding") then
				if shielding_armor then
					damage_amount = damage_amount * TUNING.WX78_SHIELDING_ARMOR
				end
			elseif owner.WMB_shieldingnum and owner.WMB_shieldingnum > 0 then
				if shielding_absorption_armor < 1 then
					damage_amount = damage_amount * shielding_absorption_armor
				end
			end
		end
		return oldfn(self, damage_amount, ...)
	end
end)

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_shielding", function(modu)
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


--能力勋章格挡电路修复(不知道为什么TOGGLEWXSHIELDING被换成DOPROPHESY了)
do
	local function validfn(inst)
		if inst:HasTag("wx_shielding") then
			return true
		end

		if inst.components.wx78_abilitycooldowns and inst.components.wx78_abilitycooldowns:IsInCooldown("shielding") then
			return false
		end
		return not inst:HasAnyTag("wx_shielding", "busy", "inspectingupgrademodules", "using_drone_remote")
	end

	AddComponentAction("SCENE", "upgrademoduleowner", function(inst, doer, actions, right)
		if right and doer == inst
			and doer.player_classified
			and doer.player_classified.WMB_shield_tag
			and doer.player_classified.WMB_shield_tag:value()
			and validfn(doer)
		then
			table.insert(actions, ACTIONS.TOGGLEWXSHIELDING)
		end
	end)
end
