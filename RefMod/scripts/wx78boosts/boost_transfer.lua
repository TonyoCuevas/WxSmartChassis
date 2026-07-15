--灵体传输模块

local LANG = GetModConfigData("language")

--修改动作文本
do
	local oldfn = ACTIONS.USESPELLBOOK.strfn or function() end
	ACTIONS.USESPELLBOOK.strfn = function(act)
		return (act.doer:HasTag("upgrademoduleowner") and "WMB_REMOTE") or oldfn(act)
	end
	
	local oldfn = ACTIONS.CLOSESPELLBOOK.strfn or function() end
	ACTIONS.CLOSESPELLBOOK.strfn = function(act)
		return (act.doer:HasTag("upgrademoduleowner") and "WMB_REMOTE") or oldfn(act)
	end
	
	if LANG then
		STRINGS.ACTIONS.USESPELLBOOK.WMB_REMOTE = "使用"
		STRINGS.ACTIONS.CLOSESPELLBOOK.WMB_REMOTE = "取消"
	else	
		STRINGS.ACTIONS.USESPELLBOOK.WMB_REMOTE = "Use"
		STRINGS.ACTIONS.CLOSESPELLBOOK.WMB_REMOTE = "Cancel"
	end
end

local function StartAOETargeting(inst)
	local playercontroller = ThePlayer.components.playercontroller
	if playercontroller ~= nil then
		playercontroller:StartAOETargetingUsing(inst)
	end
end

--文本
local Texts = (LANG and {
	"集合",
	"跟随 / 立定",
	"自动工作",
	"自动战斗",
}) or {
	"Gather",
	"Follow / Stand",
	"Auto-Work",
	"Auto-Fight",
}

--说话
local function Say(doer, zh, en)
	if doer.components.talker then
		if LANG then
			doer.components.talker:Say(zh)
		else			
			doer.components.talker:Say(en)
		end
	end
end

--传送机器人到附近
local function Teleport(doer, follower)
	local pt1 = doer:GetPosition()
	local pt2 = follower:GetPosition()
	local diff = (pt2 - pt1)
	local offset = diff:GetNormalized() * 0.1 * math.random(30,60)
	local x,y,z = pt1.x + offset.x, pt1.y, pt1.z + offset.z
	
	--尽量不传送到海上以及让位置不被阻挡
	local offset2 = 0
	for i = 1,10 do
		if TheWorld.Map:IsOceanAtPoint(x, 0, z) or TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
			offset = diff:GetNormalized() * 0.1 * math.random(15,30) * ((-1)^offset2)
			x,y,z = pt1.x + offset.x, pt1.y, pt1.z + offset.z
			offset2 = offset2 + 1
		else
			break
		end
	end

	--如果传送位置还是在海上或位置被阻挡,则不传送并提示
	if TheWorld.Map:IsOceanAtPoint(x, 0, z) and follower.components.drownable ~= nil and follower.components.drownable.enabled then
		-- if doer.components.talker then
			-- Say(doer, 
				-- "警告：海洋", 
				-- "Warning: Ocean"
			-- )
		-- end
	elseif TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
		-- if doer.components.talker then
			-- Say(doer, 
				-- "警告：障碍物", 
				-- "Warning: Obstacles"
			-- )
		-- end
	else
		follower.Transform:SetPosition(x, y, z)
		follower.brain:Pause()
		
		--清除仇恨
		if follower.components.combat then
			follower.components.combat:DropTarget()
		end
		
		follower.brain.bt:Reset()
		follower:DoTaskInTime(0, function(wx)
			if not wx.components.container or not wx.components.container:IsOpen() then
				wx.brain:Resume()
			end
		end)
		SpawnPrefab("spawn_fx_medium").Transform:SetPosition(x, y, z)
		return true
	end
	
	return false
end

