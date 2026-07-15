--电气化电路

local LANG = GetModConfigData("language")

local taserLimit = GetModConfigData("taser_limit")
local taserReturnDMG = GetModConfigData("taser_dmg1")
local taserReturnRange = GetModConfigData("taser_range1")
local taserExtraDMG = GetModConfigData("taser_dmg2")
local taserExtraRange = GetModConfigData("taser_range2")
local taserType = GetModConfigData("taser_dmgtype")
local taserPvp = GetModConfigData("taser_pvp")
local taser_zap = GetModConfigData("taser_zap")
local taser_zap_cost = GetModConfigData("taser_zap_cost")

--注册交换数据以避免使用标签
AddPrefabPostInit("player_classified", function(inst)
	inst.WMB_taser_tag = net_bool(inst.GUID, "WMB_taser_tag", "WMB_taser_tag.dirty")
	inst.WMB_taser_tag:set(false)
	
	inst.WMB_taser_cd_tag = net_bool(inst.GUID, "WMB_taser_cd_tag", "WMB_taser_cd_tag.dirty")
	inst.WMB_taser_cd_tag:set(false)
end)

--是否有电气化电路
local function HasTaserModu(wx)
	if wx.player_classified
		and wx.player_classified.WMB_taser_tag
		and wx.player_classified.WMB_taser_tag:value()
	then
		return true
	end
	return false
end

--跳闸是否在冷却
local function IsInZapCD(wx)
	if wx.player_classified
		and wx.player_classified.WMB_taser_cd_tag
		and wx.player_classified.WMB_taser_cd_tag:value()
	then
		return true
	end
	return false
end

--设置跳闸冷却(只能在主机使用)
local function SetZapCD(wx)
	if taser_zap and taser_zap > 0 
		and wx.player_classified
		and wx.player_classified.WMB_taser_cd_tag
		and not wx.player_classified.WMB_taser_cd_tag:value()
	then
		wx.player_classified.WMB_taser_cd_tag:set(true)
		if wx.wmb_taser_zap_cd_task == nil then
			wx.wmb_taser_zap_cd_task = wx:DoTaskInTime(taser_zap, function(inst) 
				inst.wmb_taser_zap_cd_task = nil
				
				if inst.player_classified and inst.player_classified.WMB_taser_cd_tag then
					inst.player_classified.WMB_taser_cd_tag:set(false)
				end
			end)
		end	
	end
end


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

--群伤排除标签
local taserExcludeTags = {"INLIMBO", "companion", "wall", "abigail", "shadowminion", "balloon", "hive"}


--电气化电路伤害倍率计算
--[[
对常规目标1.5倍;对潮湿目标2.5倍;对绝缘目标1倍
]]
local function taser_GetDamageMult(wx, target)
	local dmg_mult = 0

	--PVP检查
	if target:HasTag("player") and (taserPvp == 3 or (taserPvp == 2 and not TheNet:GetPVPEnabled())) then
		return 0
	end

	--电免疫检查
	if target:HasTag("electricdamageimmune") or (target.components.inventory ~= nil and target.components.inventory:IsInsulated()) then
		dmg_mult = 1
	else
		if target.components.combat
			and (target.components.health and not target.components.health:IsDead())
		then
			dmg_mult = TUNING.ELECTRIC_DAMAGE_MULT

			--潮湿度检查
			local wetness_mult = (target.components.moisture ~= nil and target.components.moisture:GetMoisturePercent())
				or (target:GetIsWet() and 1)
				or 0
			dmg_mult = dmg_mult + wetness_mult
		end		
	end

	--电路个数检查
	if wx.WMB_tasernum and wx.WMB_tasernum > 0 then
		--检查叠加上限
		if taserLimit > 0 then
			dmg_mult = dmg_mult * math.min(wx.WMB_tasernum, taserLimit)
		else
			dmg_mult = dmg_mult * wx.WMB_tasernum
		end	
	end	

	return dmg_mult
end

