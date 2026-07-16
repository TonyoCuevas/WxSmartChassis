local STANDBY_TAG = "wx78_chassis_standby"
GLOBAL.WX78_POSSESSEDBODY_REGISTRY = {}
local PossessedBodyRegistry = GLOBAL.WX78_POSSESSEDBODY_REGISTRY
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS

--------------------------------------------------------------------------------------------------
-- GESTALTTRAPPER: Now can toggle a standby/follow mode for possesedchassis.
--------------------------------------------------------------------------------------------------
local STRINGS = GLOBAL.STRINGS
STRINGS.ACTIONS.USEITEMON.WX78_CHASSIS_STANDBY = "Standby"
STRINGS.ACTIONS.USEITEMON.WX78_CHASSIS_FOLLOW = "Follow"

local function GetUseItemOnVerb(inst, target, doer)
    if target ~= nil and target ~= doer then return nil end

    for ent in pairs(GLOBAL.WX78_POSSESSEDBODY_REGISTRY) do
        if ent:IsValid() and ent:HasTag(STANDBY_TAG) then
            -- replica.follower for multiplayer
            local leader = ent.replica.follower ~= nil and ent.replica.follower:GetLeader() or nil
            if leader == doer then
                return "WX78_CHASSIS_FOLLOW"
            end
        end
    end
    return "WX78_CHASSIS_STANDBY"
end

AddPrefabPostInit("wx78_gestalttrapper", function(inst)
    inst:AddTag("useabletargateditem_canselftarget")
    inst:AddTag("wx78_targeter")
    inst.GetUseItemOnVerb = GetUseItemOnVerb

    if not GLOBAL.TheWorld.ismastersim then return end

    inst:AddComponent("chassis_activator")
    local useabletargeteditem = inst.components.useabletargeteditem
    if useabletargeteditem ~= nil then
        useabletargeteditem:SetUsingItemDoesNotToggleUseability(true)
        local previous_onusefn = useabletargeteditem.onusefn

        useabletargeteditem:SetOnUseFn(function(useinst, target, doer, ...)
            if target == doer and useinst.components.chassis_activator ~= nil then
                
                -- 1. Check group state before activating to avoid desync
                local group_in_standby = false
                local my_chassis = {}
                for ent in pairs(GLOBAL.WX78_POSSESSEDBODY_REGISTRY) do
                    if ent:IsValid() and ent.components.follower and ent.components.follower:GetLeader() == doer then
                        table.insert(my_chassis, ent)
                        if ent:HasTag(STANDBY_TAG) then
                            group_in_standby = true
                        end
                    end
                end

                -- 2. Activate the function
                local result = useinst.components.chassis_activator:Activate(doer)

                -- 3. Force the sync of state to all chassis
                local target_standby = not group_in_standby
                for _, ent in ipairs(my_chassis) do
                    if target_standby then
                        ent:AddTag(STANDBY_TAG)
                    else
                        ent:RemoveTag(STANDBY_TAG)
                    end
                end

                return result
            end
            if previous_onusefn ~= nil then return previous_onusefn(useinst, target, doer, ...) end
        end)
    end
end)

--------------------------------------------------------------------------------------------------
-- EQUIPMENT SLOTS --- Most of this code is from the mod "WX78 Boost" by "wiefean". All credits to them! ^^---
--------------------------------------------------------------------------------------------------
local ChassisEquipBar = require("widgets/chassis_equipbar")

AddClassPostConstruct("screens/playerhud", function(self)
    self.ShowChassisEquipBar = function(self)
        if self.controls.containerroot.ChassisEquipBarUI == nil then
            self.controls.containerroot.ChassisEquipBarUI = self.controls.containerroot:AddChild(ChassisEquipBar(self.owner))
            self.controls.containerroot.ChassisEquipBarUI:MoveToBack()
        end
        if self.controls.containerroot.ChassisEquipBarUI ~= nil then
            self.controls.containerroot.ChassisEquipBarUI:Show()
            self.controls.containerroot.ChassisEquipBarUI:Refresh()
        end
    end

    self.HideChassisEquipBar = function(self)
        if self.controls.containerroot.ChassisEquipBarUI ~= nil then
            self.controls.containerroot.ChassisEquipBarUI:Hide()
        end
    end
    
    self.RefreshChassisEquipBar = function(self)
        if self.controls.containerroot.ChassisEquipBarUI ~= nil then
            self.controls.containerroot.ChassisEquipBarUI:Refresh()
        end
    end
end)