--传送机器人RPC
AddModRPCHandler("WMB_MOD_RPC", "TeleportWX", function(player)
	local doer = player; if not doer then return end
	local Num = 0
	local NumSuccess = 0
	
	if doer.components.leader then	
		for follower,_ in pairs(doer.components.leader.followers) do
			local prefab = follower.prefab
			if prefab == "wx78_possessedbody" 
				or prefab == "wx78_shadowdrone_harvester" 
				or prefab == "wx78_shadowdrone_debuffer"
			then
				Num = Num + 1
				if Teleport(doer, follower) then
					NumSuccess = NumSuccess + 1
				end
			end
		end
	end
	
	if Num > 0 then	
		local NumStr = tostring(NumSuccess).." / "..tostring(Num)
		if Num == NumSuccess then
			Say(doer, 
				NumStr.."，全体集合完毕",
				NumStr..", all gathered"
			)
		else
			Say(doer, 
				NumStr.."，检测到阻碍", 
				NumStr..", obstacles detected"
			)			
		end
	else
		Say(doer, 
			"错误：暂无队列", 
			"Error: No queue"
		)
	end
end)

--自动工作RPC
AddModRPCHandler("WMB_MOD_RPC", "ToggleWXAutoWork", function(player)
	local doer = player; if not doer then return end
	if doer.WMB_REMOTE_AUTO_WORK == nil then
		doer.WMB_REMOTE_AUTO_WORK = true
		Say(doer, "启用自动工作协议", "Activate Auto-Work agreement")
	else
		doer.WMB_REMOTE_AUTO_WORK = nil
		Say(doer, "禁用自动工作协议", "Deactivate Auto-Work agreement")
	end
end)

--自动战斗RPC
AddModRPCHandler("WMB_MOD_RPC", "ToggleWXAutoFight", function(player)
	local doer = player; if not doer then return end
	if doer.WMB_REMOTE_AUTO_FIGHT == nil then
		doer.WMB_REMOTE_AUTO_FIGHT = true
		Say(doer, "启用自动战斗协议", "Activate Auto-Work agreement")
	else
		doer.WMB_REMOTE_AUTO_FIGHT = nil
		Say(doer, "禁用自动战斗协议", "Deactivate Auto-Work agreement")
	end
end)

--集合功能
local function GatherFn()
	SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "TeleportWX"))
	return true
end

--自动工作功能
local function AutoWorkFn()
	SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "ToggleWXAutoWork"))
	return true
end

--自动战斗功能
local function AutoFightFn()
	SendModRPCToServer(GetModRPC("WMB_MOD_RPC", "ToggleWXAutoFight"))
	return true
end

--获取最近的附身底盘
local function GetClosetWX(pos, radius)
	local wx = nil
    local x, y, z = pos:Get()
	local ents = TheSim:FindEntities(x, y, z, radius, {"possessedbody"}, {"INLIMBO", "FX", "NOCLICK"})
	local rangesq = radius * radius
	
	for i,v in ipairs(ents) do
		if v.prefab == "wx78_possessedbody" 
			and not IsEntityDeadOrGhost(v) 
			and v.entity:IsVisible()
			and v.components.follower ~= nil
		then
			local distsq = v:GetDistanceSqToPoint(x, y, z)
			if distsq < rangesq then
				rangesq = distsq
				wx = v
			end
		end
	end

	return wx
end

--标点
local function PingTarget(target)
	local ping = SpawnPrefab("reticuleaoewinonaengineeringping")
	ping.Transform:SetPosition(target.Transform:GetWorldPosition())
	ping.Transform:SetRotation(target.Transform:GetRotation())

	--placer colours:
	--  -base colour 0x6e6045 via multcolour
	--  -validcolour (0.25, 0.75, 0.25) via addcolour
	--
	--normally, reticule:PingReticuleAt controls the colours
	--to manually match it:
	--  use multcolour to match the base+validclour
	--  addcolour is fixed (0.2, 0.2, 0.2) when triggering ping
	ping.AnimState:SetMultColour(math.min(1, 0x6e/255+0.25), math.min(1, 0x60/255+0.75), math.min(1, 0x45/255+0.25), 1)
	ping.AnimState:SetAddColour(0.2, 0.2, 0.2, 0)
	ping.AnimState:SetScale(1, 1)

	return true
end

