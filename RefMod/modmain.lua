GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

--[[说明:
本模组兼容"WX自动化"模组,其机器人的prefab字符串为"wx"
]]

Assets = {
	Asset("ANIM", "anim/wmb_wx_chips.zip"),
	Asset("ANIM", "anim/wmb_status_wx_chest.zip"),
	
	Asset("ATLAS", "images/wmb_mapicons.xml"),
	Asset("IMAGE", "images/wmb_mapicons.tex"),
	
	Asset("ATLAS", "images/wmb_spell_icons.xml"),
	Asset("IMAGE", "images/wmb_spell_icons.tex"),

    Asset("IMAGE", "images/inventoryimages/wmb/wx78module_stacksize.tex"),
    Asset("ATLAS", "images/inventoryimages/wmb/wx78module_stacksize.xml"),
	
	Asset("SOUNDPACKAGE", "sound/wmbmusic.fev"),
	Asset("SOUND", "sound/wmbmusic_1.fsb"),
}

PrefabFiles = {
    "wmb_taser_fx",
}

AddMinimapAtlas("images/wmb_mapicons.xml")

AddReplicableComponent("wmb_mimic")

local LANG = GetModConfigData("language")

--装备栏实现(当时做WX自动化补丁是对的)
do

	 --注册RPC
	do
		--给装备
		AddModRPCHandler("WMB_MOD_RPC", "GiveToWX", function(player, doer, target, eslot)
			player = (doer ~= nil and doer ~= player and doer) or player

			local active_item = (player and player.components.inventory and player.components.inventory:GetActiveItem()) or nil
			if target and target.components.inventory and active_item and active_item.components.equippable and
				not active_item.components.equippable:IsRestricted(target) then
				local equipped_item = target.components.inventory:GetEquippedItem(eslot)
				if equipped_item and equipped_item.prefab == active_item.prefab and equipped_item.skinname == active_item.skinname and
					equipped_item.components.stackable and target.components.inventory:AcceptsStacks() then
					local leftovers = equipped_item.components.stackable:Put(active_item)
					player.components.inventory:SetActiveItem(leftovers)
				else
					local item = target.components.inventory:RemoveItem(equipped_item, true)
					if item then
						player.components.inventory:GiveActiveItem(item)
					end
					target.components.inventory:Equip(active_item)
				end

				player.sg:GoToState("give")
				player:ForceFacePoint(target.Transform:GetWorldPosition())
			end
		end)

		--拿装备
		AddModRPCHandler("WMB_MOD_RPC", "TakeFromWX", function(player, doer, target, eslot)
			player = (doer ~= nil and doer ~= player and doer) or player

			if target and target.components.inventory and player and player.components.inventory then			
				local equipped_item = target.components.inventory:GetEquippedItem(eslot)
				if equipped_item then
					if equipped_item.components.container and equipped_item.components.container:IsOpen() then
						equipped_item.components.container:Close()
					end
				
					local item = target.components.inventory:RemoveItem(equipped_item, true)
					if item then
						player.components.inventory:GiveActiveItem(item)
						
						player.sg:GoToState("give")
						player:ForceFacePoint(target.Transform:GetWorldPosition())
					end
				end
			end
		end)

		--右键装备
		AddModRPCHandler("WMB_MOD_RPC", "UseWXItem", function(player, doer, target, eslot)
			player = (doer ~= nil and doer ~= player and doer) or player

			if target and target.components.inventory then			
				local equipped_item = target.components.inventory:GetEquippedItem(eslot)
				if equipped_item then
					if equipped_item.components.container then
						if equipped_item.components.container:IsOpenedBy(player) then
							equipped_item.components.container:Close(player)
						else
							equipped_item.components.container:Open(player)
							player:PushEvent("opencontainer", { container = equipped_item })
						end

						player.sg:GoToState("doshortaction")
						player:ForceFacePoint(target.Transform:GetWorldPosition())
					else
					
						--备份底盘的物品栏是另一个实体,要单独考虑
						local parent = target.entity:GetParent()
						if parent ~= nil and parent.prefab == "wx78_backupbody" and parent.components.container then
							if not parent.components.container:IsFull() then
								local item = target.components.inventory:RemoveItem(equipped_item, true)
								if item then								
									parent.components.container:GiveItem(item)
								end
							else
								target.components.inventory:DropItem(equipped_item, true, true)
							end						
						else					
							if not target.components.inventory:IsFull() then
								local item = target.components.inventory:Unequip(eslot)
								if item then								
									target.components.inventory:GiveItem(item)
								end
							else
								target.components.inventory:DropItem(equipped_item, true, true)
							end
						end
						
					end
				end
			end
		end)

	end

	--注册HUD
	do
		local WMB_EquipBar = require("widgets/wmb_equipbar")
		local PlayerHud = require("screens/playerhud")
		function PlayerHud:WMB_ShowEquipBar()
			if self.controls.containerroot.WMB_EquipBar == nil then
				self.controls.containerroot.WMB_EquipBar = self.controls.containerroot:AddChild(WMB_EquipBar(self.owner))
				self.controls.containerroot.WMB_EquipBar:MoveToBack()
			end

			if self.controls.containerroot.WMB_EquipBar ~= nil then
				self.controls.containerroot.WMB_EquipBar:Open()
			end
		end

		function PlayerHud:WMB_HideEquipBar()
			if self.controls.containerroot.WMB_EquipBar ~= nil then
				self.controls.containerroot.WMB_EquipBar:Close()
			end
		end

		function PlayerHud:WMB_RefreshEquipBar()
			if self.controls.containerroot.WMB_EquipBar ~= nil then
				self.controls.containerroot.WMB_EquipBar:Refresh()
			end
		end
	end

	--隐藏装备栏(显示装备栏在备份底盘和附身底盘文件)
	local function HideEquipBar(doer)
		if doer.player_classified ~= nil and doer.player_classified.WMB_EquipBar ~= nil then
			local target = (doer.player_classified.WMB_EquipBar["target"] and doer.player_classified.WMB_EquipBar["target"]:value()) or nil
		
			if target then			
				for _, eslot in pairs(EQUIPSLOTS) do
					if doer.player_classified.WMB_EquipBar[eslot] ~= nil then
						if target.replica.inventory ~= nil and target.replica.inventory.classified ~= nil then
							target.replica.inventory.classified.Network:SetClassifiedTarget(target.replica.inventory.classified)
						end
						local item = target.components.inventory:GetEquippedItem(eslot)
						if item ~= nil and item.components.inventoryitem ~= nil then
							item.components.inventoryitem:SetOwner(target)
						end
						doer.player_classified.WMB_EquipBar[eslot]:set(nil)
					end
				end
			end
			
			if doer.WMB_OnWXEquiped ~= nil then
				doer:RemoveEventCallback("equip", doer.WMB_OnWXEquiped, target)
			end
			if doer.WMB_OnWXUnequiped ~= nil then
				doer:RemoveEventCallback("unequip", doer.WMB_OnWXUnequiped, target)
			end
			
			doer.player_classified.WMB_EquipBar["isvisible"]:set(false)
			doer.player_classified.WMB_EquipBar["target"]:set(nil)
		end
	end

	--数据处理
	AddPrefabPostInit("player_classified", function(inst)
		inst.WMB_EquipBar = {}
		inst.WMB_EquipBar["isvisible"] = net_bool(inst.GUID, "WMB_EquipBar.isvisible", "WMB_EquipBar.isvisible.dirty")
		inst.WMB_EquipBar["isvisible"]:set(false)
		inst.WMB_EquipBar["target"] = net_entity(inst.GUID, "WMB_EquipBar.target", "WMB_EquipBar.target.dirty")
		inst.WMB_EquipBar["target"]:set(nil)

		for _, eslot in pairs(EQUIPSLOTS) do
			inst.WMB_EquipBar[eslot] = net_entity(inst.GUID, "WMB_EquipBar."..tostring(eslot), "WMB_EquipBar"..tostring(eslot).."dirty")
			inst.WMB_EquipBar[eslot]:set(nil)
		end

		inst:DoTaskInTime(0, function(inst)
			if ThePlayer ~= nil and ThePlayer.player_classified == inst then
				inst._parent = inst._parent or inst.entity:GetParent()

				inst:ListenForEvent("WMB_EquipBar.isvisible.dirty", function(inst)
					if inst._parent and inst._parent.HUD then
						if inst.WMB_EquipBar["isvisible"] ~= nil and inst.WMB_EquipBar["isvisible"]:value() then
							inst._parent.HUD:WMB_ShowEquipBar()
						elseif inst.WMB_EquipBar["isvisible"] ~= nil and not inst.WMB_EquipBar["isvisible"]:value() then
							inst._parent.HUD:WMB_HideEquipBar()
						end
					end
				end)

				for _, eslot in pairs(EQUIPSLOTS) do
					inst:ListenForEvent("WMB_EquipBar"..tostring(eslot).."dirty", function(inst)
						if inst._parent ~= nil and inst._parent.HUD ~= nil then
							inst._parent.HUD:WMB_RefreshEquipBar()
						end    
					end)
				end

				inst:ListenForEvent("stackitemdirty", function(world, item)
					for _, eslot in pairs(EQUIPSLOTS) do
						if inst.WMB_EquipBar[eslot]:value() == item and inst._parent ~= nil and inst._parent.HUD ~= nil then
							item:PushEvent("stacksizechange", { stacksize = item.replica.stackable:StackSize() })
							break
						end
					end
				end, TheWorld)
				
				--关闭备份底盘或附身底盘时隐藏装备栏
				inst:ListenForEvent("closecontainer", function(doer, data)
					if data and data.container then
						if data.container:HasOneOfTags({ "wx78_backupbody", "possessedbody" }) then
							HideEquipBar(doer)
						end
					end
				end, ThePlayer)
			end
		end)
	end)


	--右键给予装备动作注册
	local WMB_GIVEEQUIP = Action({priority = 0.5, instant = true, mount_valid = true, encumbered_valid = true, paused_valid = true})
	WMB_GIVEEQUIP.id = "WMB_GIVEEQUIP"
	WMB_GIVEEQUIP.str = (LANG and "给予装备") or "Let'em Equip"
	WMB_GIVEEQUIP.fn = function(act)
		local item = act.invobject; if (item == nil or item.components.equippable == nil) then return false end
		local doer = act.doer; if (doer == nil or doer.player_classified == nil or doer.components.inventory == nil) then return false end
		local target = (doer.player_classified.WMB_EquipBar["target"] and doer.player_classified.WMB_EquipBar["target"]:value()) or nil

		if target and target.components.inventory then
			if not item.components.equippable:IsRestricted(target) then
				
				--从原主身上移除
				if item.components.inventoryitem then
					local owner = item.components.inventoryitem.owner
					if owner == nil or owner ~= target then					
						item = item.components.inventoryitem:RemoveFromOwner(true)
						if item == nil then
							return false
						end
					end
				else
					return false
				end
			
				local eslot = item.components.equippable.equipslot or ""
				local equipped_item = target.components.inventory:GetEquippedItem(eslot)
				
				if equipped_item then
					if not target.components.inventory:IsFull() then
						local _item = target.components.inventory:Unequip(eslot)
						if _item then								
							target.components.inventory:GiveItem(_item)
						end
					else
						target.components.inventory:DropItem(equipped_item, true, true)
					end
				end
			
				target.components.inventory:Equip(item)
				
				--防止私藏物品
				target.components.inventory:ReturnActiveItem()
				
				return true
			end
		end

		return false
	end

	AddAction(WMB_GIVEEQUIP)
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_GIVEEQUIP, "give"))
	AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_GIVEEQUIP, "give"))

	--右键给予装备动作注册(备份底盘)
	local WMB_GIVEEQUIP_BACKUP = Action({priority = 0.5, instant = true, mount_valid = true, encumbered_valid = true, paused_valid = true})
	WMB_GIVEEQUIP_BACKUP.id = "WMB_GIVEEQUIP_BACKUP"
	WMB_GIVEEQUIP_BACKUP.str = (LANG and "给予装备") or "Let'em Equip"
	WMB_GIVEEQUIP_BACKUP.fn = function(act)
		local item = act.invobject; if (item == nil or item.components.equippable == nil) then return false end
		local doer = act.doer; if (doer == nil or doer.player_classified == nil or doer.components.inventory == nil) then return false end
		local target = (doer.player_classified.WMB_EquipBar["target"] and doer.player_classified.WMB_EquipBar["target"]:value()) or nil
		local wx = (target and target.entity:GetParent()) or nil

		if target and target.components.inventory and wx and wx.components.container then
			if not item.components.equippable:IsRestricted(target) then
			
				--从原主身上移除
				if item.components.inventoryitem then
					local owner = item.components.inventoryitem.owner
					if owner == nil or owner ~= target then					
						item = item.components.inventoryitem:RemoveFromOwner(true)
						if item == nil then
							return false
						end
					end
				else
					return false
				end		
			
				local eslot = item.components.equippable.equipslot or ""
				local equipped_item = target.components.inventory:GetEquippedItem(eslot)

				if equipped_item then
					if not wx.components.container:IsFull() then
						local _item = target.components.inventory:RemoveItem(equipped_item, true)
						if _item then								
							wx.components.container:GiveItem(_item)
						end
					else
						target.components.inventory:DropItem(equipped_item, true, true)
					end
				end
			
				target.components.inventory:Equip(item)
				
				--防止私藏物品
				target.components.inventory:ReturnActiveItem()			
				
				return true
			end
		end

		return false
	end

	AddAction(WMB_GIVEEQUIP_BACKUP)
	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_GIVEEQUIP_BACKUP, "give"))
	AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_GIVEEQUIP_BACKUP, "give"))

	AddComponentAction("INVENTORY", "equippable", function(inst, doer, actions, right)
		local target = (doer.player_classified and doer.player_classified.WMB_EquipBar["target"] and doer.player_classified.WMB_EquipBar["target"]:value()) or nil

		if target ~= nil then
			--附身底盘
			if target.prefab == "wx78_possessedbody" then		
				if (inst:HasTag("heavy") or inst.replica.container ~= nil or (target.replica.container ~= nil and target.replica.container:IsHolding(inst, true))) 
					and (inst.replica.equippable == nil or not inst.replica.equippable:IsRestricted(target))
				then
					table.insert(actions, ACTIONS.WMB_GIVEEQUIP)
				end
			else
				--备份底盘
				local parent = (target.entity and target.entity:GetParent()) or nil

				if parent ~= nil and parent.prefab == "wx78_backupbody"
					and (inst:HasTag("heavy") or inst.replica.container ~= nil or (parent.replica.container ~= nil and parent.replica.container:IsHolding(inst, true))) 
					and (inst.replica.equippable == nil or not inst.replica.equippable:IsRestricted(target))
				then
					table.insert(actions, ACTIONS.WMB_GIVEEQUIP_BACKUP)
				end
			end
		end	
	end)