AddPrefabPostInit("player_classified", function(inst)
    inst.chassis_isvisible = GLOBAL.net_bool(inst.GUID, "chassis_isvisible", "chassis_isvisible_dirty")
    inst.chassis_isvisible:set(false)
    inst.chassis_target = GLOBAL.net_entity(inst.GUID, "chassis_target", "chassis_target_dirty")
    inst.chassis_target:set(nil)

    inst.chassis_equip = {}
    for _, eslot in pairs({EQUIPSLOTS.HANDS, EQUIPSLOTS.BODY, EQUIPSLOTS.HEAD}) do
        inst.chassis_equip[eslot] = GLOBAL.net_entity(inst.GUID, "chassis_equip_"..eslot, "chassis_equip_"..eslot.."_dirty")
        inst.chassis_equip[eslot]:set(nil)
    end

    inst:DoTaskInTime(0, function(inst)
        if GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.player_classified == inst then
            inst._parent = inst._parent or inst.entity:GetParent()

            inst:ListenForEvent("chassis_isvisible_dirty", function(inst)
                if inst._parent and inst._parent.HUD then
                    if inst.chassis_isvisible ~= nil and inst.chassis_isvisible:value() then
                        inst._parent.HUD:ShowChassisEquipBar()
                    elseif inst.chassis_isvisible ~= nil and not inst.chassis_isvisible:value() then
                        inst._parent.HUD:HideChassisEquipBar()
                    end
                end
            end)

            for _, eslot in pairs({EQUIPSLOTS.HANDS, EQUIPSLOTS.BODY, EQUIPSLOTS.HEAD}) do
                inst:ListenForEvent("chassis_equip_"..eslot.."_dirty", function(inst)
                    if inst._parent ~= nil and inst._parent.HUD ~= nil then
                        inst._parent.HUD:RefreshChassisEquipBar()
                    end    
                end)
            end
        end
    end)
end)

--------------------------------------------------------------------------------------------------
-- SERVER FUNCTIONS --- Most of this code is from the mod "WX78 Boost" by "wiefean". All credits to them! ^^---
--------------------------------------------------------------------------------------------------
local EQUIP_SLOTS_LIST = { EQUIPSLOTS.HANDS, EQUIPSLOTS.BODY, EQUIPSLOTS.HEAD }

local function OnWXEquipedFn(doer, target, data)
    if doer.player_classified ~= nil and doer.player_classified.chassis_equip ~= nil and doer.player_classified.chassis_equip[data.eslot] then
        if data.item and data.item.Network ~= nil then
            data.item.Network:SetClassifiedTarget(doer)
        end
        doer.player_classified.chassis_equip[data.eslot]:set(data.item)
    end
end

local function OnWXUnequipedFn(doer, target, data)
    if doer.player_classified ~= nil and doer.player_classified.chassis_equip ~= nil and doer.player_classified.chassis_equip[data.eslot] then
        if data.item and data.item.Network ~= nil then
            data.item.Network:SetClassifiedTarget(nil)
        end
        doer.player_classified.chassis_equip[data.eslot]:set(nil)
    end
end

local function ShowEquipBar(doer, target)
    if not doer.player_classified then return end

    doer.player_classified.chassis_isvisible:set(true)
    doer.player_classified.chassis_target:set(target)

    if target.replica.inventory ~= nil and target.replica.inventory.classified ~= nil then
        target.replica.inventory.classified.Network:SetClassifiedTarget(doer)
    end

    for _, eslot in ipairs({GLOBAL.EQUIPSLOTS.HANDS, GLOBAL.EQUIPSLOTS.BODY, GLOBAL.EQUIPSLOTS.HEAD}) do
        local item = target.components.inventory:GetEquippedItem(eslot)
        doer.player_classified.chassis_equip[eslot]:set(item)

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

            item.components.inventoryitem:SetOwner(target)
            
            if item.Network then
                item.Network:SetClassifiedTarget(doer)
            end
            if item.replica.inventoryitem and item.replica.inventoryitem.classified then
                item.replica.inventoryitem.classified.Network:SetClassifiedTarget(doer)
            end
        end
    end

    if doer.ChassisEquipEvent == nil then
        doer.ChassisEquipEvent = function(owner, data)
            if doer.player_classified then 
                doer.player_classified.chassis_equip[data.eslot]:set(data.item)
                if data.item and data.item.Network then
                    data.item.Network:SetClassifiedTarget(doer)
                end
                if data.item and data.item.replica.inventoryitem and data.item.replica.inventoryitem.classified then
                    data.item.replica.inventoryitem.classified.Network:SetClassifiedTarget(doer)
                end
            end
        end
        doer.ChassisUnequipEvent = function(owner, data)
            if doer.player_classified then doer.player_classified.chassis_equip[data.eslot]:set(nil) end
        end
    end

    doer:ListenForEvent("equip", doer.ChassisEquipEvent, target)
    doer:ListenForEvent("unequip", doer.ChassisUnequipEvent, target)
