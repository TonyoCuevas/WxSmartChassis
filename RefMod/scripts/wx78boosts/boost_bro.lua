--附身底盘

local LANG = GetModConfigData("language")

local bro_ui = GetModConfigData("bro_ui")
local bro_no_collision = GetModConfigData("bro_no_collision")
local bro_recycle = GetModConfigData("bro_recycle")

--正常伤害倍率
if GetModConfigData("bro_normal_damage") then
	TUNING.SKILLS.WX78.POSSESSEDBODY_DAMAGE_MULT = 1
	TUNING.SKILLS.WX78.POSSESSEDBODY_PLANAR_DAMAGE_MULT = 1
	TUNING.SKILLS.WX78.POSSESSEDBODY_PLANAR_SHADOW_DAMAGE_MULT = 1
	
	TUNING.SKILLS.WX78.PLANARPOSSESSEDBODY_DAMAGE_MULT = 1
	TUNING.SKILLS.WX78.PLANARPOSSESSEDBODY_PLANAR_DAMAGE_MULT = 1
	TUNING.SKILLS.WX78.PLANARPOSSESSEDBODY_PLANAR_SHADOW_DAMAGE_MULT = 1
end

--获取原版装备栏的背包
local function GetBackpackOnBodySlot(inst)
	local body = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
	if body ~= nil and body.components.container ~= nil then
		return body
	end
end

--获取模组新增栏位的背包(若身体栏已有背包则跳过)
local function GetBackpackOnModSlot(inst)
	local backpack = GetBackpackOnBodySlot(inst)

	if backpack ~= nil then
		return backpack
	end

	backpack = (EQUIPSLOTS.BACK ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BACK)) or nil

	if backpack == nil then
		for k,v in pairs(inst.components.inventory.equipslots) do
			if v:HasTag("backpack") and v.components.container ~= nil then
				return v
			end
		end
	end

	return backpack
end

--装备监听
local function OnWXEquipedFn(doer, target, data)
    if doer.player_classified ~= nil and doer.player_classified.WMB_EquipBar ~= nil and doer.player_classified.WMB_EquipBar[data.eslot] and
        data.item and data.item.components.equippable and not data.item.components.equippable:IsRestricted(target) then
        if data.item.Network ~= nil then
            data.item.Network:SetClassifiedTarget(doer)
        end
        doer.player_classified.WMB_EquipBar[data.eslot]:set(data.item)
    end
end

--卸下装备监听
local function OnWXUnequipedFn(doer, target, data)
    if doer.player_classified.WMB_EquipBar ~= nil and doer.player_classified.WMB_EquipBar[data.eslot] ~= nil and
        data.item ~= nil and data.item.components.equippable ~= nil then
        if data.item.Network ~= nil then
            data.item.Network:SetClassifiedTarget(nil)
        end
        doer.player_classified.WMB_EquipBar[data.eslot]:set(nil)
    end
end

--显示装备栏
local function ShowEquipBar(doer, target)
    if doer.player_classified ~= nil and doer.player_classified.WMB_EquipBar ~= nil then
        doer.player_classified.WMB_EquipBar["isvisible"]:set(true)
        doer.player_classified.WMB_EquipBar["target"]:set(target)

        if target.components.inventory ~= nil then
            for _, eslot in pairs(EQUIPSLOTS) do
                if doer.player_classified.WMB_EquipBar[eslot] ~= nil then
                    if target.replica.inventory ~= nil and target.replica.inventory.classified ~= nil then
                        target.replica.inventory.classified.Network:SetClassifiedTarget(doer)
                    end
                    local item = target.components.inventory:GetEquippedItem(eslot)
                    doer.player_classified.WMB_EquipBar[eslot]:set(item)

					--为客机刷新一下物品栏
                    if item ~= nil and item.components.inventoryitem ~= nil then
                        item.components.inventoryitem:SetOwner(doer)
						
                        if item.components.armor ~= nil then
                            item:PushEvent("percentusedchange", { percent = item.components.armor:GetPercent() })
                        end
                        if item.components.finiteuses ~= nil then
                            item:PushEvent("percentusedchange", { percent = item.components.finiteuses:GetPercent() })
                        end
                        if item.components.fueled ~= nil then
                            item:PushEvent("percentusedchange", { percent = item.components.fueled:GetPercent() })
                        end
                        if item.components.perishable ~= nil then
                            item:PushEvent("perishchange", { percent = item.components.perishable:GetPercent() })
                        end
						item.components.inventoryitem:SetOwner(target)
                    end
                end
            end
        end
    end

    if doer.WMB_OnWXEquiped == nil then
        doer.WMB_OnWXEquiped = function(target, data) OnWXEquipedFn(doer, target, data) end
    end
    if doer.WMB_OnWXUnequiped == nil then
        doer.WMB_OnWXUnequiped = function(target, data) OnWXUnequipedFn(doer, target, data) end
    end

    doer:ListenForEvent("equip", doer.WMB_OnWXEquiped, target)
    doer:ListenForEvent("unequip", doer.WMB_OnWXUnequiped, target)
