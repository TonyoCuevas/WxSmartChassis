--备份底盘

local LANG = GetModConfigData("language")

local backup_ui = GetModConfigData("backup_ui")
local backup_everyone = GetModConfigData("backup_everyone")
local backup_limit = GetModConfigData("backup_limit")
local backup_protection = GetModConfigData("backup_protection")
local backup_no_collision = GetModConfigData("backup_no_collision")
local backup_return = GetModConfigData("backup_return")

--增加上限
AddPrefabPostInit("wx78_classified", function(inst)
	if backup_limit > 0 then
		local oldfn = inst.GetMaxBackupBodies or function() end
		inst.GetMaxBackupBodies = function(...)
			local num = oldfn(...)
			return num + backup_limit
		end
	end
end)

--所有人都可打开(修改自原版打开动作)
if backup_everyone then
	local function OpenCheck(target, doer)
		if target:HasTag("wx78_backupbody") then
			--机器人
			if doer.wx78_classified then
				local linkeditem = target.components.linkeditem
				
				--为没有主人的备份设置主人
				if linkeditem then
					local owneruserid = linkeditem:GetOwnerUserID()
					if not owneruserid and target.TryToAttachToOwner then
						target:TryToAttachToOwner(doer)
					end
				end
				
				return true
			else --其他角色
				return true
			end
		end
		return false
	end

	local oldfn = ACTIONS.RUMMAGE.fn or function() end
	ACTIONS.RUMMAGE.fn = function(act)
		local targ = act.target
		local doer = act.doer
		
		if targ == nil or doer == nil 
			or targ.components.container == nil 
			or not targ:HasTag("wx78_backupbody")
			or not OpenCheck(targ, doer)
		then
			return oldfn(act)
		end
		
		--关闭
		if targ.components.container:IsOpenedBy(doer) then
            targ.components.container:Close(doer)
            doer:PushEvent("closecontainer", { container = targ })
			return true
		end
		
		--打开
		if not targ.components.container:IsOpenedBy(doer) and not targ.components.container:CanOpen() then
			return false, "INUSE"
		elseif targ.components.container.canbeopened then
			doer:PushEvent("opencontainer", { container = targ })
			targ.components.container:Open(doer)
			return true
		end
	
		return oldfn(act)
	end
end

--让其他人可以回收备份底盘
if backup_protection then

	--右键回收动作注册
	local WMB_RECYCLE_BACKUP = Action({priority = 1, distance = 1.5, invalid_hold_action = true})
	WMB_RECYCLE_BACKUP.id = "WMB_RECYCLE_BACKUP"
	WMB_RECYCLE_BACKUP.str = "回收"
	WMB_RECYCLE_BACKUP.fn = function(act)
		local target = act.target
		local doer = act.doer
		if target == nil or act.doer == nil then return false end
		if target.prefab ~= "wx78_backupbody" then return false end

		if doer.components.inventory then					
			local recipe = AllRecipes[target.prefab]
			if recipe and recipe.ingredients then
				for k,v in ipairs(recipe.ingredients) do
					local prefab = v.type
					for i = 1, v.amount do						
						local item = SpawnPrefab(prefab)
						
						--尝试送入物品栏
						if item ~= nil then	
							doer.components.inventory:GiveItem(item)
						end
					end
				end				
			end
			
			--处理储存的物品
			do
				target.wx78_backupbody_inventory.components.inventory:DropEverything()
				target.components.container:DropEverything()
				local items = target.components.socketholder:UnsocketEverything()
				for _, item in ipairs(items) do
					target.components.lootdropper:FlingItem(item)
				end
				local modules = target.components.upgrademoduleowner:PopAllModules()
				for _, onemodule in ipairs(modules) do
					target.components.lootdropper:FlingItem(onemodule)
				end
			end
			
			target:Remove()
			return true
		end
		
		return false
	end

	AddAction(WMB_RECYCLE_BACKUP)
	AddComponentAction("SCENE", "lootdropper", function(inst, doer, actions, right)
		if right and inst.prefab == "wx78_backupbody" and doer:HasTag("player") and doer.prefab ~= "wx78" then
			table.insert(actions, ACTIONS.WMB_RECYCLE_BACKUP)
		end
	end)

	AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_RECYCLE_BACKUP, "dolongaction"))
	AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_RECYCLE_BACKUP, "dolongaction"))

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
						
						--未知原因,备份底盘需要延迟设置才能刷新
						--为了兼容性不再追求视觉效果
						item.components.inventoryitem:SetOwner(target)
						item.Network:SetClassifiedTarget(doer)
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

	local inst = wx.wx78_backupbody_inventory

	if inst then	
		ShowEquipBar(doer, inst)
		
		--兼容来自模组的背包装备栏
		local backpack = GetBackpackOnModSlot(inst)
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
			if backpack.components.container:IsOpenedBy(inst) then
				backpack.components.container:Close(inst)
				inst:PushEvent("closecontainer", { container = backpack })
			end
			if not backpack.components.container:IsOpenedBy(doer) then
				backpack.components.container:Open(doer)
				doer:PushEvent("opencontainer", { container = backpack })
			end
		end	
	end

