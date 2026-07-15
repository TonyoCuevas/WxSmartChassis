local STANDBY_TAG = "wx78_chassis_standby"
GLOBAL.WX78_POSSESSEDBODY_REGISTRY = {}
local PossessedBodyRegistry = GLOBAL.WX78_POSSESSEDBODY_REGISTRY

--------------------------------------------------------------------------------------------------
-- GESTALTTRAPPER: click derecho (auto-uso) alterna el standby de los chasis poseídos.
--------------------------------------------------------------------------------------------------

local STRINGS = GLOBAL.STRINGS
STRINGS.ACTIONS.USEITEMON.WX78_CHASSIS_STANDBY = "Standby"
STRINGS.ACTIONS.USEITEMON.WX78_CHASSIS_FOLLOW = "Seguir"

-- Corre tanto en cliente como en servidor (es solo para el texto del tooltip),
-- así que solo usamos tags, nunca .components
local function GetUseItemOnVerb(inst, target, doer)
    if target ~= nil and target ~= doer then
        return nil
    end

    for ent in pairs(GLOBAL.WX78_POSSESSEDBODY_REGISTRY) do
        if ent:IsValid() and ent:HasTag(STANDBY_TAG) then
            return "WX78_CHASSIS_FOLLOW"
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
            print("[ChassisActivator] onusefn llamado, target==doer: "..tostring(target == doer)) -- DEBUG, quitar luego
            if target == doer and useinst.components.chassis_activator ~= nil then
                return useinst.components.chassis_activator:Activate(doer)
            end
            if previous_onusefn ~= nil then
                return previous_onusefn(useinst, target, doer, ...)
            end
        end)
    end
end)

--------------------------------------------------------------------------------------------------

-- ========================================================
-- SISTEMA DE INTERFAZ Y RED (SKINS Y DURABILIDAD)
-- ========================================================
local EQUIP_SLOTS_LIST = { GLOBAL.EQUIPSLOTS.HANDS, GLOBAL.EQUIPSLOTS.BODY, GLOBAL.EQUIPSLOTS.HEAD }

local function GetChassisEquipOwner(inst)
    if inst.prefab ~= "wx78_backupbody" then return inst end
    if inst.wx78_backupbody_inventory ~= nil and inst.wx78_backupbody_inventory:IsValid() then
        return inst.wx78_backupbody_inventory
    end
    for _, child_ent in ipairs(inst.entity:GetChildren()) do
        local guid = child_ent:GetGUID()
        local child = guid ~= nil and GLOBAL.Ents[guid] or nil
        if child ~= nil and child.prefab == "wx78_backupbody_inventory" then
            inst.wx78_backupbody_inventory = child
            return child
        end
    end
    return nil
end

local function ShowEquipBar(doer, target)
    if not doer.player_classified then return end

    -- Autorizamos al cliente para ver este inventario
    if target.replica.inventory ~= nil then
        target.replica.inventory:AttachClassified(doer)
    end

    doer.player_classified.chassis_isvisible:set(true)
    doer.player_classified.chassis_target:set(target)

    for _, eslot in ipairs(EQUIP_SLOTS_LIST) do
        local item = target.components.inventory:GetEquippedItem(eslot)
        doer.player_classified.chassis_equip[eslot]:set(item)
        
        -- ESTO ES LO QUE TE FALTA: Forzar la red de cada item individualmente
        if item and item.replica.inventoryitem then
            item.replica.inventoryitem:SetOwner(doer) 
            -- Forzamos al cliente a procesar el cambio de skin/durabilidad
            item:PushEvent("percentusedchange", {percent = item.replica.inventoryitem:GetPercent() or 1})
        end
    end
end

local function HideEquipBar(doer, target)
    if not doer.player_classified then return end

    if target.replica.inventory ~= nil and target.replica.inventory.classified ~= nil then
        target.replica.inventory.classified.Network:SetClassifiedTarget(target.replica.inventory.classified)
    end

    doer.player_classified.chassis_isvisible:set(false)
    doer.player_classified.chassis_target:set(nil)
    
    for _, eslot in ipairs(EQUIP_SLOTS_LIST) do
        local item = target.components.inventory:GetEquippedItem(eslot)
        if item and item.replica.inventoryitem and item.replica.inventoryitem.classified then
            item.replica.inventoryitem.classified.Network:SetClassifiedTarget(item.replica.inventoryitem.classified)
        end
        doer.player_classified.chassis_equip[eslot]:set(nil)
    end
    
    if doer.ChassisEquipEvent then
        doer:RemoveEventCallback("equip", doer.ChassisEquipEvent, target)
        doer:RemoveEventCallback("unequip", doer.ChassisUnequipEvent, target)
    end
end

-- ========================================================
-- FUNCIONES HOOK (Ahora definidas ANTES de usarse)
-- ========================================================
local function HookChassisContainer(inst)
    if not GLOBAL.TheWorld.ismastersim then return end
    inst:DoTaskInTime(0, function()
        if inst.components.container == nil then return end

        local previous_onanyopenfn = inst.components.container.onanyopenfn
        local previous_onanyclosefn = inst.components.container.onanyclosefn

        inst.components.container.onanyopenfn = function(container_inst, data)
            if previous_onanyopenfn ~= nil then previous_onanyopenfn(container_inst, data) end
            if data and data.doer then
                local equip_owner = GetChassisEquipOwner(inst)
                if equip_owner then 
                    -- ESTA LÍNEA ES EL CLAVE:
                    -- El possessedbody debe "avisar" a su inventario de que debe replicarse al jugador
                    if equip_owner.replica.inventory and equip_owner.replica.inventory.classified then
                        equip_owner.replica.inventory.classified.Network:SetClassifiedTarget(data.doer)
                    end
                    ShowEquipBar(data.doer, equip_owner) 
                end
            end
        end

        inst.components.container.onanyclosefn = function(container_inst, data)
            if previous_onanyclosefn ~= nil then previous_onanyclosefn(container_inst, data) end
            if data and data.doer then
                local equip_owner = GetChassisEquipOwner(inst)
                if equip_owner then HideEquipBar(data.doer, equip_owner) end
            end
        end
    end)