end




--总开关检测
local function MainSwitch(name)
	return GetModConfigData(name.."_main") or false
end

--懒得写replica,将就着用吧
AddComponentPostInit("upgrademoduleowner", function(UpgradeModuleOwner)
	UpgradeModuleOwner.inst:AddTag("upgrademoduleowner")
end)
AddComponentPostInit("upgrademodule", function(UpgradeModule)
	UpgradeModule.inst:AddTag("WMB_upgrademodule")
end)


--WX78
if MainSwitch('wx78') then 
	modimport("scripts/wx78boosts/boost_wx78.lua")
end

--物品制作配方调整
if MainSwitch('recipes') then 
	modimport("scripts/wx78boosts/boost_recipes.lua")
end

--扫描仪
if MainSwitch("scanner") then
	modimport("scripts/wx78boosts/boost_scanner.lua")
end

--测绘机
if MainSwitch("scout") then
	modimport("scripts/wx78boosts/boost_scout.lua")
end

--电刑机
if MainSwitch("zap") then
	modimport("scripts/wx78boosts/boost_zap.lua")
end

--运输机
if MainSwitch("delivery") then
	modimport("scripts/wx78boosts/boost_delivery.lua")
end

--抓取机
if MainSwitch("harvester") then
	modimport("scripts/wx78boosts/boost_harvester.lua")
