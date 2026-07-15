--机器人装备栏

local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local WMB_EquipSlot = require "widgets/wmb_equipslot"

local EquipSlots = {
    {eslot = EQUIPSLOTS.HANDS, image = "equip_slot.tex", pos = Vector3(-(64 + 12), 0, 0)},
    {eslot = EQUIPSLOTS.BODY, image = "equip_slot_body.tex", pos = Vector3(0, 0, 0)},
    {eslot = EQUIPSLOTS.HEAD, image = "equip_slot_head.tex", pos = Vector3(64 + 12, 0, 0)},
}

local WMB_EquipBar = Class(Widget, function(self, owner)
    Widget._ctor(self, "WMB_EquipBar")
    local scale = .6
    self:SetScale(scale,scale,scale)
    self.isopen = false
    self.owner = owner
    self:SetPosition(0, -280, 0)

    self.bganim = self:AddChild(UIAnim())
    self.bganim:GetAnimState():SetBank("ui_chest_3x1")
    self.bganim:GetAnimState():SetBuild("ui_chest_3x1")
    self.bganim:GetAnimState():AnimateWhilePaused(false)

    self.slots = {}
    for _, v in ipairs(EquipSlots) do
        local eslot = v.eslot or ""
        self.slots[eslot] = self:AddChild(WMB_EquipSlot(v.eslot, "images/hud.xml", v.image, owner))
        self.slots[eslot]:SetPosition(v.pos)
        self.slots[eslot]:SetPosition(v.pos)
    end
end)

function WMB_EquipBar:Refresh()
    for _, v in pairs(self.slots) do
        v:Refresh()
    end
end

function WMB_EquipBar:Open()
    self:Close()
    self.isopen = true
    self:Refresh()
    self.bganim:GetAnimState():PlayAnimation("open")
    for _, v in pairs(self.slots) do
        v:Show()
    end    
    self:Show()
end

function WMB_EquipBar:Close()
    if self.isopen then
        self.isopen = false
        self.bganim:GetAnimState():PlayAnimation("close")
        for _, v in pairs(self.slots) do
            v:Hide()
        end
        self.inst:DoTaskInTime(0.4, function() if not self.isopen then self:Hide() end end)
    end
end

return WMB_EquipBar