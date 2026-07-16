--- Most of this code is from the mod "WX78 Boost" by "wiefean". All credits to them! ^^---

local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local ChassisEquipSlot = require "widgets/chassis_equipslot"

local EquipSlots = {
    {eslot = EQUIPSLOTS.HANDS, image = "equip_slot.tex", pos = Vector3(-(64 + 12), 0, 0)},
    {eslot = EQUIPSLOTS.BODY, image = "equip_slot_body.tex", pos = Vector3(0, 0, 0)},
    {eslot = EQUIPSLOTS.HEAD, image = "equip_slot_head.tex", pos = Vector3(64 + 12, 0, 0)},
}

local ChassisEquipBar = Class(Widget, function(self, owner)
    Widget._ctor(self, "ChassisEquipBar")
    self:SetScale(0.65, 0.65, 0.65)
    self.owner = owner
    self:SetPosition(0, 375, 0)

    self.bganim = self:AddChild(UIAnim())
    self.bganim:GetAnimState():SetBank("ui_chest_3x1")
    self.bganim:GetAnimState():SetBuild("ui_chest_3x1")
    self.bganim:GetAnimState():PlayAnimation("open")

    self.slots = {}
    for _, v in ipairs(EquipSlots) do
        self.slots[v.eslot] = self:AddChild(ChassisEquipSlot(v.eslot, "images/hud.xml", v.image, owner))
        self.slots[v.eslot]:SetPosition(v.pos)
    end
end)

function ChassisEquipBar:Refresh()
    for _, v in pairs(self.slots) do v:Refresh() end
end

return ChassisEquipBar