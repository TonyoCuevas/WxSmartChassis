require("behaviours/leash")
local WX78_ShadowDrone_BrainCommon = require("brains/wx78_shadowdrone_braincommon")

local DEBUFF_RANGE_FROM_LEADER = 16
local STOP_DEBUFF_DELAY = 3

local WX78_ShadowDrone_DebufferBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetLeader(inst)
	return inst.components.follower and inst.components.follower:GetLeader()
end

local function GetLeaderAction(leader) --NOTE: not inst!
    local target
	local act = leader:GetBufferedAction() or leader.sg and leader.sg.statemem.action
    if act then
        return act.action, act.target
    end

	if leader._lastspintime then
		if leader.sg:HasStateTag("spinning") then
			if GetTime() - leader._lastspintime < 1 then
				return leader._lastspinaction, leader._lastspintarget
            end
		elseif leader:HasTag("using_drone_remote") then
			return leader._lastspinaction, leader._lastspintarget
        end
    end

	if leader.components.playercontroller then
		return leader.components.playercontroller:GetRemoteInteraction()
    end
end

local function GetLeaderTarget(leader) --NOTE: not inst!
	if leader.components.rider and leader.components.rider:IsRiding() then
		return
	end

    local leaderact, leadertarget = GetLeaderAction(leader)
    if leaderact == ACTIONS.ATTACK then
		return leadertarget
	end

	return leader.components.combat and leader.components.combat.target
end

local function GetScanTarget(inst)
	local target = inst:GetScanTarget()
	if target and not (target.components.health and target.components.health:IsDead()) then
		return target
	end
end

local function ShouldScan(self)
	local leader = GetLeader(self.inst)
	if leader == nil then
		self._last_debuff_time = nil
		self.inst:ClearScanTarget()
		return false
	end

	--check leader has current target
	local leadertarget = GetLeaderTarget(leader)
	if leadertarget then
		self.inst:SetScanTarget(leadertarget)
		local target = GetScanTarget(self.inst)
		if target and leader:IsNear(target, DEBUFF_RANGE_FROM_LEADER) then
			self._last_debuff_time = GetTime()
			return true
		end
		self._last_debuff_time = nil
		self.inst:ClearScanTarget()
		return false
	end

	--check for keeping our last target
	local target = GetScanTarget(self.inst)
	if target and leader:IsNear(target, DEBUFF_RANGE_FROM_LEADER) then
		if self._last_debuff_time then
			-- Do not immediately stop debuffing when the player stops attacking or moves out of range.
			if GetTime() - self._last_debuff_time < STOP_DEBUFF_DELAY then
				return true
			end
			self._last_debuff_time = nil
		end

		if target.components.combat and
			target.components.combat:HasTarget() and
			leader.components.combat and
			leader.components.combat:IsAlly(target.components.combat.target)
		then
			-- Keep target if they are still in combat with us.
			return true
		end
	end

	self._last_debuff_time = nil
	self.inst:ClearScanTarget()
	return false
end

--scan position is [scandist] away from target
local DEG_45 = 45 * DEGREES
local function GetScanPos(inst)
	local target = GetScanTarget(inst)
	if target then
		local scandist--[[, maxdist]] = inst:CalcScanRange()
		local x1, y1, z1 = target.Transform:GetWorldPosition()
		local theta
		local offs = WX78_ShadowDrone_BrainCommon.GetFormationOffset(inst)
		if offs then
			theta = math.atan2(-offs.z, offs.x)
		else
			local x, y, z = inst.Transform:GetWorldPosition()
			if x == x1 and z == z1 then
				theta = (inst.Transform:GetRotation() + 180) * DEGREES
			else
				theta = math.atan2(z1 - z1, x - x1)
			end
		end
		--Snap to nearest 45 degrees, better matches 8-faced beams
		theta = math.floor(theta / DEG_45 + 0.5) * DEG_45
		return Vector3(x1 + scandist * math.cos(theta), 0, z1 - scandist * math.sin(theta))
	end
end

--Min/Max leash dist is relative to GetScanPos, not target pos
--Wider threshold when already in scanning mode.
local function MinMaxLeashDist(inst)
	local range, maxrange = inst:CalcScanRange()
	return inst.sg:HasStateTag("scanning")
		and math.max(0.65, maxrange - range - 0.1)
		or 0.65
