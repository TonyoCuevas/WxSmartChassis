--扫描仪

local LANG = GetModConfigData("language")

local scanner_perish_mult = GetModConfigData("scanner_perish_mult")
local sannerSpdMult = GetModConfigData("scanner_spd")
local sannerRepair = GetModConfigData("scanner_repair")
local sannerRepairPeriod = GetModConfigData("scanner_repairperiod")
local scanner_unload = GetModConfigData("scanner_unload")
local scanner_inv = GetModConfigData("scanner_inv")

TUNING.WX78_SCANNER_MODULETARGETSCANTIME = GetModConfigData("scanner_scantime")
TUNING.WX78_SCANNER_MODULETARGETSCANTIME_EPIC = GetModConfigData("scanner_scantime2")

--更多扫描对象
if GetModConfigData("scanner_more") then
	local wx78_moduledefs = require("wx78_moduledefs")
	local AddCreatureScanDataDefinition = wx78_moduledefs.AddCreatureScanDataDefinition
	
	--超级强化
	AddCreatureScanDataDefinition("toadstool", "maxhealth2", 10)
	AddCreatureScanDataDefinition("toadstool_dark", "maxhealth2", 20)
	
	--超级加速
	AddCreatureScanDataDefinition("eyeofterror", "movespeed2", 6)
	AddCreatureScanDataDefinition("twinofterror1", "movespeed2", 10)
	AddCreatureScanDataDefinition("twinofterror2", "movespeed2", 10)
	
	--再消化电路
	AddCreatureScanDataDefinition("itemmimic_revealed", "digestion", 5)
	
	--旋转电路
	AddCreatureScanDataDefinition("mushgnome", "spin", 6)
end

--扫描仪初始化
AddPrefabPostInit("wx78_scanner", function(inst)
	if TheWorld.ismastersim then
		--扫描仪移速
		if inst.components.locomotor then		
			inst.components.locomotor:SetExternalSpeedMultiplier(inst, "WMB_scannerspeedmult", sannerSpdMult)
		end
	end
end)

--扫描仪容器
if GetModConfigData("scanner_container") then

--注册容器
local containers = require("containers")
local params = containers.params
params.wmb_wx78scanner =
{
	widget = {
        slotpos = {},
        animbank = "ui_wx78_backupbody_5x3",
        animbuild = "ui_wx78_backupbody_5x3",
		pos = Vector3(0, 280, 0),
        side_align_tip = 160,
        opensound = "WX_rework/module_side/open",
        closesound = "WX_rework/module_side/close",
	},
	type = "chest",
	openlimit = 1,
	itemtestfn = function(inst, item, slot)
		return item:HasTag("WMB_upgrademodule")
			or (TUNING.WX78_CHARGING_FOODS[item.prefab] ~= nil)
			or (string.sub(item.prefab, 1, 11) == "wx78module_")
			or (item.prefab == "wx78_moduleremover")
			or (item.prefab == "scandata")
			or (item.prefab == "gears")
			or (item.prefab == "transistor")
			or (item.prefab == "wagpunk_bits")
			or (item.prefab == "trinket_1")
			or (item.prefab == "trinket_6")
			or (item.prefab == "iron")
			or (item.prefab == "alloy")
			or (item.prefab == "wx78_drone_delivery_small_item")
			or (item.prefab == "wx78_drone_delivery_item")
			or (item.prefab == "wx78_drone_zap_remote")
			or (item.prefab == "wx78_gestalttrapper")
			or (item.prefab == "gestalt_cage")
			or (item.prefab == "gestalt_cage_filled1")
			or (item.prefab == "gestalt_cage_filled2")
			or (item.prefab == "gestalt_cage_filled3")
	end,
}

for y = 2, 0, -1 do
    for x = 0, 4, 1 do
        table.insert(params.wmb_wx78scanner.widget.slotpos, Vector3(80 * x - 80 * 2, 80 * y - 80 * 2 - 42.5, 0))
    end
end

--卸货RPC
AddModRPCHandler("WMB_MOD_RPC", "UnloadContainer", function(player, inst)
	local doer = player; if not doer then return end
	if inst and inst.components.container then
		inst.components.container:DropEverything()
	end
end)

--卸货按钮
if scanner_unload then
	params.wmb_wx78scanner.widget.buttoninfo = {
		text = (LANG and "卸货") or "Unload",
		position = Vector3(0, -280, 0),
		fn = function(inst, doer)
			SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "UnloadContainer"), inst)
		end,
		validfn = function(inst)
			return inst.replica.container ~= nil and not inst.replica.container:IsEmpty()
		end,
	}
end

--恢复容器内电路1%耐久
local function RestoreModules(inst)
	if not inst.components.container then return end
	for _,item in pairs(inst.components.container.slots) do
		if (item.components.upgrademodule or item.WMB_hotplugmodu) and item.components.finiteuses then
			local percent = item.components.finiteuses:GetPercent()
			if percent < 1 then
				item.components.finiteuses:SetPercent(math.min(1, percent + 0.01))
			end
		end
	end
end