end

local function HideEquipBar(doer, target)
    if not doer.player_classified then return end

    doer.player_classified.chassis_isvisible:set(false)
    doer.player_classified.chassis_target:set(nil)

    if target.replica.inventory ~= nil and target.replica.inventory.classified ~= nil then
        target.replica.inventory.classified.Network:SetClassifiedTarget(target.replica.inventory.classified)
    end

    for _, eslot in ipairs({GLOBAL.EQUIPSLOTS.HANDS, GLOBAL.EQUIPSLOTS.BODY, GLOBAL.EQUIPSLOTS.HEAD}) do
        local item = target.components.inventory:GetEquippedItem(eslot)
        if item ~= nil and item.components.inventoryitem ~= nil then
            item.components.inventoryitem:SetOwner(target)
        end
        doer.player_classified.chassis_equip[eslot]:set(nil)
    end

    if doer.ChassisEquipEvent ~= nil then
        doer:RemoveEventCallback("equip", doer.ChassisEquipEvent, target)
        doer:RemoveEventCallback("unequip", doer.ChassisUnequipEvent, target)
    end
end

--------------------------------------------------------------------------------------------------
-- INYECTION TO BODIES --- Most of this code is from the mod "WX78 Boost" by "wiefean". All credits to them! ^^---
--------------------------------------------------------------------------------------------------
AddPrefabPostInit("wx78_backupbody", function(wx)
    if not GLOBAL.TheWorld.ismastersim then return end

    wx:DoTaskInTime(0, function()
        if wx.components.container then
            local old_open = wx.components.container.onopenfn
            wx.components.container.onopenfn = function(inst, data)
                if old_open then old_open(inst, data) end
                local doer = data and data.doer
                if doer and doer:HasTag("player") then
                    local inv = wx.wx78_backupbody_inventory
                    if inv then ShowEquipBar(doer, inv) end
                end
            end
            
            local old_close = wx.components.container.onclosefn
            wx.components.container.onclosefn = function(inst, doer)
                if old_close then old_close(inst, doer) end
                if doer and doer:HasTag("player") then
                    local inv = wx.wx78_backupbody_inventory
                    if inv then HideEquipBar(doer, inv) end
                end
            end
        end
    end)
end)