end

--添加部分(自动工作部分参考自WX自动化)--------------------------------------------
local WMB_AutoModeFunc = {}

--是否可以自动战斗
local function CanAutoFight(inst)
	local leader = GetLeader(inst)
	
	if leader ~= nil and (leader.WMB_REMOTE_AUTO_FIGHT or leader.prefab == "wx78_backupbody") then
		return leader
	end	
	
	return nil
end

--寻找敌意目标
do
	
	local TOFIGHT_ONE_OF_TAGS = { "monster", "hostile", "nightmare", "epic", "mosquito", "killer", "shadowcreature", "nightmarecreature" }	
	local TOFIGHT_CANT_TAGS = { "INLIMBO", "player" }
	
	--是否跟随友好玩家
	--[[
	已驯化的实体跟随任何实体都视为友好玩家,除非开启PVP
	开启PVP的情况下,该函数只会返回false
	(毕竟饥荒原版没有队伍系统)
	]]
	local function HasFriendlyLeader(inst)
		if not TheNet:GetPVPEnabled() then
			local inst_leader = (inst.components.follower and inst.components.follower.leader) or nil
			
			if inst_leader then
				if inst_leader.components.inventoryitem then
					inst_leader = inst_leader.components.inventoryitem:GetGrandOwner()
				end

				return (inst_leader and inst_leader:HasTag("player"))
					or (inst.components.domesticatable and inst.components.domesticatable:IsDomesticated())
			end	
		end

		return false
	end	
	
	--是否为有效战斗目标
	local function IsAutoFightTarget(target, leader)
		--范围检测
		if not target:IsNear(leader, DEBUFF_RANGE_FROM_LEADER) then
			return false
		end
	
		--不要内斗
		if HasFriendlyLeader(target) then
			return false
		end
		
		--血量检测
		if target.components.health ~= nil and target.components.health:IsDead() then
			return false
		end		
		
		--检测目标的目标
		local _target = (target.components.combat and target.components.combat.target) or nil
		if _target then
			
			--领队或玩家
			if _target == leader or (not TheNet:GetPVPEnabled() and _target:HasTag("player")) then
				return true
			end
		end
		
		return target:HasOneOfTags(TOFIGHT_ONE_OF_TAGS)
	end	
	
	function WMB_AutoModeFunc:FindHostileTarget(inst)
		local leader = CanAutoFight(inst); if not leader then return end
		
		--检查记录
		local target = inst.target
		if target ~= nil and not IsAutoFightTarget(target, leader) then
			target = nil
		end
		
		--找领队附近的
		if target == nil then
			target = FindEntity(leader, DEBUFF_RANGE_FROM_LEADER, function(ent)
				return IsAutoFightTarget(ent, leader)
			end, nil, TOFIGHT_CANT_TAGS)
		end		
		
		if target ~= nil then
			inst:SetScanTarget(target)
			return true
		end
	end

end

----------------------------------------------------------------------------------------

function WX78_ShadowDrone_DebufferBrain:OnStart()
    local root = PriorityNode({
        WhileNode(
            function()
                return not self.inst.sg:HasStateTag("despawn")
            end,
            "<busy state guard>",
            PriorityNode({
				WhileNode(function() return ShouldScan(self) or (CanAutoFight(self.inst) ~= nil and WMB_AutoModeFunc:FindHostileTarget(self.inst) ~= nil) end, "scanning",
                    PriorityNode({
                        FailIfSuccessDecorator(Leash(self.inst, GetScanPos, MinMaxLeashDist, MinMaxLeashDist, true)),
                        ActionNode(function()
                            self.inst:PushEventImmediate("ms_wx_shadowdrone_scan")
                        end),
					}, 0.1)),
					
                WX78_ShadowDrone_BrainCommon.FollowFormationNode(self.inst),
                WX78_ShadowDrone_BrainCommon.WanderNode(self.inst),
			}, 0.1)
        )
	}, 0.1)

    self.bt = BT(self.inst, root)
end

return WX78_ShadowDrone_DebufferBrain