end

--破绽机
if MainSwitch("debuffer") then
	modimport("scripts/wx78boosts/boost_debuffer.lua")
end

--备份底盘
if MainSwitch("backup") then
	modimport("scripts/wx78boosts/boost_backup.lua")
end

--附身底盘
if MainSwitch("bro") then
	modimport("scripts/wx78boosts/boost_bro.lua")
end

--灵体传输模块
if MainSwitch("transfer") then
	modimport("scripts/wx78boosts/boost_transfer.lua")
end

--电气化电路
if MainSwitch("taser") then
	modimport("scripts/wx78boosts/boost_taser.lua")
end

--制冷&热能电路
TUNING.WX78_MINTEMPCHANGEPERMODULE = TUNING.WX78_MINTEMPCHANGEPERMODULE + GetModConfigData("coldheat_temperature")

--制冷电路
if MainSwitch("cold") then
	modimport("scripts/wx78boosts/boost_cold.lua")
end

--热能电路
if MainSwitch("heat") then
	modimport("scripts/wx78boosts/boost_heat.lua")
end

--合唱盒电路
if MainSwitch("music") then
	modimport("scripts/wx78boosts/boost_music.lua")
end

--加速电路
if MainSwitch("speed") then
	modimport("scripts/wx78boosts/boost_speed.lua")