end

--隐藏装备栏
local function HideEquipBar(doer, target)
    if doer.player_classified ~= nil and doer.player_classified.WMB_EquipBar ~= nil then
        doer.player_classified.WMB_EquipBar["isvisible"]:set(false)
        doer.player_classified.WMB_EquipBar["target"]:set(nil)

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
end


--打开
local function OnOpen(wx, data)
	local doer = data and data.doer
    if not doer or not doer:HasTag("player") then
        return
    end

    wx.brain:Pause()
    wx.components.locomotor:Stop()
	ShowEquipBar(doer, wx)

	--设置领队(弃用,因为有遥控器了)
	-- if doer.prefab == "wx78" and wx.components.follower then
		-- if wx.components.follower.leader == nil then		
			-- wx.components.follower:SetLeader(doer)
		-- end
	-- end
	
	--兼容来自模组的背包装备栏
	local backpack = GetBackpackOnModSlot(wx)
	if backpack ~= nil and backpack.components.container ~= nil then
		local playerbackpack = GetBackpackOnBodySlot(doer) or GetBackpackOnModSlot(doer)
		if playerbackpack ~= nil and playerbackpack.components.container ~= nil and
			playerbackpack.components.container:IsOpenedBy(doer) then
			playerbackpack.components.container:Close(doer)
			doer:PushEvent("closecontainer", { container = playerbackpack })
		end
		if backpack.components.container:IsOpenedByOthers(doer) then
			for _, opener in pairs(backpack.components.container:GetOpeners()) do
				if opener ~= doer then
					backpack.components.container:Close(opener)
					opener:PushEvent("closecontainer", { container = backpack })
				end
			end
		end
		backpack.Network:SetClassifiedTarget(doer)
		if backpack.components.container:IsOpenedBy(wx) then
			backpack.components.container:Close(wx)
			wx:PushEvent("closecontainer", { container = backpack })
		end
		if not backpack.components.container:IsOpenedBy(doer) then
			backpack.components.container:Open(doer)
			doer:PushEvent("opencontainer", { container = backpack })
		end
	end	
end

--关闭
local function OnClose(wx, doer)
    if not doer or not doer:HasTag("player") then
        return
    end

    wx.brain.bt:Reset()
    wx.brain:Resume()
	HideEquipBar(doer, wx)

	--兼容来自模组的背包装备栏
	local backpack = GetBackpackOnModSlot(wx)
	if backpack ~= nil and backpack.components.container ~= nil then
		if backpack.components.container:IsOpenedBy(doer) then
			backpack.components.container:Close(doer)
			doer:PushEvent("closecontainer", { container = backpack })
		end
		if not backpack.components.container:IsOpenedBy(wx) then
			backpack.components.container:Open(wx)
			wx:PushEvent("opencontainer", { container = backpack })
		end
		backpack.Network:SetClassifiedTarget(wx)
		local playerbackpack = GetBackpackOnBodySlot(doer) or GetBackpackOnModSlot(doer)
		if playerbackpack ~= nil and playerbackpack.components.container ~= nil and
			not playerbackpack.components.container:IsOpenedBy(doer) then
			playerbackpack.components.container:Open(doer)
			doer:PushEvent("opencontainer", { container = playerbackpack })
		end
	end

end

AddPrefabPostInit("wx78_possessedbody", function(wx)
	if not TheWorld.ismastersim then
		local oldfn = wx.OnEntityReplicated or function() end
		wx.OnEntityReplicated = function(wx)
			if wx.replica.container then			
				wx.replica.container:WidgetSetup("wx78_backupbody")
			end
			oldfn(wx)
		end
		return wx
	end

	--让bro可以被打开
	if bro_ui then
		--气笑了,官方直接做了个组件来让打开的时候变成备份底盘
		if wx.components.container_transform then
			wx.components.container_transform:SetOnTransform(function(inst) return inst end)
		end
	
		--将物品栏上限设置为15,避免更改物品栏上限的模组冲突
		if wx.components.inventory then
			wx.components.inventory.maxslots = 15
		end
	
		wx:AddComponent("container")
		wx.components.container:WidgetSetup("wx78_backupbody")
		wx.components.container.slots = wx.components.inventory.itemslots --连接到物品栏
		wx.components.container.onopenfn = OnOpen
		wx.components.container.onclosefn = OnClose
		
		--避免保存物品
		wx.components.container.OnSave = function()
			return {items = {}}, {}
		end
	end
	
	--无碰撞体积
	if bro_no_collision then
		wx.Physics:ClearCollisionMask()
		wx.Physics:CollidesWith(COLLISION.WORLD)
	end
	
	
	--以下均为细节优化
	--if not GetModConfigData("bro_detil") then return wx end
	
	--落水不丢失物品
	if wx.components.drownable then
		wx.components.drownable.shoulddropitemsfn = function() return false end
	end
	
	--被领队攻击不再直接挂掉(硬核,可能也会影响到其他攻击效果)
	local oldfn = wx.PushEvent
	function wx:PushEvent(event, data, ...)
		if event == "attacked" and data and type(data) == "table" then
			if data.attacker ~= nil and data.attacker.components.leader ~= nil then
				if data.attacker.components.leader:IsFollower(self) then
					data.attacker = nil
				end
			end
		end
		return oldfn(self, event, data, ...)
	end	

end)

