--热能电路

local LANG = GetModConfigData("language")

local heatFreezeImmune = GetModConfigData("heat_freezeimmune")
local heatWaterProof = GetModConfigData("heat_waterproof")
local heatCooker = GetModConfigData("heat_cooker")

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_heat_tag = net_bool(inst.GUID, "WMB_heat_tag", "WMB_heat_tag.dirty")
	inst.WMB_heat_tag:set(false)
end)
AddPrefabPostInit("wx78_classified", function(inst)
	inst.WMB_heat_tag = net_bool(inst.GUID, "WMB_heat_tag", "WMB_heat_tag.dirty")
	inst.WMB_heat_tag:set(false)
end)

local function SetHeatModu(wx, bool)
	if wx.player_classified and wx.player_classified.WMB_heat_tag then
		wx.player_classified.WMB_heat_tag:set(bool)
	end
	if wx.wx78_classified and wx.wx78_classified.WMB_heat_tag then
		wx.wx78_classified.WMB_heat_tag:set(bool)
	end
end

local function HasHeatModu(wx)
	if wx.player_classified
		and wx.player_classified.WMB_heat_tag
		and wx.player_classified.WMB_heat_tag:value()
	then
		return true
	end
	
	if wx.wx78_classified
		and wx.wx78_classified.WMB_heat_tag
		and wx.wx78_classified.WMB_heat_tag:value()
	then
		return true
	end
	
	return false
end

--热能电路冰冻不掉电
if heatFreezeImmune then

local function fn(wx)
	if not TheWorld.ismastersim then return wx end
    if wx.components.freezable then
		local oldonfreeze = wx.components.freezable.onfreezefn
		wx.components.freezable.onfreezefn = function(inst)
			if wx.components.freezable and wx.WMB_heatnum and wx.WMB_heatnum > 0 then
				--wx.components.freezable:Unfreeze()
			else
				oldonfreeze(inst)
			end
		end
    end
end
AddPrefabPostInit("wx78", fn)
AddPrefabPostInit("wx", fn) --WX自动化兼容


--不进入冰冻状态
local function CheckHeatModu(sg)
	if sg.events and sg.events.freeze then
		local oldfn = sg.events.freeze.fn
		sg.events.freeze.fn = function(inst, ...)
			if HasHeatModu(inst) or inst:HasTag("playerghost") then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
	end
end
AddStategraphPostInit("wilson", CheckHeatModu)
AddStategraphPostInit("wilson_client", CheckHeatModu)
AddStategraphPostInit("wx", CheckHeatModu) --WX自动化兼容


--不累积冰冻层数
AddComponentPostInit("freezable", function(Freezable)
	local oldfn = Freezable.AddColdness
	function Freezable:AddColdness(...)
		local inst = self.inst
		if HasHeatModu(inst) then
			self.coldness = 0
			return
		elseif oldfn then
			return oldfn(self, ...)
		end
	end
end)

end



--热能电路激活
local function heat_activate(modu, wx)
	wx.WMB_heatnum = (wx.WMB_heatnum or 0) + 1

	--潮湿免疫
	if heatWaterProof and wx.components.moisture then
		local oldLevel = wx.components.moisture.moisture or 0
		wx.components.moisture.moisture = 0
		wx:PushEvent("moisturedelta", { old = oldLevel, new = 0 })
		wx.components.moisture.waterproofnessmodifiers:SetModifier(modu, 78, "WMB_heatwarterproof")
	end
	
	SetHeatModu(wx, true)
end

--热能电路关闭
local function heat_deactivate(modu, wx)
	wx.WMB_heatnum = math.max(0, (wx.WMB_heatnum or 0) - 1)

	--取消潮湿免疫和可烹饪
	if wx.WMB_heatnum <= 0 then
		if wx.components.moisture then
			wx.components.moisture.waterproofnessmodifiers:SetModifier(modu, 0, "WMB_heatwarterproof")
		end		
		SetHeatModu(wx, false)
	end