end

-- ========================================================
-- INYECCIÓN EN LOS CUERPOS (Chassis y Possessed)
-- ========================================================

AddPrefabPostInit("wx78_backupbody", HookChassisContainer)

AddPrefabPostInit("wx78_possessedbody", function(inst)
    -- ========================================================
    -- 1. REGISTRO Y CEREBRO ORIGINAL
    -- ========================================================
    GLOBAL.WX78_POSSESSEDBODY_REGISTRY[inst] = true
    inst:ListenForEvent("onremove", function()
        GLOBAL.WX78_POSSESSEDBODY_REGISTRY[inst] = nil
    end)

    -- Configuración de réplica de red
    local oldfn = inst.OnEntityReplicated or function() end
    inst.OnEntityReplicated = function(inst_rep)
        if inst_rep.replica.container then			
            inst_rep.replica.container:WidgetSetup("wx78_backupbody")
        end
        oldfn(inst_rep)
    end

    if not GLOBAL.TheWorld.ismastersim then return end

    local ModdedBrain = require("brains/wx78_possessedbodybrain_modded")
    inst:SetBrain(ModdedBrain)

    -- ========================================================
    -- 2. LÓGICA DE AGGRO (Grace Period)
    -- ========================================================
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

    -- ========================================================
    -- 3. INTEGRACIÓN CONTENEDOR Y UI
    -- ========================================================
    inst:AddTag("inventoryprovider")
    
    if inst.components.container_transform then
        inst.components.container_transform:SetOnTransform(function(ent) return ent end)
    end
    
    if inst.components.inventory then 
        inst.components.inventory.maxslots = 15 
    end
    
    if not inst.components.container then
        inst:AddComponent("container")
        inst.components.container:WidgetSetup("wx78_backupbody")
        inst.components.container.slots = inst.components.inventory.itemslots
        inst.components.container.OnSave = function() return {}, {} end
    end
    
    -- Usamos la función HookChassisContainer que definimos globalmente en modmain
    HookChassisContainer(inst)
end)

------------------------------------------------------------------------------------------------

-- ========================================================
-- RPCs PARA GESTIONAR EL EQUIPAMIENTO
-- ========================================================
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
        player.components.inventory:ReturnActiveItem() -- Si sobró algo en el cursor
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
        -- Si es una mochila, la abre o cierra
        if equipped_item.components.container then
            if equipped_item.components.container:IsOpenedBy(player) then
                equipped_item.components.container:Close(player)
            else
                equipped_item.components.container:Open(player)
                player:PushEvent("opencontainer", { container = equipped_item })
            end
        else
            -- Si es un item normal, lo devuelve a su inventario
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

-- ========================================================
-- VARIABLES DE RED Y HUD
-- ========================================================
local EQUIP_SLOTS_LIST = { GLOBAL.EQUIPSLOTS.HANDS, GLOBAL.EQUIPSLOTS.BODY, GLOBAL.EQUIPSLOTS.HEAD }

AddPrefabPostInit("player_classified", function(inst)
    inst.chassis_isvisible = GLOBAL.net_bool(inst.GUID, "chassis.isvisible", "chassis.isvisible.dirty")
    inst.chassis_target = GLOBAL.net_entity(inst.GUID, "chassis.target", "chassis.target.dirty")
    
    inst.chassis_equip = {}
    for _, eslot in pairs(EQUIP_SLOTS_LIST) do
        inst.chassis_equip[eslot] = GLOBAL.net_entity(inst.GUID, "chassis."..eslot, "chassis."..eslot..".dirty")
    end

    inst:DoTaskInTime(0, function(inst)
        if GLOBAL.ThePlayer and GLOBAL.ThePlayer.player_classified == inst then
            inst._parent = inst.entity:GetParent()

            -- Mostrar/Ocultar la barra
            inst:ListenForEvent("chassis.isvisible.dirty", function()
                if inst._parent and inst._parent.HUD then
                    if inst.chassis_isvisible:value() then
                        if not inst._parent.HUD.ChassisEquipBarUI then
                            local ChassisEquipBar = require("widgets/chassis_equipbar")
                            inst._parent.HUD.ChassisEquipBarUI = inst._parent.HUD.controls.containerroot:AddChild(ChassisEquipBar(inst._parent))
                            inst._parent.HUD.ChassisEquipBarUI:MoveToBack()
                        end
                        inst._parent.HUD.ChassisEquipBarUI:Show()
                        inst._parent.HUD.ChassisEquipBarUI:Refresh()
                    elseif inst._parent.HUD.ChassisEquipBarUI then
                        inst._parent.HUD.ChassisEquipBarUI:Hide()
                    end
                end
            end)

            -- Refrescar al cambiar items
            for _, eslot in pairs(EQUIP_SLOTS_LIST) do
                inst:ListenForEvent("chassis."..eslot..".dirty", function()
                    if inst._parent and inst._parent.HUD and inst._parent.HUD.ChassisEquipBarUI then
                        inst._parent.HUD.ChassisEquipBarUI:Refresh()
                    end
                end)
            end
        end
    end)
end)