--用于显示选中的附身底盘
local function SelectWXUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
	reticule.Transform:SetPosition(pos:Get())
	local wx = GetClosetWX(pos, 2)
	if wx and reticule.prefab == "reticuleaoefiretarget_1ping" then
		PingTarget(wx)
	end
end

--跟随或立定功能
local function FollowOrStandFn(inst, doer, pos)
	if not doer then return end
	local wx = GetClosetWX(pos, 2)

	if wx and wx.components.follower then
		if wx.components.follower.leader == doer then
			wx.components.follower.leader = nil
			Say(doer, "已发送指令：立定", "Sent command: Stand")
		else
			wx.components.follower:SetLeader(doer)
			Say(doer, "已发送指令：跟随", "Sent command: Follow")
		end
	end
	
end


local ICON_SCALE = 0.78
local ICON_RADIUS = 50
local SPELLBOOK_RADIUS = 100
local SPELLBOOK_FOCUS_RADIUS = SPELLBOOK_RADIUS + 2
local SPELLS =
{
	{
		label = Texts[1],
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(Texts[1])
			inst.components.spellbook:SetSpellAction(nil)
            if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = GatherFn,
		atlas = "images/wmb_spell_icons.xml",
		normal = "wmb_gather.tex",
		widget_scale = ICON_SCALE,
		hit_radius = ICON_RADIUS,
	},
	{
		label = Texts[2],
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(Texts[2])
			inst.components.spellbook:SetSpellAction(nil)
			inst.components.aoetargeting:SetDeployRadius(0)
			inst.components.aoetargeting:SetShouldRepeatCastFn(function() return true end)
			inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoefiretarget_1"
			inst.components.aoetargeting.reticule.pingprefab = "reticuleaoefiretarget_1ping"
			inst.components.aoetargeting.reticule.updatepositionfn = SelectWXUpdatePositionFn
			if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX("reticuleaoefiretarget_1")
				inst.components.aoespell:SetSpellFn(FollowOrStandFn)
				inst.components.spellbook:SetSpellFn(nil)
			end
		end,
		execute = StartAOETargeting,
		atlas = "images/wmb_spell_icons.xml",
		normal = "wmb_stand.tex",
		widget_scale = ICON_SCALE,
		hit_radius = ICON_RADIUS,
	},
	{
		label = Texts[3],
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(Texts[3])
			inst.components.spellbook:SetSpellAction(nil)
            if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = AutoWorkFn,
		atlas = "images/wmb_spell_icons.xml",
		normal = "wmb_work.tex",
		widget_scale = ICON_SCALE,
		hit_radius = ICON_RADIUS,
	},
	{
		label = Texts[4],
		onselect = function(inst)
			inst.components.spellbook:SetSpellName(Texts[4])
			inst.components.spellbook:SetSpellAction(nil)
            if TheWorld.ismastersim then
				inst.components.aoetargeting:SetTargetFX(nil)
                inst.components.spellbook:SetSpellFn(nil)
            end
		end,
		execute = AutoFightFn,
		atlas = "images/wmb_spell_icons.xml",
		normal = "wmb_fight.tex",
		widget_scale = ICON_SCALE,
		hit_radius = ICON_RADIUS,
	},
}