--伤害计数器修正
AddComponentPostInit("stunnable", function(Stunnable)
    local oldfn = Stunnable.TakeDamage
    function Stunnable:TakeDamage(damage, ...)
		self.WMB_LAST_DAMAGE_TAKEN = damage
        return oldfn(self, damage, ...)
    end
end)

--电气化电路造成伤害
local function taser_DoDamage(dmg, wx, _target, data)
	if dmg < 0 then return end

	--眩晕伤害计数器修正(主要是龙蝇)
	do
		local stunnable = _target.components.stunnable
		if stunnable and stunnable.WMB_LAST_DAMAGE_TAKEN then
			local KEY = GetTime() - 0.001
			if GetTime() >= stunnable.valid_stun_time and not stunnable.damage[KEY] then
				stunnable.damage[KEY] = math.abs(stunnable.WMB_LAST_DAMAGE_TAKEN)
			end
		end
	end

	--伤害类型判断
	if taserType == 1 then
		_target.components.combat:GetAttacked(nil, dmg)
		_target:PushEvent("attacked", {attacker = wx, damage = 0, stimuli = "electric"}) --用于施加带电攻击判断
		if dmg == 0 then
			_target:PushEvent("attacked", {attacker = wx, damage = 0}) --用于造成伤害和硬直
		end
	else
		local insulated = _target:HasTag("electricdamageimmune") or (_target.components.inventory ~= nil and _target.components.inventory:IsInsulated())
		_target.components.health:DoDelta(-dmg, false, wx.prefab, false, wx, not insulated)
		_target:PushEvent("attacked", {attacker = wx, damage = 0})
		_target:PushEvent("attacked", {attacker = wx, damage = 0, stimuli = "electric"})	
	end
	
	local prefab = _target.prefab
	
	--恶液
	if prefab == "gelblob" then
		_target:PushEvent("electrocute", { attacker = wx, stimuli = "electric" })
	end
	
	--秒杀哈姆雷特虫群
	if prefab == "gnat"
		or prefab == "cropgnat" --棱镜mod
		or prefab == "cropgnat_infester" --棱镜mod
	then
		_target.components.health:SetVal(0, "electric", wx)
	end
	
	--击杀检测
	if _target.components.health:IsDead() then
		wx:PushEvent("killed", {victim = _target, attacker = wx})
		if _target.components.combat.onkilledbyother ~= nil then
			_target.components.combat.onkilledbyother(_target, wx)
		end
	end
	
	--能量勋章mod击杀检测
	if _target.components.health:IsDead() or (_target.components.health.IsDefeated and _target.components.health:IsDefeated()) or _target.defeated then
		if _target.prefab == "klaus" and _target.IsUnchained ~= nil and not _target:IsUnchained() then return end--克劳斯需要二阶段死了才算
		local eslot = EQUIPSLOTS.MEDAL or EQUIPSLOTS.NECK or EQUIPSLOTS.BODY
		local medal = (wx.components.inventory and wx.components.inventory:GetEquippedItem(eslot)) or nil
		
		if medal ~= nil and medal:HasTag("medal") then
			if medal.medalKilled and not _target["medal_kill_sign_"..medal.prefab] then
				_target["medal_kill_sign_"..medal.prefab] = true--添加标记防多次触发
				medal.medalKilled(wx,{victim=_target,prefab=medal.prefab})
			end
		
			--融合勋章
			if medal:HasTag("multivariate_certificate") and medal.components.container then
				for _,v in pairs(medal.components.container.slots) do
					if v:HasTag("medal") and v.medalKilled and not _target["medal_kill_sign_"..v.prefab] then
						_target["medal_kill_sign_"..v.prefab] = true--添加标记防多次触发
						v.medalKilled(wx,{victim=_target,prefab=v.prefab})
					end
				end
			end
		end
	end	
end

