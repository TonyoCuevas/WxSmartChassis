local BrainCommon = require("brains/braincommon")
local WX78_ShadowDrone_BrainCommon = require("brains/wx78_shadowdrone_braincommon")

local WX78_ShadowDrone_HarvesterBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local HARVEST_RADIUS = TUNING.SKILLS.WX78.SHADOWDRONE_HARVESTER_FINDITEM_RADIUS

--添加部分(自动工作部分参考自WX自动化)--------------------------------------------
local WMB_AutoModeFunc = {}

local SEE_WORK_DIST = HARVEST_RADIUS + 6 --用于找领队附近的目标
local REPEAT_WORK_DIST = HARVEST_RADIUS --用于找自己身边的目标

local function GetLeader(inst)
	return inst.components.follower and inst.components.follower:GetLeader()
end

--是否可以自动工作
local function CanAutoWork(inst)
	local leader = GetLeader(inst)
	
	if leader ~= nil and leader.WMB_REMOTE_AUTO_WORK then
		return leader
	end	
	
	return nil
end

--标记,减少获取同一个目标的概率
local function Mark(target, wait)
	wait = wait or 1
	if target.WMB_AUTO_MODE_HARVESTER_MARK == nil then	
		target.WMB_AUTO_MODE_HARVESTER_MARK = target:DoTaskInTime(wait, function(inst)
			inst.WMB_AUTO_MODE_HARVESTER_MARK = nil
		end)
	end
end
local function HasMark(target)
	return target.WMB_AUTO_MODE_HARVESTER_MARK ~= nil
end

--采集
do
	local TOPICK_TAGS = { "pickable" }
	local TOPICK_CANT_TAGS = { "fire", "smolder", "INLIMBO", "NOCLICK", "flower", "structure", "event_trigger", "donotautopick" }

	--是否可以采集
	local function CanWork(ent)
		return ent.components.pickable ~= nil 
			and ent.components.pickable:CanBePicked()
			and not HasMark(ent)
	end

	function WMB_AutoModeFunc:Harvest(inst)
		local leader = CanAutoWork(inst); if not leader then return end

		--检查记录
		local target = inst.sg.statemem.target
		if target ~= nil and not CanWork(target) then
			target = nil
		end
		
		--找自己身边的
		if target == nil then		
			target = FindEntity(inst, REPEAT_WORK_DIST, function(ent)
				return ent:IsNear(leader, SEE_WORK_DIST) and CanWork(ent)
			end, TOPICK_TAGS, TOPICK_CANT_TAGS)
		end
		
		--找领队附近的
		if target == nil then
			target = FindEntity(leader, SEE_WORK_DIST, function(ent)
				return CanWork(ent)
			end, TOPICK_TAGS, TOPICK_CANT_TAGS)			
		end
		
		if target ~= nil then
			Mark(target)
			return BufferedAction(inst, target, ACTIONS.PICK)
		end
	end
	
end

--拾取
do
	local TOPICKUP_TAGS = { "_inventoryitem" }
	local TOPICKUP_CANT_TAGS = { "fire", "smolder", "INLIMBO", "NOCLICK", "event_trigger", "irreplaceable", "heavy" }

	--是否可以拾取
	local function CanWork(ent, leader)
		if ent.components.inventoryitem ~= nil 
			and ent.components.equippable == nil
			and ent.components.container == nil
			and not ent:HasTag("heavy")
			and not HasMark(ent)
		then
			--可拾取的活物
			if ent.components.inventoryitem.canbepickedupalive 
				or ent.components.inventoryitem.trappable
			then
				return true
			end
		end
		return false
	end

	function WMB_AutoModeFunc:PickUp(inst)
		local leader = CanAutoWork(inst); if not leader then return end

		--检查记录
		local target = inst.sg.statemem.target
		if target ~= nil and not CanWork(target, leader) then
			target = nil
		end
		
		--找自己身边的
		if target == nil then		
			target = FindEntity(inst, REPEAT_WORK_DIST, function(ent)
				return ent:IsNear(leader, SEE_WORK_DIST) and CanWork(ent, leader)
			end, TOPICKUP_TAGS, TOPICKUP_CANT_TAGS)
		end
		
		--找领队附近的
		if target == nil then
			target = FindEntity(leader, SEE_WORK_DIST, function(ent)
				return CanWork(ent, leader)
			end, TOPICKUP_TAGS, TOPICKUP_CANT_TAGS)			
		end
		
		if target ~= nil and target.components.inventoryitem then
			Mark(target, 10) --标记持续久一点防止一直拾取
			
			--用于修正	
			target.components.inventoryitem.canbepickedupalive = true
			
			return BufferedAction(inst, target, ACTIONS.PICKUP)
		end
	end
	
end