AddPrefabPostInit("wx78_gestalttrapper", function(inst)

	inst:AddComponent("spellbook")
	inst.components.spellbook:SetRequiredTag("upgrademoduleowner")
	inst.components.spellbook:SetRadius(SPELLBOOK_RADIUS)
	inst.components.spellbook:SetFocusRadius(SPELLBOOK_FOCUS_RADIUS)
	inst.components.spellbook:SetItems(SPELLS)
	--inst.components.spellbook:SetOnOpenFn(OnOpenSpellBook)
	--inst.components.spellbook:SetOnCloseFn(OnCloseSpellBook)
	inst.components.spellbook.opensound = "meta4/winona_UI/open"
	inst.components.spellbook.closesound = "meta4/winona_UI/close"
	inst.components.spellbook.executesound = "meta4/winona_UI/select"
	inst.components.spellbook.focussound = "meta4/winona_UI/hover"

	inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAllowWater(true)
	inst.components.aoetargeting:SetRange(78)
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetAllowWaterFn
	inst.components.aoetargeting.reticule.validcolour = { 0.78125, 0.546875, 0.3125, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { 0.5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true
	inst.components.aoetargeting.reticule.twinstickmode = 1
	inst.components.aoetargeting.reticule.twinstickrange = 8

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("aoespell")
	
end)

--动作修改
local function ModifyActionHandler(sg)
    if sg.actionhandlers ~= nil then
		local handler = sg.actionhandlers[ACTIONS.CASTAOE] or {}
		local oldfn = handler.deststate or function() end
		handler.deststate = function(inst, act)
			local invobject = act.invobject
			if invobject and invobject.prefab == "wx78_gestalttrapper" then
				return "give"
			end
			return oldfn(inst, act)
		end
	end
end
AddStategraphPostInit("wilson", ModifyActionHandler)
AddStategraphPostInit("wilson_client", ModifyActionHandler)

--快速动作
if GetModConfigData("transfer_quick") then
	local actions = {ACTIONS.CONTAINER_INSTALL_ITEM, ACTIONS.USEITEMON}

	local function transfer_actionhandler(inst, act)
		if act.target and act.target.prefab == "wx78_backupbody" then
			return "doshortaction"
		end
	end
	local function transfer_quickfn(sg)
		if sg.actionhandlers ~= nil then
			for _,action in pairs(actions) do
				local handler = sg.actionhandlers[action] or {}
				local oldfn = handler.deststate or function() end
				handler.deststate = function(inst, act)
					local oldresult = oldfn(inst, act)
					if oldresult == "dolongaction" then
						return transfer_actionhandler(inst, act) or oldresult
					end
					return oldresult
				end
			end
		end
	end
	AddStategraphPostInit("wilson", transfer_quickfn)
	AddStategraphPostInit("wilson_client", transfer_quickfn)

end


--以下为附身底盘和无人机行为逻辑修改

--是否可以自动战斗
local function CanAutoFight(wx)
	local leader = wx.components.follower and wx.components.follower:GetLeader()
	
	if leader ~= nil and leader.WMB_REMOTE_AUTO_FIGHT then
		return leader
	end	
	
	return nil
end

--附身底盘
do
	local brain = require("brains/wmb_wx78_possessedbodybrain")
	AddPrefabPostInit("wx78_possessedbody", function(wx)
		if TheWorld.ismastersim then
			wx:SetBrain(brain)
			
			--自动战斗模式下看谁都不顺眼
			if wx.components.combat then
				local oldfn = wx.components.combat.ShouldAggro or function() end
				function wx.components.combat:ShouldAggro(...)
					local leader = CanAutoFight(self.inst)
					if leader then
						return true
					end
					return oldfn(self, ...)
				end
			end
		end
	end)
end

--抓取机
do
	local brain = require("brains/wmb_wx78_shadowdrone_harvesterbrain")
	AddPrefabPostInit("wx78_shadowdrone_harvester", function(inst)
		if TheWorld.ismastersim then
			inst:SetBrain(brain)
		end
	end)
	
	--抓月熠补偿,成功抓取时再生成一个
	local oldfn = ACTIONS.PICKUP.fn or function() end
	ACTIONS.PICKUP.fn = function(act)
		local target = act.target
		local doer = act.doer
		
		if doer and doer.prefab == "wx78_shadowdrone_harvester"
			and target and target.prefab == "moonstorm_spark"
		then
			local success,reason = oldfn(act)
			if success then
				if TheWorld.components.moonstormmanager then
					TheWorld.components.moonstormmanager:DoTestForSparks()
				end
			end
			return success,reason
		end
		
		return oldfn(act)
	end
end

--破绽机
do
	local brain = require("brains/wmb_wx78_shadowdrone_debufferbrain")
	AddPrefabPostInit("wx78_shadowdrone_debuffer", function(inst)
		if TheWorld.ismastersim then
			inst:SetBrain(brain)
		end
	end)
end