--电气化电路尝试造成伤害
local function taser_TryDamage(dmg, wx, target, data)
	if dmg < 0 then return false end
	if target == nil then return false end
	if target.components.health == nil then return false end
	if target.components.combat == nil then return false end
	local prefab = target.prefab
	
	--排除遗迹古董(修复为爽神秘打古董崩溃的问题)
	if string.sub(prefab, 1, 6) == "ruins_" then
		return false
	end
	
	--排除能量静电
	if prefab == "moonstorm_static" or prefab == "moonstorm_static_nowag" then
		return false
	end
	
	local mult = taser_GetDamageMult(wx, target)
	if mult > 0 then		
		taser_DoDamage(mult*dmg, wx, target, data)
		return true
	end
	
	return false
end

--电气化电路获取群体目标
--[[
排除自身,目标,友好追随者,追随友好者,和具有排除标签的实体
]]
local function taser_GetTargets(dmg, range, wx)
	local x,y,z = wx.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, range, {"_combat"}, taserExcludeTags)
	local result = {}

	for _,ent in pairs(ents) do
		if ent ~= wx
			and (wx.components.combat == nil or wx.components.combat:IsValidTarget(ent))
			and (wx.components.leader == nil or not wx.components.leader:IsFollower(ent))
			and (taserPvp == 1 or not HasFriendlyLeader(ent)) then
				table.insert(result, ent)
		end
	end
	
	return result
end

--电气化电路反伤重构
--[[
原版是0.3秒冷却,对于反伤来说实在太慢了,还是自身冷却,不知道鸽雷怎么想的
]]
local function taser_onblockedorattacked(wx, data)
    if data and data.attacker and not data.redirected then
		local dmg = taserReturnDMG
		local range = taserReturnRange

		--防止反伤吃到增伤
		if data.attacker.WMB_taserextradmgcd == nil then
			data.attacker.WMB_taserextradmgcd = data.attacker:DoTaskInTime(0.001, function(inst) inst.WMB_taserextradmgcd = nil end)
		end

		--对于投射类武器和投射物不进行单体反伤
		if data == nil or data.weapon == nil or 
			(	
				data.weapon.components.projectile == nil and
				(data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil)
			)
		then
			--冷却检查(防止伤害无限循环)
			if data.attacker.WMB_taserreturndmgcd == nil then
				data.attacker.WMB_taserreturndmgcd = data.attacker:DoTaskInTime(0.001, function(inst) inst.WMB_taserreturndmgcd = nil end)
				if taser_TryDamage(dmg, wx, data.attacker, data) then
					--单体电击特效
					if range <= 0 then SpawnPrefab("electrichitsparks"):AlignToTarget(data.attacker, wx, true) end
				end
			end	
		end
			
		--群体伤害
		if range > 0 and wx.WMB_taseraoecd == nil then
			wx.WMB_taseraoecd = wx:DoTaskInTime(0.001, function(inst) inst.WMB_taseraoecd = nil end)

			for _,ent in pairs(taser_GetTargets(dmg, range, wx)) do
			
				--防止反伤吃到增伤
				if ent.WMB_taserextradmgcd == nil then
					ent.WMB_taserextradmgcd = ent:DoTaskInTime(0.001, function(inst) inst.WMB_taserextradmgcd = nil end)
				end
			
				if ent.WMB_taserreturndmgcd == nil then
					ent.WMB_taserreturndmgcd = ent:DoTaskInTime(0.001, function(inst) inst.WMB_taserreturndmgcd = nil end)
					taser_TryDamage(dmg, wx, ent, data)
				end
			end
			
			--群体电击特效
			local scale = range * 1.25
			local fx = SpawnPrefab("electrichitsparks")
			fx.Transform:SetScale(scale, scale, scale)
			fx:AlignToTarget(wx, wx, true)
		end
    end
end

