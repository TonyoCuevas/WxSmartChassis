--制冷电路

local LANG = GetModConfigData("language")

local coldFireResist = GetModConfigData("cold_fireresist")
local coldExtinguish = GetModConfigData("cold_extinguish")

TUNING.WX78_COLD_ICEMOISTURE = GetModConfigData("cold_ice")
TUNING.WX78_COLD_ICECOUNT = GetModConfigData("cold_icenum")

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_cold_tag = net_bool(inst.GUID, "WMB_cold_tag", "WMB_cold_tag.dirty")
	inst.WMB_cold_tag:set(false)
end)

--制冷电路激活
local function cold_activate(modu, wx)
	wx.WMB_coldnum = (wx.WMB_coldnum or 0) + 1

	--火焰减伤
	if wx.components.health then
		wx.components.health.externalfiredamagemultipliers:SetModifier(modu, 1 - coldFireResist)
	end
	
	--允许扑灭火焰
	if wx.player_classified and wx.player_classified.WMB_cold_tag then
		wx.player_classified.WMB_cold_tag:set(true)
	end
end

--制冷电路关闭
local function cold_deactivate(modu, wx)
	 wx.WMB_coldnum = math.max(0, (wx.WMB_coldnum or 0) - 1)

	--取消火焰减伤
	if wx.components.health then
		wx.components.health.externalfiredamagemultipliers:RemoveModifier(modu)
	end
	
	--取消允许扑灭火焰
	if wx.WMB_coldnum <= 0 then
		if wx.player_classified and wx.player_classified.WMB_cold_tag then
			wx.player_classified.WMB_cold_tag:set(false)
		end
	end
end

--制冷电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "cold" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			cold_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			cold_deactivate(modu, wx)
		end
	end
end

-- AddPrefabPostInit("wx78module_cold", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- cold_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- cold_deactivate(modu, wx)
		-- end
    -- end
-- end)


--左键扑灭动作注册
local WMB_EXTINGUISH = Action({priority = 0.5, mount_valid = true, invalid_hold_action = true})
WMB_EXTINGUISH.id = "WMB_EXTINGUISH"
WMB_EXTINGUISH.str = (LANG and "扑灭") or "Extinguish"
WMB_EXTINGUISH.fn = function(act)
	local target = act.target or act.invobject
	if target == nil then return false end
	local SUCCESS = false

    if target.components.burnable and (target.components.burnable:IsBurning() or target.components.burnable:IsSmoldering()) then
		if target.components.fueled and not target.components.fueled:IsEmpty() then
			target.components.fueled:ChangeSection(-1)
		end
		target.components.burnable:Extinguish(true, 0)
		SUCCESS = true
    end

	--群体灭火
	local x, y, z = target.Transform:GetWorldPosition()
	local fires = TheSim:FindEntities(x, y, z, 2, nil,  {"INLIMBO", "lighter"}, {"fire", "smolder"})
	for _,fire in pairs(fires) do
		if fire.components.fueled and not fire.components.fueled:IsEmpty() then
			fire.components.fueled:ChangeSection(-1)
		end
		if fire.components.burnable and (fire.components.burnable:IsBurning() or fire.components.burnable:IsSmoldering()) then			
			fire.components.burnable:Extinguish(true, 0)
		end
		SUCCESS = true
	end

	return SUCCESS
end

AddAction(WMB_EXTINGUISH)

AddComponentAction("SCENE", "burnable", function(inst, doer, actions, right)
	if coldExtinguish and inst:HasOneOfTags({"fire", "smolder"})
		and doer.player_classified
		and doer.player_classified.WMB_cold_tag
		and doer.player_classified.WMB_cold_tag:value()
	then
        table.insert(actions, ACTIONS.WMB_EXTINGUISH)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_EXTINGUISH, "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_EXTINGUISH, "doshortaction"))

--注册动作快捷键(貌似方式有误,弃用)
-- local function TryExtinguish(self, force_target)
	-- if not (
		-- ((not self.ismastersim and (self.remote_controls[GLOBAL.CONTROL_ACTION] or 0) > 0)
			-- or not self:IsEnabled()
			-- or self:IsBusy()
			-- or (force_target ~= nil and (not force_target.entity:IsVisible() or force_target:HasTag("INLIMBO") or force_target:HasTag("NOCLICK"))))
			-- or self.inst.replica.inventory:IsHeavyLifting()
	-- ) and not self:IsDoingOrWorking() and not self.inst:HasTag("playerghost") then

		-- if self.inst:HasTag("WMB_cold") then
			-- local x, y, z = self.inst.Transform:GetWorldPosition()
			-- local fires = TheSim:FindEntities(x, y, z, 4, nil,  {"INLIMBO", "lighter"}, {"fire", "smolder"})
			-- for _,fire in ipairs(fires) do
				-- if not fire:HasTag("campfire") then					
					-- return BufferedAction(self.inst, fire, ACTIONS.WMB_EXTINGUISH)
				-- end
			-- end
		-- end
	-- end
-- end
-- if coldExtinguish then		
	-- AddComponentPostInit("playercontroller", function(PlayerController)
		-- local oldfn = PlayerController.GetActionButtonAction
		-- function PlayerController:GetActionButtonAction(force_target)
			-- local new_action = TryExtinguish(self, force_target)
			-- return (new_action ~= nil and new_action) or oldfn(self, force_target)
		-- end
	-- end)
-- end


--行为排队论兼容
AddComponentPostInit("actionqueuer", function(ActionQueuer)
	if ActionQueuer.AddAction ~= nil then
		ActionQueuer.AddAction("leftclick", "WMB_EXTINGUISH", true)
	end
end)

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_cold", function(modu)
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