end

--热能电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "heat" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			heat_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			heat_deactivate(modu, wx)
		end
	end
end

--更进一步的免疫潮湿
if heatWaterProof then

AddPlayerPostInit(function(wx)
	if not TheWorld.ismastersim then return wx end
	if wx.components.moisture then
		local oldfn = wx.components.moisture.DoDelta
		function wx.components.moisture:DoDelta(num, ...)
			if HasHeatModu(wx) and num > 0 then
				num = 0
				self.moisture = 0
			end
			return oldfn(self, num, ...)
		end
	end
end)

end

-- AddPrefabPostInit("wx78module_heat", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- heat_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- heat_deactivate(modu, wx)
		-- end
    -- end
-- end)

--是否能烹饪
local function CanCook(item)
    return item ~= nil
        and item.components.cookable ~= nil
        and not (item.components.projectile ~= nil and item.components.projectile:IsThrown())
end

--烹饪
local function CookItem(item, wx)
    if CanCook(item) then
        local newitem = item.components.cookable:Cook(wx, wx)
        ProfileStatsAdd("cooked_"..item.prefab)

        if wx.SoundEmitter ~= nil then
            wx.SoundEmitter:PlaySound("dontstarve/wilson/cook")
        end

        item:Remove()
		
        return newitem
    end
end


--右键烹饪动作注册
local WMB_COOK = Action({priority = 3, mount_valid = true})
WMB_COOK.id = "WMB_COOK"
WMB_COOK.str = (LANG and "烹饪") or "Cook"
WMB_COOK.fn = function(act)
	local target = act.target or act.invobject
	if target == nil or act.doer == nil then return false end

	local cook_pos = act.doer:GetPosition()
	local ingredient = act.doer.components.inventory:RemoveItem(target)
	ingredient.Transform:SetPosition(cook_pos:Get())

	if not CanCook(ingredient) then
		act.doer.components.inventory:GiveItem(ingredient, nil, cook_pos)
		return false
	end

	if ingredient.components.health ~= nil then
		act.doer:PushEvent("murdered", { victim = ingredient, stackmult = 1 }) -- NOTES(JBK): Cooking something alive.
		if ingredient.components.combat ~= nil then
			act.doer:PushEvent("killed", { victim = ingredient })
		end
	end

	local product = CookItem(ingredient, act.doer)
	if product ~= nil then
		act.doer.components.inventory:GiveItem(product, nil, cook_pos)
		return true
	elseif ingredient:IsValid() then
		act.doer.components.inventory:GiveItem(ingredient, nil, cook_pos)
	end

	return false
end

AddAction(WMB_COOK)

AddComponentAction("INVENTORY", "cookable", function(inst, doer, actions, right)
	if heatCooker and right and HasHeatModu(doer) and doer:HasTag("player") and doer.replica.inventory then
		local item = doer.replica.inventory:GetActiveItem()
		if item ~= nil and item == inst then		
			table.insert(actions, ACTIONS.WMB_COOK)
		end
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_COOK, "domediumaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_COOK, "domediumaction"))

--行为排队论兼容
AddComponentPostInit("actionqueuer", function(ActionQueuer)
	if ActionQueuer.AddAction ~= nil then
		ActionQueuer.AddAction("rightclick", "WMB_COOK", true)
	end
end)


--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_heat", function(modu)
    if TheWorld.ismastersim  then
	
		local oldfn = modu.ListenForEvent
		function modu:ListenForEvent(event, ...)
			if event == "onactivateskill_server" or event == "ondeactivateskill_server" or event == "leaderchanged" then
				return
			end
			return oldfn(self, event, ...)
		end	
		
		local oldfn = modu.RemoveEventCallback
		function modu:RemoveEventCallback(event, ...)
			if event == "onactivateskill_server" or event == "ondeactivateskill_server" or event == "leaderchanged" then
				return
			end
			return oldfn(self, event, ...)		
		end
		
    end
end)