--电气化电路增伤
local function taser_onhitother(wx, data)
	if data and data.target and not data.redirected then
		local dmg = taserExtraDMG
		local range = taserExtraRange

		--冷却检查(防止伤害无限循环)
		if data.target.WMB_taserextradmgcd == nil then
			data.target.WMB_taserextradmgcd = data.target:DoTaskInTime(0.001, function(inst) inst.WMB_taserextradmgcd = nil end)
			if taser_TryDamage(dmg, wx, data.target, data) then
				--单体电击特效
				if range <= 0 then SpawnPrefab("electrichitsparks"):AlignToTarget(data.target, wx, true) end
			end
		end

		--群体伤害
		if range > 0 and wx.WMB_taseraoecd == nil then
			wx.WMB_taseraoecd = wx:DoTaskInTime(0.001, function(inst) inst.WMB_taseraoecd = nil end)

			for _,ent in pairs(taser_GetTargets(dmg, range, wx, data.attacker)) do
				if ent.WMB_taserextradmgcd == nil then
					ent.WMB_taserextradmgcd = ent:DoTaskInTime(0.001, function(inst) inst.WMB_taserextradmgcd = nil end)
					taser_TryDamage(dmg, wx, ent, data)
				end
			end
			
			--群体电击特效
			local scale = range * 1.25
			local fx = SpawnPrefab("electrichitsparks")
			fx.Transform:SetScale(scale, scale, scale)
			fx:AlignToTarget(wx, wx, true)
		end
	end		
end


--电气化电路激活
local function taser_activate(modu, wx)
	wx.WMB_tasernum = (wx.WMB_tasernum or 0) + 1

	--反伤和增伤
    if modu.WMB_onblocked == nil then
        modu.WMB_onblocked = taser_onblockedorattacked
    end
    if modu.WMB_taser_onhitother == nil then
        modu.WMB_taser_onhitother = taser_onhitother
    end	
	modu:ListenForEvent("blocked", modu.WMB_onblocked, wx)
	modu:ListenForEvent("attacked", modu.WMB_onblocked, wx)
	modu:ListenForEvent("onhitother", modu.WMB_taser_onhitother, wx)

	--设置绝缘
    if wx.components.inventory and wx.components.inventory.isexternallyinsulated then
        wx.components.inventory.isexternallyinsulated:SetModifier(modu, true)
    end
	
	--允许电击动作
	if wx.player_classified and wx.player_classified.WMB_taser_tag then
		wx.player_classified.WMB_taser_tag:set(true)
	end
	
	--空函数,用于防止其他修改电气化电路的模组读取不到原版的这个值导致崩溃
	if modu._onblocked == nil then
		modu._onblocked = function() end
	end
	modu:ListenForEvent("blocked", modu._onblocked, wx)
	modu:ListenForEvent("attacked", modu._onblocked, wx)	
end

--电气化电路关闭
local function taser_deactivate(modu, wx)
	wx.WMB_tasernum = math.max(0, (wx.WMB_tasernum or 0) - 1)

	--取消反伤增伤
	if modu.WMB_onblocked then 
		modu:RemoveEventCallback("blocked", modu.WMB_onblocked, wx)
		modu:RemoveEventCallback("attacked", modu.WMB_onblocked, wx)
	end
	if modu.WMB_taser_onhitother then
		modu:RemoveEventCallback("onhitother", modu.WMB_taser_onhitother, wx)
	end

	--取消设置绝缘
    if wx.components.inventory then
        wx.components.inventory.isexternallyinsulated:RemoveModifier(modu)
    end
	
	--取消电击动作
	if wx.WMB_tasernum <= 0 then	
		if wx.player_classified and wx.player_classified.WMB_taser_tag then
			wx.player_classified.WMB_taser_tag:set(false)
		end
	end	
	
	--空函数,用于防止其他修改电气化电路的模组读取不到原版的这个值导致崩溃
	if modu._onblocked ~= nil then
		modu:RemoveEventCallback("blocked", modu._onblocked, wx)
		modu:RemoveEventCallback("attacked", modu._onblocked, wx)
	end
end

--电气化电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "taser" then
		modu.activatefn, modu.deactivatefn = taser_activate, taser_deactivate
	end
