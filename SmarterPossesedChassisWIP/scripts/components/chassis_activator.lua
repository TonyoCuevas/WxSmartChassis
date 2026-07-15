local STANDBY_TAG = "wx78_chassis_standby"

local ChassisActivator = Class(function(self, inst)
    self.inst = inst
end)

-- Busca en el registro global los chasis que sigan específicamente a "doer"
local function GetOwnedChassis(doer)
    local owned = {}

    if WX78_POSSESSEDBODY_REGISTRY == nil then
        return owned
    end

    for ent in pairs(WX78_POSSESSEDBODY_REGISTRY) do
        if ent:IsValid()
            and ent.components.follower ~= nil
            and ent.components.follower:GetLeader() == doer then
            table.insert(owned, ent)
        end
    end

    return owned
end

local function ToggleChassisStandby(chassis)
    local entering_standby = not chassis:HasTag(STANDBY_TAG)

    if entering_standby then
        chassis:AddTag(STANDBY_TAG)
    else
        chassis:RemoveTag(STANDBY_TAG)
        chassis._chassis_sitting = nil
    end

    -- Limpieza de estado transitorio para que no se quede "atascado"
    -- al cambiar de modo (target de combate viejo, acción en curso, etc.)
    if chassis.components.locomotor ~= nil then
        chassis.components.locomotor:Stop()
    end
    if chassis.components.combat ~= nil then
        chassis.components.combat:SetTarget(nil)
    end
    chassis:ClearBufferedAction()
    chassis._last_drone_time = nil

    return entering_standby
end

function ChassisActivator:Activate(doer)
    local chassis_list = GetOwnedChassis(doer)
    print("[ChassisActivator] Activate llamado, chasis encontrados: "..#chassis_list) -- DEBUG

    if #chassis_list == 0 then
        if doer.components.talker ~= nil then
            doer.components.talker:Say("No tengo ningún chasis activo.")
        end
        return false
    end

    local now_in_standby = nil
    for _, chassis in ipairs(chassis_list) do
        now_in_standby = ToggleChassisStandby(chassis)
    end

    if doer.components.talker ~= nil then
        if now_in_standby then
            doer.components.talker:Say("Chasis en standby.")
        else
            doer.components.talker:Say("Chasis reactivado.")
        end
    end

    return true
end

return ChassisActivator