--机器人装备栏格子

local ItemSlot = require "widgets/itemslot"
local ItemTile = require "widgets/itemtile"

local WMB_EquipSlot = Class(ItemSlot, function(self, eslot, atlas, bgim, owner)
    ItemSlot._ctor(self, atlas, bgim, owner)
    self.owner = owner
    self.eslot = eslot or ""
    self.highlight = false

    self:SetOnTileChangedFn(function(self, tile)
        if tile ~= nil then
            tile:SetIsEquip(true)
        end
    end)
end)

function WMB_EquipSlot:GetTarget()
    local player_classified = self.owner ~= nil and self.owner.player_classified or nil
    return (player_classified ~= nil and player_classified.WMB_EquipBar ~= nil and
        player_classified.WMB_EquipBar["target"] ~= nil and player_classified.WMB_EquipBar["target"]:value()) or nil
end

function WMB_EquipSlot:GetItem()
    local player_classified = self.owner ~= nil and self.owner.player_classified or nil
    return (player_classified ~= nil and player_classified.WMB_EquipBar ~= nil and
        player_classified.WMB_EquipBar[self.eslot] ~= nil and player_classified.WMB_EquipBar[self.eslot]:value()) or nil
end

function WMB_EquipSlot:Refresh()
    local item = self:GetItem()
    if item ~= nil then
        if self.tile == nil or (self.tile.item ~= nil and self.tile.item ~= item) then
            self:SetTile(ItemTile(item))
            self.tile.GetDescriptionString = function(tile)
                return tile.item ~= nil and tile.item:IsValid() and
                    tile.item:GetDisplayName() or ""
            end
        end
    else
        self:SetTile(nil)
    end

    if self.tile ~= nil and self.tile.item ~= nil then
        self.tile:Refresh()
    end
end

function WMB_EquipSlot:Click()
    self:OnControl(CONTROL_ACCEPT, true)
end

function WMB_EquipSlot:OnControl(control, down)
    if self.tile ~= nil then
        self.tile:UpdateTooltip()
    end

    if down then
        local target = self:GetTarget()
        if target == nil or self.owner == nil then
            return false
        end

        local item = self:GetItem()
        if control == CONTROL_ACCEPT then
            local active_item = self.owner.replica.inventory and self.owner.replica.inventory:GetActiveItem() or nil
            if active_item ~= nil and active_item.replica.equippable ~= nil and active_item.replica.equippable:EquipSlot() == self.eslot then
                SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "GiveToWX"), self.owner, target, self.eslot)
                return true
            elseif active_item == nil and item ~= nil then
                SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "TakeFromWX"), self.owner, target, self.eslot)
                return true
            end
        elseif control == CONTROL_SECONDARY and item ~= nil then
            SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "UseWXItem"), self.owner, target, self.eslot)
            return true
        end
    end
end

return WMB_EquipSlot