end

-- AddPrefabPostInit("wx78module_taser", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- modu.components.upgrademodule.onactivatedfn = taser_activate
		-- modu.components.upgrademodule.ondeactivatedfn = taser_deactivate
    -- end
-- end)

local function WMB_ZAP_FN(doer, position)	
	if doer and doer.sg:HasState("wmb_zap") 
		and not doer.wmb_zap_doing
		and not IsInZapCD(doer)
	then
		doer.sg:GoToState("wmb_zap", {pos = position})
		
		--掉血
		if taser_zap_cost > 0 and doer.components.health then
			if doer.components.health:GetPercent() > 0.4 then			
				doer.components.health:DoDelta(-taser_zap_cost, false, doer.prefab)
			else
				if doer.components.upgrademoduleowner then
					doer.components.upgrademoduleowner:AddCharge(-1)
				end
			end
		end

		--冷却
		if taser_zap and taser_zap > 0 then		
			SetZapCD(doer)
		end

		return true
	end
end

--电击动作注册
local WMB_ZAP = Action({
	priority = 1.1, 
	rmb = true, 
	silent_fail = true,
	distance = math.huge, 
	instant = true, 
	do_not_locomote = true, 
})
WMB_ZAP.id = "WMB_ZAP"
WMB_ZAP.str = (LANG and "跳闸") or "Trip"
WMB_ZAP.fn = function(act)
	local target = act.pos or act.target
	if target then
		return WMB_ZAP_FN(act.doer, target:GetPosition())	
	end
end

AddAction(WMB_ZAP)