end

--关闭
local function OnClose(wx, doer)
    if not doer or not doer:HasTag("player") then
        return
    end

	local inst = wx.wx78_backupbody_inventory

	if inst then
		HideEquipBar(doer, inst)
				
		--兼容来自模组的背包装备栏
		local backpack = GetBackpackOnModSlot(inst)
		if backpack ~= nil and backpack.components.container ~= nil then
			if backpack.components.container:IsOpenedBy(doer) then
				backpack.components.container:Close(doer)
				doer:PushEvent("closecontainer", { container = backpack })
			end
			if not backpack.components.container:IsOpenedBy(inst) then
				backpack.components.container:Open(inst)
				inst:PushEvent("opencontainer", { container = backpack })
			end
			backpack.Network:SetClassifiedTarget(inst)
			local playerbackpack = GetBackpackOnBodySlot(doer) or GetBackpackOnModSlot(doer)
			if playerbackpack ~= nil and playerbackpack.components.container ~= nil and
				not playerbackpack.components.container:IsOpenedBy(doer) then
				playerbackpack.components.container:Open(doer)
				doer:PushEvent("opencontainer", { container = playerbackpack })
			end
		end
	end

end

AddPrefabPostInit("wx78_backupbody", function(wx)
	if TheWorld.ismastersim then
	
		--显示装备栏
		if backup_ui then
			local oldfn = wx.components.container.onopenfn or function() end
			wx.components.container.onopenfn = function(...)
				oldfn(...)
				OnOpen(...)
			end
			
			local oldfn = wx.components.container.onclosefn or function() end
			wx.components.container.onclosefn = function(...)
				oldfn(...)
				OnClose(...)
			end
		end
	
		--不能被锤
		if backup_protection then
			wx:RemoveComponent("workable")
		end
		
		--无碰撞体积
		if backup_no_collision then
			wx.Physics:ClearCollisionMask()
		end
		
		--激活空间扩展电路(因为改到伽玛栏了)
		do
			local oldfn = wx.TryToActivateBetaCircuitStates or function() end
			wx.TryToActivateBetaCircuitStates = function(inst, ...)
				oldfn(inst, ...)
				local modules = inst.components.upgrademoduleowner:GetModules(CIRCUIT_BARS.GAMMA)
				for _, mod in ipairs(modules) do
					if mod.prefab == "wx78module_stacksize" then
						mod.components.upgrademodule:TryActivate()
					end
				end
			end
			
			local oldfn = wx.TryToDeactivateBetaCircuitStates or function() end
			wx.TryToDeactivateBetaCircuitStates = function(inst, ...)
				oldfn(inst, ...)
				local modules = inst.components.upgrademoduleowner:GetModules(CIRCUIT_BARS.GAMMA)
				for _, mod in ipairs(modules) do
					if mod.prefab == "wx78module_stacksize" then					
						mod.components.upgrademodule:TryDeactivate()
					end
				end
			end
		end
		
	end
end)