AddPrefabPostInit("wx78_possessedbody", function(inst)
    GLOBAL.WX78_POSSESSEDBODY_REGISTRY[inst] = true
    inst:ListenForEvent("onremove", function()
        GLOBAL.WX78_POSSESSEDBODY_REGISTRY[inst] = nil
    end)

    if not GLOBAL.TheWorld.ismastersim then
        local oldfn = inst.OnEntityReplicated or function() end
        inst.OnEntityReplicated = function(wx)
            if wx.replica.container then			
                wx.replica.container:WidgetSetup("wx78_backupbody")
            end
            oldfn(wx)
        end
        return
    end

    -- SYNC AT BORN CHASSIS
    -- If new chassis is possesed, it checks the group state and copy it.
    inst:ListenForEvent("startfollowing", function(inst, data)
        local leader = data and data.leader or (inst.components.follower and inst.components.follower:GetLeader())
        if leader then
            local group_in_standby = false
            for ent in pairs(GLOBAL.WX78_POSSESSEDBODY_REGISTRY) do
                if ent ~= inst and ent:IsValid() and ent:HasTag(STANDBY_TAG) then
                    local ent_leader = ent.components.follower and ent.components.follower:GetLeader()
                    if ent_leader == leader then
                        group_in_standby = true
                        break
                    end
                end
            end

            if group_in_standby then
                inst:AddTag(STANDBY_TAG)
            else
                inst:RemoveTag(STANDBY_TAG)
            end
        end
    end)

    -- Modded Brain
    local ModdedBrain = require("brains/wx78_possessedbodybrain_modded")
    inst:SetBrain(ModdedBrain)

    -- AGGRO: grace period
    local GRACE_PERIOD = 1.0
    local grace_task = nil
    local current_boss = nil

    local function RemoveGrace()
        grace_task = nil
        if current_boss ~= nil and current_boss:IsValid() and current_boss.components.combat ~= nil then
            current_boss.components.combat:RemoveShouldAvoidAggro(inst)
        end
        current_boss = nil
    end

    local function ApplyGrace(boss)
        if current_boss ~= nil and current_boss ~= boss then
            if current_boss:IsValid() and current_boss.components.combat ~= nil then
                current_boss.components.combat:RemoveShouldAvoidAggro(inst)
            end
        end
        current_boss = boss
        if boss.components.combat ~= nil then
            boss.components.combat:SetShouldAvoidAggro(inst)
        end
        if grace_task ~= nil then grace_task:Cancel() end
        grace_task = inst:DoTaskInTime(GRACE_PERIOD, RemoveGrace)
    end

    inst:DoPeriodicTask(0.1, function()
        local leader = inst.components.follower and inst.components.follower:GetLeader()
        if leader == nil or not leader:IsValid() then return end
        local leader_target = leader.components.combat and leader.components.combat.target
        if leader_target ~= nil and leader_target:IsValid() and leader_target:HasTag("epic") and leader_target.components.combat ~= nil then
            ApplyGrace(leader_target)
        end
    end)

    inst:ListenForEvent("death", function()
        if grace_task ~= nil then grace_task:Cancel() end
        RemoveGrace()
    end)

    -- UI in possesedbody
    if inst.components.container_transform then
        inst.components.container_transform:SetOnTransform(function(ent) return ent end)
    end
    if inst.components.inventory then
        inst.components.inventory.maxslots = 15
    end
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("wx78_backupbody")
    inst.components.container.slots = inst.components.inventory.itemslots
    inst.components.container.OnSave = function() return {items = {}}, {} end

    inst.components.container.onopenfn = function(wx, data)
        local doer = data and data.doer
        if doer and doer:HasTag("player") then
            wx.brain:Pause()
            wx.components.locomotor:Stop()
            ShowEquipBar(doer, wx)
        end
    end

    inst.components.container.onclosefn = function(wx, doer)
        if doer and doer:HasTag("player") then
            wx.brain.bt:Reset()
            wx.brain:Resume()
            HideEquipBar(doer, wx)
        end
    end
end)

--------------------------------------------------------------------------------------------------
-- RPCS --- Most of this code is from the mod "WX78 Boost" by "wiefean". All credits to them! ^^---
--------------------------------------------------------------------------------------------------
AddModRPCHandler("ChassisRPC", "EquipItem", function(player, target, eslot)
    if not target or not target.components.inventory then return end
    local active_item = player.components.inventory:GetActiveItem()
    
    if active_item and active_item.components.equippable and not active_item.components.equippable:IsRestricted(target) then
        local equipped_item = target.components.inventory:GetEquippedItem(eslot)
        if equipped_item then
            local item = target.components.inventory:RemoveItem(equipped_item, true)
            if item then player.components.inventory:GiveActiveItem(item) end
        end
        target.components.inventory:Equip(active_item)
        player.components.inventory:ReturnActiveItem()
    end
end)

AddModRPCHandler("ChassisRPC", "UnequipItem", function(player, target, eslot)
    if not target or not target.components.inventory then return end
    local equipped_item = target.components.inventory:GetEquippedItem(eslot)
    if equipped_item then
        local item = target.components.inventory:RemoveItem(equipped_item, true)
        if item then player.components.inventory:GiveActiveItem(item) end
    end
end)

AddModRPCHandler("ChassisRPC", "UseItem", function(player, target, eslot)
    if not target or not target.components.inventory then return end
    local equipped_item = target.components.inventory:GetEquippedItem(eslot)
    if equipped_item then
        if equipped_item.components.container then
            if equipped_item.components.container:IsOpenedBy(player) then
                equipped_item.components.container:Close(player)
            else
                equipped_item.components.container:Open(player)
                player:PushEvent("opencontainer", { container = equipped_item })
            end
        else
            local parent = target.entity:GetParent()
            if parent ~= nil and parent.prefab == "wx78_backupbody" and parent.components.container then
                if not parent.components.container:IsFull() then
                    local item = target.components.inventory:RemoveItem(equipped_item, true)
                    if item then parent.components.container:GiveItem(item) end
                else
                    target.components.inventory:DropItem(equipped_item, true, true)
                end
            else
                if not target.components.inventory:IsFull() then
                    local item = target.components.inventory:Unequip(eslot)
                    if item then target.components.inventory:GiveItem(item) end
                else
                    target.components.inventory:DropItem(equipped_item, true, true)
                end
            end
        end
    end
end)