--电击状态注册
local zap_state = State{
    name = "wmb_zap",
    tags = { "busy", "no_stun", "canrotate", "nopredict" },
    onenter = function(inst, data)
		--下牛
		if inst.components.rider and inst.components.rider:IsRiding() then
			inst.components.rider:ActualDismount()
		end
	
        inst.wmb_zap_doing = true
        inst.AnimState:PlayAnimation("boat_jump_to_teeter")
		
		--动作期间无视实体碰撞(有点跳起来的感觉?)
		inst.Physics:ClearCollidesWith(COLLISION.OBSTACLES)
		inst.Physics:ClearCollidesWith(COLLISION.SMALLOBSTACLES)
		inst.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
		inst.Physics:ClearCollidesWith(COLLISION.GIANTS)
		
		--调整方向
        if data and data.pos then
            local pos = data.pos
            inst:ForceFacePoint(pos.x, 0, pos.z)
			
			--后坐力感?
			--if inst.components.locomotor and inst.components.locomotor.isrunning then
				local speed = math.clamp(inst.components.locomotor:GetRunSpeed() * 2, 12, 20)
				inst.Physics:SetMotorVelOverride(speed, 0, 0)
			--end
        end
		
		--复制的群伤
		do
			local dmg = taserReturnDMG
			local range = taserReturnRange
			if range < 2 then range = 2 end
			for _,ent in pairs(taser_GetTargets(dmg, range, inst)) do
			
				--防止反伤吃到增伤
				if ent.WMB_taserextradmgcd == nil then
					ent.WMB_taserextradmgcd = ent:DoTaskInTime(0.001, function(inst) inst.WMB_taserextradmgcd = nil end)
				end
			
				if ent.WMB_taserreturndmgcd == nil then
					ent.WMB_taserreturndmgcd = ent:DoTaskInTime(0.001, function(inst) inst.WMB_taserreturndmgcd = nil end)
					taser_TryDamage(dmg, inst, ent)
					
					--让目标进入电击状态(共享冷却)
					--参考自官方逻辑(commonstates.lua)
					local shock = true		
					do
						local delay = ent.electrocute_delay or TUNING.ELECTROCUTE_DEFAULT_DELAY
						local resist = ent._electrocute_resist or 0
						local t = GetTime()
						if ent._last_electrocute_time == nil or ent._last_electrocute_time + math.max(10 * delay.max, delay.max + resist) < t then
							shock = true
						elseif ent._last_electrocute_delay == nil then
							ent._last_electrocute_delay = GetRandomMinMax(delay.min, delay.max) + resist
						end
						if ent._last_electrocute_time and ent._last_electrocute_delay
							and ent._last_electrocute_time + ent._last_electrocute_delay > t
						then
							shock = false
						end
					end
					
					--防止梦魇疯猪卡住
					if ent.prefab == "daywalker" and not ent.hostile then
						shock = false
					end
					
					if shock then					
						ent:PushEvent("electrocute", { attacker = inst, stimuli = "electric" })
					end
				end
			end
			

			--群体电击特效
			local scale = range * 1.25
			local fx = SpawnPrefab("electrichitsparks")
			fx.Transform:SetScale(scale, scale, scale)
			fx:AlignToTarget(inst, inst, true)			
			
			local scale2 = range * 0.3
			local fx2 = SpawnPrefab("wmb_taser_fx")
			fx2.Transform:SetScale(scale2, scale2, scale2)
			fx2.Transform:SetPosition(inst:GetPosition():Get())
		end
    end,
    events = {
        EventHandler("animover", function(inst)
            inst.sg:GoToState("idle")
        end)
    },
    onexit = function(inst)
		inst.sg:RemoveStateTag("busy")
		inst.sg:RemoveStateTag("nopredict")	
		inst.Physics:CollidesWith(COLLISION.OBSTACLES)
		inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
		inst.Physics:CollidesWith(COLLISION.CHARACTERS)
		inst.Physics:CollidesWith(COLLISION.GIANTS)	
        inst:DoTaskInTime(0.1, function(inst)
			inst.wmb_zap_doing = nil
		end)
    end
}
local zap_state_client = State{
	name = "wmb_zap",
	tags = {"busy"},
	server_states = { "wmb_zap" },

	onenter = function(inst, data)
		inst.entity:SetIsPredictingMovement(false)
		inst.entity:FlattenMovementPrediction()
		inst.sg:SetTimeout(0.3)
		
		if data and data.pos then
			local pos = data.pos
			SendModRPCToServer(MOD_RPC["WMB_WX78Boosts"]["WMB_ZAP"], pos.x, pos.z)
		else
			local pos = TheInput:GetWorldPosition()		
			SendModRPCToServer(MOD_RPC["WMB_WX78Boosts"]["WMB_ZAP"], pos.x, pos.z)
		end
	end,

	onupdate = function(inst)
		if inst.sg:ServerStateMatches() and
			inst.entity:FlattenMovementPrediction() then
			inst.sg:GoToState("idle", "noanim")
		end
	end,

	ontimeout = function(inst)
		inst.sg:RemoveStateTag("busy")
		inst.sg:GoToState("idle", "noanim")
	end,

	onexit = function(inst)
		inst.sg:RemoveStateTag("busy")
		inst.entity:SetIsPredictingMovement(true)
	end,	
}
AddStategraphState("wilson", zap_state)
AddStategraphState("wilson_client", zap_state_client)

local function GetPointSpecialActions(inst, pos, useitem, right)
	if right 
		and useitem == nil 
		and HasTaserModu(inst)
		and not IsInZapCD(inst)
		and (inst.components.playercontroller == nil or not inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT))
	then
		return { ACTIONS.WMB_ZAP }
	end
    return {}
end

--电击动作期间不会受到伤害
AddComponentPostInit("combat", function(Combat)
    local oldfn = Combat.GetAttacked
    function Combat:GetAttacked(...)
		local inst = self.inst
        if inst and inst:IsValid() 
			and inst.components.health
			and not inst.components.health:IsDead()
			and inst.wmb_zap_doing
		then
			return
		end
        return oldfn(self, ...)
    end
end)