--物品状态扫描仪初始化
AddPrefabPostInit("wx78_scanner_item", function(inst)
	if not TheWorld.ismastersim then
		local oldfn = inst.OnEntityReplicated or function() end
		inst.OnEntityReplicated = function(inst) 
			inst.replica.container:WidgetSetup("wmb_wx78scanner")
			oldfn(inst)
		end
		return inst
	end

	--添加容器
	if inst.components.container == nil then
		inst:AddComponent("container")
		inst.components.container:WidgetSetup("wmb_wx78scanner")
	end

	if inst.components.deployable then
		do --有内容物时不能放置
			local oldfn = inst._custom_candeploy_fn
			inst._custom_candeploy_fn = function(inst, pt, mouseover, deployer, rot)
				if inst.components.container and not inst.components.container:IsEmpty() then
					return false
				end			
				return oldfn(inst, pt, mouseover, deployer, rot)
			end
		end

		do --放置时丢下内容物
			local oldfn = inst.components.deployable.ondeploy
			inst.components.deployable.ondeploy = function(inst, pt, deployer)
				if inst.components.container then
					inst.components.container:DropEverything()
				end
				oldfn(inst, pt, deployer)
			end
		end
	end
	
	--修复内含电路
	if sannerRepair then
		if inst.WMB_RestoreTask == nil then
			inst.WMB_RestoreTask = inst:DoPeriodicTask(sannerRepairPeriod, RestoreModules)
		end
	end	
	
	--保鲜效果
	if scanner_perish_mult < 1 then	
		inst:AddComponent("preserver")
		inst.components.preserver:SetPerishRateMultiplier(scanner_perish_mult)
	end
end)

--有内容物时不能放置
local oldondeploy = ACTIONS.DEPLOY.fn or function() end
ACTIONS.DEPLOY.fn = function(act)
	local target = act.invobject or act.target
	if target ~= nil and target.prefab == "wx78_scanner_item" then
		if target.components.container and not target.components.container:IsEmpty() then
			return false
		end	
		
		--保险,丢下内容物
		if target.components.container then
			target.components.container:DropEverything()
		end		
	end
	return oldondeploy(act)
end

--打开优先而不是放置(适配牛牛的改动mod)
AddComponentAction("INVENTORY", "deployable", function(inst, doer, actions, right)
	if inst.prefab == "wx78_scanner_item" then
		for k,action in ipairs(actions) do
			if action.id == "BEFFPOT" then
				table.remove(actions, k)
			end
		end
	end
end)

end



local GetCreatureScanDataDefinition = require("wx78_moduledefs").GetCreatureScanDataDefinition

--生成数据
local function SpawnData(doer, prefab)
	if doer and doer.components.dataanalyzer then
		local amount = doer.components.dataanalyzer:SpendData(prefab)

		if amount > 0 then
			local scandata = SpawnPrefab("scandata")
			local x, y, z = doer.Transform:GetWorldPosition()
			scandata.Transform:SetPosition(x, y, z)
			
			--设置堆叠量
			if scandata.components.stackable then				
				scandata.components.stackable:SetStackSize(amount)
			end

			--尝试送入物品栏
			if doer.components.inventory then
				doer.components.inventory:GiveItem(scandata)
			end
			
			return true
		end
	end
	return false
end

--获取配方
local function GetCreatureRecipeScan(doer, scandata)
	if scandata.recipename then
		return FunctionOrValue(scandata.recipename, doer)
	else
		return "wx78module_"..scandata.module
	end
end

--右键扫描动作注册
local WMB_INVSCAN = Action({priority = 3, mount_valid = true})
WMB_INVSCAN.id = "WMB_INVSCAN"
WMB_INVSCAN.str = (LANG and "扫描") or "Scan"
WMB_INVSCAN.fn = function(act)
	local doer = act.doer
	local target = act.target
	local invobject = act.invobject
	if target == nil or invobject == nil or doer == nil then return false end
	if doer.components.dataanalyzer == nil then return false end
	local SUCCESS = false

	--学习配方
	local ent_scandata = GetCreatureScanDataDefinition(target.prefab)
	if ent_scandata ~= nil then
		local recipename = GetCreatureRecipeScan(doer, ent_scandata)
		if recipename ~= nil and doer.components.builder and not doer.components.builder:KnowsRecipe(recipename) then
			doer.components.builder:UnlockRecipe(recipename)
			doer:PushEvent("learnrecipe", { recipe = recipename })
			SUCCESS = true
		end
	end

	--生成生物数据
	if SpawnData(doer, target.prefab) then
		SUCCESS = true
	end

	return SUCCESS
end

AddAction(WMB_INVSCAN)

AddComponentAction("USEITEM", "deployable", function(inst, doer, target, actions, right)
	if scanner_inv and right and inst.prefab == "wx78_scanner_item" 
		and doer:HasTag("upgrademoduleowner")
		and target and target.replica.inventoryitem ~= nil
		and target.replica.inventoryitem:IsHeld()
		and GetCreatureScanDataDefinition(target.prefab) ~= nil
	then
        table.insert(actions, ACTIONS.WMB_INVSCAN)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_INVSCAN, "domediumaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_INVSCAN, "domediumaction"))