end

--强化电路
if MainSwitch("health") then
	modimport("scripts/wx78boosts/boost_health.lua")
end

--处理器电路
if MainSwitch("sanity") then
	modimport("scripts/wx78boosts/boost_sanity.lua")
end

--胃增益电路
if MainSwitch("hunger") then
	modimport("scripts/wx78boosts/boost_hunger.lua")
end

--豆增压电路
if MainSwitch("bee") then
	modimport("scripts/wx78boosts/boost_bee.lua")
end

--照明电路
if MainSwitch("light") then
	modimport("scripts/wx78boosts/boost_light.lua")
end

--光电电路
if MainSwitch("night") then
	modimport("scripts/wx78boosts/boost_night.lua")
end

--超级照明电路
if MainSwitch("light2") then
	modimport("scripts/wx78boosts/boost_light2.lua")
end

--空间扩展电路
if MainSwitch("stacksize") then
	modimport("scripts/wx78boosts/boost_stacksize.lua")
end

--旋转电路
if MainSwitch("spin") then
	modimport("scripts/wx78boosts/boost_spin.lua")
end

--格挡电路
if MainSwitch("shielding") then
	modimport("scripts/wx78boosts/boost_shielding.lua")
end

--声波电路
if MainSwitch("screech") then
	modimport("scripts/wx78boosts/boost_screech.lua")
end


--再消化电路
if MainSwitch("digestion") then
	modimport("scripts/wx78boosts/boost_digestion.lua")
end


--能力勋章模组兼容
if GetModConfigData("compat_medal") then
	modimport("scripts/wx78boosts/compats/medal.lua")
end






