local ItemSlot = require "widgets/itemslot"
local ItemTile = require "widgets/itemtile"

local ChassisEquipSlot = Class(ItemSlot, function(self, eslot, atlas, bgim, owner)
    ItemSlot._ctor(self, atlas, bgim, owner)
    self.owner = owner
    self.eslot = eslot or ""
    self:SetOnTileChangedFn(function(self, tile)
        if tile ~= nil then tile:SetIsEquip(true) end
    end)
end)

function ChassisEquipSlot:GetTarget()
    local classified = self.owner ~= nil and self.owner.player_classified or nil
    return (classified ~= nil and classified.chassis_target ~= nil and classified.chassis_target:value()) or nil
end

function ChassisEquipSlot:GetItem()
    local classified = self.owner ~= nil and self.owner.player_classified or nil
    return (classified ~= nil and classified.chassis_equip[self.eslot] ~= nil and classified.chassis_equip[self.eslot]:value()) or nil
end

function ChassisEquipSlot:Refresh()
    local item = self:GetItem()
    if item ~= nil then
        if self.tile == nil or (self.tile.item ~= nil and self.tile.item ~= item) then
            self:SetTile(ItemTile(item))
            self.tile.GetDescriptionString = function(tile)
                return tile.item ~= nil and tile.item:IsValid() and tile.item:GetDisplayName() or ""
            end
        end
    else
        self:SetTile(nil)
    end
    if self.tile ~= nil and self.tile.item ~= nil then
        self.tile:Refresh()
    end
end

-- FIX 1: Esta función es vital para que el juego detecte los clicks del ratón
function ChassisEquipSlot:Click()
    self:OnControl(CONTROL_ACCEPT, true)
end

function ChassisEquipSlot:OnControl(control, down)
    if self.tile ~= nil then self.tile:UpdateTooltip() end
    if down then
        local target = self:GetTarget()
        if target == nil or self.owner == nil then return false end
        local item = self:GetItem()

        if control == CONTROL_ACCEPT then
            local active_item = self.owner.replica.inventory and self.owner.replica.inventory:GetActiveItem() or nil
            if active_item ~= nil and active_item.replica.equippable ~= nil and active_item.replica.equippable:EquipSlot() == self.eslot then
                SendModRPCToServer(GetModRPC("ChassisRPC", "EquipItem"), target, self.eslot)
                return true
            elseif active_item == nil and item ~= nil then
                SendModRPCToServer(GetModRPC("ChassisRPC", "UnequipItem"), target, self.eslot)
                return true
            end
        elseif control == CONTROL_SECONDARY and item ~= nil then
            -- FIX 1: Soporte para click derecho (usar items equipados o quitarlos rápido)
            SendModRPCToServer(GetModRPC("ChassisRPC", "UseItem"), target, self.eslot)
            return true
        end
    end
end

return ChassisEquipSlot