--电击动作期间不会累积冰冻层数
AddComponentPostInit("freezable", function(Freezable)
	local oldfn = Freezable.AddColdness
	function Freezable:AddColdness(...)
		local inst = self.inst
        if inst and inst:IsValid() 
			and inst.components.health
			and not inst.components.health:IsDead()
			and inst.wmb_zap_doing
		then
			return
		elseif oldfn then
			return oldfn(self, ...)
		end
	end
end)

--电击动作期间不会累积潮湿度
AddComponentPostInit("moisture", function(Moisture)
	local oldfn = Moisture.DoDelta
	function Moisture:DoDelta(num, ...)
		local inst = self.inst
        if num > 0
			and inst and inst:IsValid() 
			and inst.components.health
			and not inst.components.health:IsDead()
			and inst.wmb_zap_doing
		then
			return
		elseif oldfn then
			return oldfn(self, num, ...)
		end
	end
end)

--电击动作期间不会被点燃
AddComponentPostInit("burnable", function(Burnable)
    local oldfn = Burnable.Ignite
    function Burnable:Ignite(...)
		local inst = self.inst
        if inst and inst:IsValid() 
			and inst.components.health
			and not inst.components.health:IsDead()
			and inst.wmb_zap_doing
		then
			return
		end
        return oldfn(self, ...)
    end
end)

--允许在黑暗中使用电击动作(为什么不在动作设置里给接口呢)
--由于各种离奇bug弃用
-- AddComponentPostInit("playeractionpicker", function(PlayerActionPicker)
    -- local oldfn = PlayerActionPicker.DoGetMouseActions
    -- function PlayerActionPicker:DoGetMouseActions(position, target, spellbook, ...)
		-- --神秘bug,原版的inventory就没做判空
		-- if self.inst.replica.inventory == nil then
			-- return
		-- end
	
		-- if position == nil then
			-- local lmb,rmb = oldfn(self, position, target, spellbook, ...)
			-- local isaoetargeting = self.inst.components.playercontroller:IsAOETargeting()

			-- if isaoetargeting then
				-- position = self.inst.components.playercontroller:GetAOETargetingPos()
				-- spellbook = spellbook or self.inst.components.playercontroller:GetActiveSpellBook()
			-- else
				-- position = TheInput:GetWorldPosition()
				-- target = target or TheInput:GetWorldEntityUnderMouse()
			-- end

			-- local cansee
			-- if target == nil then
				-- local x, y, z = position:Get()
				-- cansee = CanEntitySeePoint(self.inst, x, y, z)
			-- else
				-- cansee = target == self.inst or CanEntitySeeTarget(self.inst, target)
			-- end

			-- if not cansee and rmb == nil and not isaoetargeting then
				-- local rmbs = self:GetRightClickActions(position, nil, spellbook)
				-- for i, v in ipairs(rmbs) do
					-- if (v.action == ACTIONS.WMB_ZAP) then
						-- return lmb, v
					-- end
				-- end
			-- end
		-- end

        -- return oldfn(self, position, target, spellbook, ...)
    -- end
-- end)

--动作期间各种补偿
AddStategraphPostInit("wilson", function(sg)
	
	--防击飞
    if sg.events and sg.events.knockback then
		local oldfn = sg.events.knockback.fn
		sg.events.knockback.fn = function(inst, ...)
			if not (inst.sg:HasStateTag("devoured") or inst.sg:HasStateTag("suspended")) and (inst.wmb_zap_doing or inst:HasTag("playerghost")) then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
    end	
	
	--防恶液黏住
    if sg.states and sg.states.suspended then
		local oldfn = sg.states.suspended.onenter
		sg.states.suspended.onenter = function(inst, ...)
			if inst.wmb_zap_doing or inst:HasTag("playerghost") then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
    end	
	
	--防冰冻
	if sg.events and sg.events.freeze then
		local oldfn = sg.events.freeze.fn
		sg.events.freeze.fn = function(inst, ...)
			if inst.wmb_zap_doing or inst:HasTag("playerghost") then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
	end

end)



--设置右键动作
if taser_zap then