--右键回收动作注册
local WMB_RECYCLE_GESTALT = Action({priority = 10, mount_valid = true})
WMB_RECYCLE_GESTALT.id = "WMB_RECYCLE_GESTALT"
WMB_RECYCLE_GESTALT.str = (LANG and "回收虚影") or "Recycle Gestalt"
WMB_RECYCLE_GESTALT.fn = function(act)
	local target = act.target; if target == nil or target.prefab ~= "wx78_possessedbody" then return false end
	local invobject = act.invobject; if invobject == nil or invobject.prefab ~= "gestalt_cage" then return false end
	local doer = act.doer; if doer == nil then return false end

	if target.components.health and target.components.health:GetPercent() >= 1 then
		--卸下
		if doer.components.inventory and doer.components.inventory:IsItemEquipped(invobject) and invobject.components.equippable then
			doer.components.inventory:Unequip(invobject.components.equippable.equipslot)
		end
		
		invobject:Remove()
		
		--生成对应虚影物品
		local planar = target.GetIsPlanar ~= nil and target:GetIsPlanar()
		local prefab = (planar and "gestalt_cage_filled2") or "gestalt_cage_filled1"
		local item = SpawnPrefab(prefab)
		local x, y, z = target.Transform:GetWorldPosition()
		item.Transform:SetPosition(x, y, z)
	
		--位面属性要单独加
		if planar and item.SetIsPlanar then
			item:SetIsPlanar(true)
		end
	
		--尝试送入物品栏
		if doer.components.inventory then
			doer.components.inventory:GiveItem(item)
		end			
		
		if target.DoSanityDeath then
			target:DoSanityDeath()
		else		
			target.components.health:Kill()
		end
		
		return true
	else
		doer:DoTaskInTime(0, function(doer)		
			if doer.components.talker then
				local tip = (LANG and "错误：对象没有恢复完全") or "Erro: Object has not fully recovered."
				doer.components.talker:Say(tip)
			end
		end)
		return false
	end

	return false
end

AddAction(WMB_RECYCLE_GESTALT)

AddComponentAction("USEITEM", "gestaltcage", function(inst, doer, target, actions, right)
	if right and bro_recycle
		and inst.prefab == "gestalt_cage" 
		and target.prefab == "wx78_possessedbody"
	then
		table.insert(actions, ACTIONS.WMB_RECYCLE_GESTALT)
	end
end)
AddComponentAction("EQUIPPED", "gestaltcage", function(inst, doer, target, actions, right)
	if right and bro_recycle
		and inst.prefab == "gestalt_cage" 
		and target.prefab == "wx78_possessedbody"
	then
		table.insert(actions, ACTIONS.WMB_RECYCLE_GESTALT)
	end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_RECYCLE_GESTALT, "domediumaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_RECYCLE_GESTALT, "domediumaction"))

--以下均为细节优化
--if not GetModConfigData("bro_detil") then return end

--免疫偷窃
AddComponentPostInit("thief", function(Thief)
	local oldfn = Thief.StealItem
	function Thief:StealItem(victim, itemtosteal, attack)
		if victim == nil or victim.prefab ~= "wx78_possessedbody" then
			oldfn(self, victim, itemtosteal, attack)
		end
	end
end)

--未开启pvp时,总是视为队友
AddClassPostConstruct("components/combat_replica", function(self)
    local oldfn = self.IsAlly
    self.IsAlly = function(self, guy, ...)
		if guy and guy.prefab == "wx78_possessedbody" and not TheNet:GetPVPEnabled() then
			return true
		end
        return oldfn(self, guy, ...)
    end
end)

--旋转根本就不需要目标
local WX78Common = require("prefabs/wx78_common")
AddStategraphPostInit("wx78_possessedbody", function(sg)

	local handler = sg.events.doattack
	if handler then
		local oldfn = handler.fn or function() end
		handler.fn = function(inst, data)
			
			--条件基本复制自原版,删除了旋转目标判定
			if inst.components.health ~= nil and not inst.components.health:IsDead() and not inst.sg:HasStateTag("busy") then
				local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
				if inst.GetModuleTypeCount and
					inst:GetModuleTypeCount("spin") > 0 and
					WX78Common.CanSpinUsingItem(weapon)
				then
					if not inst.sg:HasStateTag("prespin") then
						inst.sg:GoToState(inst.sg:HasStateTag("spinning") and "wx_spin" or "wx_spin_start", {
							target = data ~= nil and data.target or nil,
						})
					end
				else
					return oldfn(inst, data)
				end
			end
		end
	end

end)