--返还捕获机
if backup_return then

	local function Return(inst)
		if TheWorld.ismastersim then
			if inst.components.useabletargeteditem then
				inst.components.useabletargeteditem.onusefn = function(inst, target, doer)
					if target.TryToSpawnPossessedBody ~= nil and target:HasTag("possessable_chassis") then
						local isplanar = inst.isplanar
						local prefab = "gestalt_cage"
						local fresh = false
					
						--3级返还本身且赋予位面属性,并回满属性
						if inst.prefab == "gestalt_cage_filled3" then
							prefab = "gestalt_cage_filled3"
							isplanar = true
							fresh = true
						end
						target:TryToSpawnPossessedBody(isplanar, fresh)
						
						local x, y, z = target.Transform:GetWorldPosition()
						local item = SpawnPrefab(prefab)
						item.Transform:SetPosition(x, y, z)
					
						--尝试送入物品栏
						if doer and doer.components.inventory then
							doer.components.inventory:GiveItem(item)
						end
					
						inst:Remove()
						
						return true
					end
					
					return false
				end
			end
		end	
	end

	AddPrefabPostInit("gestalt_cage_filled1", Return)
	AddPrefabPostInit("gestalt_cage_filled2", Return)
	AddPrefabPostInit("gestalt_cage_filled3", Return)
end

--修正,不能在打开的时候激活
do
	local TIP = (LANG and "错误：底盘占用中") or "Error: Chasis Occupied"
	STRINGS.CHARACTERS.GENERIC.ACTIONFAIL.USEITEMON.WMB_MOD_CHASIS_OCCUPIED = TIP
	STRINGS.CHARACTERS.WX78.ACTIONFAIL.USEITEMON.WMB_MOD_CHASIS_OCCUPIED = TIP

	local function Fix(inst)
		if TheWorld.ismastersim then
			if inst.components.useabletargeteditem then
				local oldfn = inst.components.useabletargeteditem.onusefn or function() end
				inst.components.useabletargeteditem.onusefn = function(inst, target, doer)
					if target and target.prefab == "wx78_backupbody" then
						if target.components.container and target.components.container:IsOpen() then
							return false, "WMB_MOD_CHASIS_OCCUPIED"
						end
					end
					return oldfn(inst, target, doer)
				end
			end
		end	
	end
	AddPrefabPostInit("gestalt_cage_filled1", Fix)
	AddPrefabPostInit("gestalt_cage_filled2", Fix)
	AddPrefabPostInit("gestalt_cage_filled3", Fix)
end

--快速传输
if GetModConfigData("backup_quick") then

	--移除wx78关机动画
	AddGamePostInit(function()
		local state, WxPowerOver = pcall(require, "widgets/wxpowerover")
		if state then
			function WxPowerOver:PowerOff() end
			function WxPowerOver:Clear() end
		end
	end)

	local function FastTransfer(sg)
		local state = sg.states.wx_poweroff
		if state then
			local oldfn = state.onenter or function() end
			state.onenter = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(4)
			end
			
			local oldfn = state.onexit or function() end
			state.onexit = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end
			
			--加速时间线
			if state.timeline then
				for _,v in ipairs(state.timeline) do
					if v.time then
						v.time = v.time / 4
					end
				end
			end
		end	
	
		local state = sg.states.wx_poweron
		if state then
			local oldfn = state.onenter or function() end
			state.onenter = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(4)
			end
			
			local oldfn = state.onexit or function() end
			state.onexit = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end
			
			--加速时间线
			if state.timeline then
				for _,v in ipairs(state.timeline) do
					if v.time then
						v.time = v.time / 4
					end
				end
			end
		end		
	end

	AddStategraphPostInit("wilson", FastTransfer)

end