--重要动作
local ImportantAction = {
	["MOUNT"] = true, --上牛
	["DISMOUNT"] = true, --下牛
	["CHARGE_FROM"] = true, --充电
	["TAKEITEM"] = true, --拿取物品
	["HARVEST"] = true, --收获
	["PICKUP"] = true, --采集
	["WMB_DISCHARGE"] = true, --本模组的输电
	["WAP_RECYCLE"] = true, --WX自动化补丁mod的回收月眼守卫
}

local function OnSetOwner(inst)
    if inst.components.playeractionpicker ~= nil then
		local oldfn = inst.components.playeractionpicker.pointspecialactionsfn or function() return {} end
		inst.components.playeractionpicker.pointspecialactionsfn = function(...)
			local actions = oldfn(...)
			return (#actions > 0 and actions) or GetPointSpecialActions(...)
		end
	end
end

AddPrefabPostInit("wx78", function(wx)
	wx:ListenForEvent("setowner", function(wx)
		wx:DoTaskInTime(0.1, OnSetOwner)
	end)
end)

--防止实体遮挡(参考自棱镜盾反)
local function WMB_AddComponentActionfunction(inst, doer, actions, right)
	if right
		and HasTaserModu(doer)
		and inst ~= doer 
		and inst.components.spellbook == nil 
		and doer.replica.inventory ~= nil
		and (not inst:HasTag("heavy")) --不要影响重物
		and (not inst:HasTag("prototyper")) --不要影响科技站
		and (inst.replica.container == nil or not inst.replica.container:CanBeOpened()) --不要影响容器
		and (doer.HUD == nil or not doer.HUD:IsSpellWheelOpen()) --不要影响按钮轮盘
		and (doer.components.playercontroller == nil or not doer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT))
	then
		--检测重要动作
		for _,action in ipairs(actions) do
			if ImportantAction[action.id] then
				return
			end
		end
		table.insert(actions, ACTIONS.WMB_ZAP)
	end
end
AddComponentAction("SCENE", "inspectable", WMB_AddComponentActionfunction)
AddComponentAction("SCENE", "combat", WMB_AddComponentActionfunction)

AddModRPCHandler("WMB_WX78Boosts","WMB_ZAP", function(player, x, z)
	WMB_ZAP_FN(player, Point(x,0,z))
end)

--实现爆气解控效果?
if not TheNet:IsDedicated() then

--检查是否有电击动作
local function HasAction(player)
	if player.prefab ~= "wx78" then return false end
	if not HasTaserModu(player) then return false end
	if not player:HasTag("busy") then return false end --仅在busy时触发防止误触
	if player:HasTag("playerghost") then return false end

	if player.components.playeractionpicker and player.replica.inventory then
		local item = (player.replica.inventory and player.replica.inventory:GetActiveItem()) or nil
		local lmb,rmb = player.components.playeractionpicker:DoGetMouseActions()
		if rmb and rmb.action and rmb.action == ACTIONS.WMB_ZAP then
			return true
		end
	end
	
	return false
end

local isHolding = false

TheInput:AddControlHandler(CONTROL_SECONDARY, function(down)
	if down then
		if not isHolding then
			isHolding = true
			if TheInput:GetHUDEntityUnderMouse() then return end
			local player = ThePlayer; if not player or not player.HUD then return end
			if player.HUD:HasInputFocus() then return end
			if player.HUD:IsSpellWheelOpen() then return end		
			if player.HUD.controls and not player.HUD.controls.craftingandinventoryshown then return end
			
			local pos = TheInput:GetWorldPosition()
			if HasAction(player) then
				local pc = player.components.playercontroller
				if pc then
					if pc.locomotor then
						--为主机
						WMB_ZAP_FN(player, pos)
					else				
						--为客机
						SendModRPCToServer(MOD_RPC["WMB_WX78Boosts"]["WMB_ZAP"], pos.x, pos.z)
					end
				end
			end
		end
	else
		isHolding = false
	end
end)

end

end


--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_taser", function(modu)
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