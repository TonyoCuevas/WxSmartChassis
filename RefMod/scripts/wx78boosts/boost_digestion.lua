--再消化电路

TUNING.WX78_DIGESTION_SPOILED_NEEDED = GetModConfigData("digestion_num") or TUNING.WX78_DIGESTION_SPOILED_NEEDED

--快速生产
if GetModConfigData("digestion_fast") then

	AddStategraphPostInit("wilson", function(sg)
		local state = sg.states.wx_bake
		if state then
			state.onenter = function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local brick = SpawnPrefab("wx78_foodbrick")
                brick.Transform:SetPosition(x, y, z)
				if inst.components.inventory then
					inst.components.inventory:GiveItem(brick)
				end
				inst.SoundEmitter:PlaySound("dontstarve/common/researchmachine_lvl1_ding", nil, 0.2)
				inst.sg:RemoveStateTag("busy")
				inst.sg:GoToState("idle")
			end		
		end
	end)

end

--复制电路效果
local digestion_mimic = GetModConfigData("digestion_mimic")

local LANG = GetModConfigData("language")

AddGamePostInit(function()
	if LANG then
		STRINGS.RECIPE_DESC.WX78MODULE_DIGESTION = "食物和电路都能再利用！" 
	else
		STRINGS.RECIPE_DESC.WX78MODULE_DIGESTION = "Reuse foods or circuits!" 
	end
end)

--获取数量时把复制的也加上
AddComponentPostInit("upgrademoduleowner", function(UpgradeModuleOwner)
	local oldfn = UpgradeModuleOwner.GetModuleTypeCount
	function UpgradeModuleOwner:GetModuleTypeCount(moduletype, ...)
		local count = oldfn(self, moduletype, ...)
		local module_prefab = "wx78module_"..moduletype

		for bartype, modules in pairs(self.module_bars) do
			local remaining_charge = self.charge_level
			for _, moduleent in ipairs(modules) do
				remaining_charge = remaining_charge - moduleent.components.upgrademodule.slots
				if remaining_charge < 0 then
					break
				elseif moduleent.components.wmb_mimic and moduleent.components.wmb_mimic.mimic_prefab == module_prefab then
					count = count + 1
				end
			end
		end

		return count
	end	
end)

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

local old_digestion_activate, old_digestion_deactivate = function()end, function()end

--记录原效果
for _,modu in pairs(module_definitions) do
	if modu.name == "digestion" then
		old_digestion_activate = modu.activatefn
		old_digestion_deactivate = modu.deactivatefn
	end
end

--再消化电路激活
local function digestion_activate(modu, ...)
	if modu.components.wmb_mimic and modu.components.wmb_mimic.mimic_activatefn then
		modu.components.wmb_mimic.mimic_activatefn(modu, ...)
	else	
		old_digestion_activate(modu, ...)
	end
end

--再消化电路关闭
local function digestion_deactivate(modu, ...)
	if modu.components.wmb_mimic and modu.components.wmb_mimic.mimic_deactivatefn then
		modu.components.wmb_mimic.mimic_deactivatefn(modu, ...)
	else	
		old_digestion_deactivate(modu, ...)
	end
end

for _,modu in pairs(module_definitions) do
	if modu.name == "digestion" then
		modu.activatefn = digestion_activate
		modu.deactivatefn = digestion_deactivate
	end
end

AddPrefabPostInit("wx78module_digestion", function(modu)

	--显示复制的电路名称
	local oldfn = modu.GetAdjectivedName or function() end
	modu.GetAdjectivedName = function(inst)
		local name = oldfn(inst)
		if inst.replica.wmb_mimic then			
			local prefab = inst.replica.wmb_mimic:GetMimicPrefab()
			if prefab and prefab ~= "" then		
				name = name.."["..(STRINGS.NAMES[string.upper(prefab)] or "MISSING NAME").."]"
			end
		end
		return name
	end

    if TheWorld.ismastersim then
		modu:AddComponent("wmb_mimic")
		
		--屏蔽技能树监听(硬核)
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

local TIP = (LANG and "电路已复刻") or "Circuit replicated"

--模仿动作注册
local WMB_MIMIC = Action({priority = 3, mount_valid = true, invalid_hold_action = true})
WMB_MIMIC.id = "WMB_MIMIC"
WMB_MIMIC.str = (LANG and "模仿") or "Mimic"
WMB_MIMIC.fn = function(act)
	local target = act.target; if target == nil then return false end
	local invobject = act.invobject; if invobject == nil then return false end

	if invobject.prefab == "wx78module_digestion"
		and invobject.components.upgrademodule ~= nil
		and invobject.components.wmb_mimic ~= nil
		and target.components.upgrademodule ~= nil
	then
		if invobject.prefab == target.prefab then		
			invobject.components.wmb_mimic:ClearMimic()
		else
			invobject.components.wmb_mimic:Mimic(target.prefab)
		end
		
		if act.doer and act.doer.components.talker then
			act.doer.components.talker:Say(TIP)
		end
		
		return true
	end

	return false
end

AddAction(WMB_MIMIC)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_MIMIC, "domediumaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_MIMIC, "domediumaction"))

AddComponentAction("USEITEM", "upgrademodule", function(inst, doer, target, actions)
	if digestion_mimic
		and inst.prefab == "wx78module_digestion"
		and doer:HasTag("upgrademoduleowner")
		and target.prefab ~= "wx78module_stacksize"
		and (string.sub(target.prefab, 1, 11) == "wx78module_")
	then
		table.insert(actions, ACTIONS.WMB_MIMIC)
	end
end)