--备份底盘拾取蝴蝶
do
	local TOPICKUP_TAGS = { "_inventoryitem", "butterfly" }
	local TOPICKUP_CANT_TAGS = { "fire", "smolder", "INLIMBO", "NOCLICK", "event_trigger", "irreplaceable", "heavy" }

	--是否可以拾取
	local function CanWork(ent, leader)
		if ent.components.inventoryitem ~= nil 
			and ent.components.equippable == nil
			and ent.components.container == nil
			and not ent:HasTag("heavy")
			and not HasMark(ent)
		then
			--可拾取的活物
			if ent.components.inventoryitem.canbepickedupalive 
				or ent.components.inventoryitem.trappable
			then
				return true
			end
		end
		return false
	end

	function WMB_AutoModeFunc:PickUp_Backup(inst)
		local leader = GetLeader(inst)
		
		if leader == nil or not leader:HasTag("wx78_backupbody") then
			return
		end

		--检查记录
		local target = inst.sg.statemem.target
		if target ~= nil and not CanWork(target, leader) then
			target = nil
		end
		
		--找自己身边的
		if target == nil then		
			target = FindEntity(inst, REPEAT_WORK_DIST, function(ent)
				return ent:IsNear(leader, SEE_WORK_DIST) and CanWork(ent, leader)
			end, TOPICKUP_TAGS, TOPICKUP_CANT_TAGS)
		end
		
		--找领队附近的
		if target == nil then
			target = FindEntity(leader, SEE_WORK_DIST, function(ent)
				return CanWork(ent, leader)
			end, TOPICKUP_TAGS, TOPICKUP_CANT_TAGS)			
		end
		
		if target ~= nil and target.components.inventoryitem then
			Mark(target, 10) --标记持续久一点防止一直拾取
			
			--用于修正	
			target.components.inventoryitem.canbepickedupalive = true
			
			return BufferedAction(inst, target, ACTIONS.PICKUP)
		end
	end
	
end


----------------------------------------------------------------------------------------

function WX78_ShadowDrone_HarvesterBrain:OnStart()
    local pickupparams = {
        range = HARVEST_RADIUS,
        furthestfirst = true,
        allowpickables = true,
        itemoverridefn = function(inst, leader)
            local socket_shadow_harvester = leader and leader.components.socket_shadow_harvester or nil
            if not socket_shadow_harvester then
                return nil
            end

            return socket_shadow_harvester:GetItemForHarvester(self.inst)
        end,
    }
    local root = PriorityNode({
        WhileNode(
            function()
                return not self.inst.sg:HasStateTag("despawn")
            end,
            "<busy state guard>",
            PriorityNode({
			
				--自动模式
				WhileNode(function()
					local leader = GetLeader(self.inst)
					if leader ~= nil and (leader.WMB_REMOTE_AUTO_WORK) then
						return true
					end
					return false
				end, "WMB_AUTO_MODE", SelectorNode({
					--自动工作
					IfNode(
						function() 
							local leader = GetLeader(self.inst)
							if leader ~= nil and (leader.WMB_REMOTE_AUTO_WORK) 
								and self.inst.components.inventory ~= nil
								and not self.inst.components.inventory:IsFull()
								and leader.components.inventory ~= nil
								and not leader.components.inventory:IsFull()
							then
								return true
							end
							return false
						end, "WMB_AUTO_WORK",
						SelectorNode({
							DoAction(self.inst, function() return WMB_AutoModeFunc:PickUp(self.inst) end, "WMB_AUTO_PICKUP", true),
							DoAction(self.inst, function() return WMB_AutoModeFunc:Harvest(self.inst) end, "WMB_AUTO_HARVEST", true),
						})
					),

				})),			
			
				--备份底盘自动模式
				WhileNode(function()
					local leader = GetLeader(self.inst)
					if leader ~= nil and leader:HasTag("wx78_backupbody") then
						return true
					end
					return false
				end, "WMB_AUTO_MODE_BACKUP", SelectorNode({
					--自动工作
					IfNode(
						function() 
							local leader = GetLeader(self.inst)
							if leader ~= nil and leader:HasTag("wx78_backupbody")
								and self.inst.components.inventory ~= nil
								and not self.inst.components.inventory:IsFull()
								and leader.components.container ~= nil
								and not leader.components.container:IsFull()
							then
								return true
							end
							return false
						end, "WMB_AUTO_WORK_BACKUP",
						SelectorNode({
							DoAction(self.inst, function() return WMB_AutoModeFunc:PickUp_Backup(self.inst) end, "WMB_AUTO_PICKUP_BACKUP", true),
						})
					),

				})),			
			
                BrainCommon.NodeAssistLeaderPickUps(self, pickupparams),
                WX78_ShadowDrone_BrainCommon.FollowFormationNode(self.inst),
                WX78_ShadowDrone_BrainCommon.WanderNode(self.inst),
            }, .25)
        )
    }, .25)

    self.bt = BT(self.inst, root)
end

return WX78_ShadowDrone_HarvesterBrain
