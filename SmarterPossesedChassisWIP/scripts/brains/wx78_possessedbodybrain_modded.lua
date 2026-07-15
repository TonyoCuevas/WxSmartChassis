require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/standstill"
require "behaviours/runtodist"
require "behaviours/runaway"

-- #GLOOMERANG_HACK
    -- Ugly gloomerang hack.. When it runs out of stock, it sets its range to 0 so the possessed body tries to run up to the target.
    -- The gloomerang is at fault here, never add a weapon that works like it again!

local BrainCommon = require("brains/braincommon")
local WX78Common = require("prefabs/wx78_common")

local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 50

local TRADE_DIST = 20

local FOLLOW_MIN_DIST = 1
local FOLLOW_TARGET_DIST = 4
local FOLLOW_MAX_DIST = 5

local STANDBY_TAG = "wx78_chassis_standby"
local STANDBY_EMOTE_DATA = {
    anim = { { "emote_pre_sit2", "emote_loop_sit2" }, { "emote_pre_sit4", "emote_loop_sit4" } },
    randomanim = true,
    loop = true,
    fx = false,
    mounted = true,
    mountsound = "walk",
    mountsounddelay = 6 * FRAMES,
}

--------------------------------------------------------------------------------------------------------------------------------

local Wx78_PossessedBodyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function GetInteractorFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, TRADE_DIST, true)
    for _, player in ipairs(players) do
        if inst.components.trader:IsTryingToTradeWithMe(player) or inst.components.eater:IsTryingToFeedMe(player) or inst.components.container_transform:IsTryingToOpenMe(player) then
            return player
        end
    end
end

local function KeepInteractorFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target) or inst.components.eater:IsTryingToFeedMe(target) or inst.components.container_transform:IsTryingToOpenMe(target)
end

local function GetLeader(inst)
	return inst.components.follower and inst.components.follower:GetLeader()
end

local function GetFaceLeaderFn(inst)
    return GetLeader(inst)
end

local function KeepFaceLeaderFn(inst, target)
    return GetLeader(inst) == target
end

--------------------------------------------------------------------------------------------------------------------------------

local function GetTool(inst)
    return inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
end

local function CanToolDoAction(tool, action)
    -- tool:CanDoAction is for till
    return ((tool.components.tool ~= nil and tool.components.tool:CanDoAction(action)) or tool:CanDoAction(action))
        or (action == ACTIONS.ROW and tool.components.oar ~= nil)
end

local function HasToolForAction(inst, action, tryequip)
    local tool = GetTool(inst)
    if tool ~= nil and CanToolDoAction(tool, action) then
        return true
    end

    -- Equip next available tool
    local nexttool = inst.components.inventory:FindItem(function(item)
        return item.components.equippable ~= nil and not item.components.equippable:IsRestricted(inst)
            and CanToolDoAction(item, action)
    end)

    if nexttool ~= nil then
        if tryequip then
            inst.components.inventory:Equip(nexttool)
        end
        return true
    end
end

local function GetLeaderAction(inst)
    local act = inst:GetBufferedAction() or inst.sg.statemem.action
	if act then
		return act.action, act.target, act:GetActionPoint()
	end

	if inst._lastspintime then
		if inst.sg:HasStateTag("spinning") then
			if GetTime() - inst._lastspintime < 1 then
				return inst._lastspinaction, inst._lastspintarget
			end
		elseif inst:HasTag("using_drone_remote") then
			return inst._lastspinaction, inst._lastspintarget
		end
	end

	if inst.components.playercontroller then
		return inst.components.playercontroller:GetRemoteInteraction()
	end
end

local function IsLeaderAttacking(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        local leaderact, leadertarget = GetLeaderAction(leader)
        if leaderact == ACTIONS.ATTACK then
            return true
        end

        if leader.components.combat.target ~= nil then
            return true
        end
    end
end

local function IsLeaderMoving(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        return leader.components.locomotor ~= nil and leader.components.locomotor:WantsToMoveForward()
    end
end

local function Create_Starter(action, notool)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == action and (notool or HasToolForAction(inst, action, true))
        end
    end
end

local function Create_KeepGoing(action)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == action
        end
    end
end

local function Create_FindNew(action, notool)
    return function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == action
                and BufferedAction(inst, leadertarget, action, (not notool and GetTool(inst) or nil))
                or nil
        end
    end
end

-- action field is Required.
local NODE_ASSIST_CHOP_ACTION =
{
    action = "CHOP",
    starter = Create_Starter(ACTIONS.CHOP),
    keepgoing = Create_KeepGoing(ACTIONS.CHOP),
    finder = Create_FindNew(ACTIONS.CHOP),
    shouldrun = true,
}
local NODE_ASSIST_MINE_ACTION =
{
    action = "MINE",
    starter = Create_Starter(ACTIONS.MINE),
    keepgoing = Create_KeepGoing(ACTIONS.MINE),
    finder = Create_FindNew(ACTIONS.MINE),
    shouldrun = true,
}
local NODE_ASSIST_HAMMER_ACTION =
{
    action = "HAMMER",
    starter = Create_Starter(ACTIONS.HAMMER),
    keepgoing = Create_KeepGoing(ACTIONS.HAMMER),
    finder = Create_FindNew(ACTIONS.HAMMER),
    shouldrun = true,
}
local NODE_ASSIST_DIG_ACTION =
{
    action = "DIG",
    starter = Create_Starter(ACTIONS.DIG),
    keepgoing = Create_KeepGoing(ACTIONS.DIG),
    -- We don't want to dig the same thing
    shouldrun = true,
}
local NODE_ASSIST_TILL_ACTION =
{
    action = "TILL",
    starter = Create_Starter(ACTIONS.TILL),
    keepgoing = Create_KeepGoing(ACTIONS.TILL),
    -- Use regular till finding logic
    shouldrun = true,
}

local function IsValidAnchorToRaise(anchor)
    return anchor ~= nil and (not anchor:HasTag("anchor_raised") or anchor:HasTag("anchor_transitioning"))
end
local NODE_ASSIST_RAISE_ANCHOR_ACTION =
{
    action = "RAISE_ANCHOR",
    starter = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.RAISE_ANCHOR and IsValidAnchorToRaise(leadertarget)
        end
    end,
    keepgoing = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.RAISE_ANCHOR and IsValidAnchorToRaise(leadertarget)
        end
    end,
    finder = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return (leaderact == ACTIONS.RAISE_ANCHOR and IsValidAnchorToRaise(leadertarget))
                and BufferedAction(inst, leadertarget, ACTIONS.RAISE_ANCHOR)
                or nil
        end
    end,
    shouldrun = true,
}
local NODE_ASSIST_ROW_ACTION =
{
    action = "ROW",
    starter = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return (leaderact == ACTIONS.ROW or leaderact == ACTIONS.ROW_CONTROLLER) and HasToolForAction(inst, ACTIONS.ROW, true)
        end
    end,
    keepgoing = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.ROW or leaderact == ACTIONS.ROW_CONTROLLER
        end
    end,
    finder = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget, leaderpos = GetLeaderAction(leader)
            if leaderact == ACTIONS.ROW or leaderact == ACTIONS.ROW_CONTROLLER or leaderact == ACTIONS.ROW_FAIL then
                if leaderact == ACTIONS.ROW_CONTROLLER then
                    leaderact = ACTIONS.ROW -- Always use the ROW action for non-players.
                    local platform = leader:GetCurrentPlatform()
                    local leaderx, leadery, leaderz = leader.Transform:GetWorldPosition()
                    if platform ~= nil then
	                    local boat_x, boat_y, boat_z = platform.Transform:GetWorldPosition()
	                    local dir_x, dir_z = VecUtil_Normalize(leaderx - boat_x, leaderz - boat_z)
                        local test_length = 2
                        local test_x, test_z = leaderx + dir_x * test_length, leaderz + dir_z * test_length
                        local found_water = not TheWorld.Map:IsVisualGroundAtPoint(test_x, 0, test_z) and TheWorld.Map:GetPlatformAtPoint(test_x, test_z) == nil
                        if found_water then
                            leaderpos = Vector3(test_x, 0, test_z)
                        end
                    end
                end
                return BufferedAction(inst, leadertarget, leaderact, GetTool(inst), leaderpos)
            end
        end
    end,
    shouldrun = true,
}

local function IsValidToLowerSailBoost(inst, leader, leadertarget)
    return (inst.sg.mem.furl_target ~= leadertarget)
        or (inst.sg.currentstate.name == "furl" and leader.sg.currentstate.name == "furl_boost")
end
local NODE_ASSIST_LOWER_SAIL_ACTION =
{
    action = "LOWER_SAIL",
    starter = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return (leaderact == ACTIONS.LOWER_SAIL_BOOST or leaderact == ACTIONS.LOWER_SAIL_FAIL)
                and IsValidToLowerSailBoost(inst, leader, leadertarget)
        end
    end,
    keepgoing = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.LOWER_SAIL_BOOST or leaderact == ACTIONS.LOWER_SAIL_FAIL
                and IsValidToLowerSailBoost(inst, leader, leadertarget)
        end
    end,
    finder = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            if (leaderact == ACTIONS.LOWER_SAIL_BOOST or leaderact == ACTIONS.LOWER_SAIL_FAIL)
                and IsValidToLowerSailBoost(inst, leader, leadertarget) then
                return BufferedAction(inst, leadertarget, leaderact)
            end
        end
    end,
    shouldrun = true,
}
local NODE_ASSIST_SOAKIN_ACTION =
{
    action = "SOAKIN",
    starter = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.SOAKIN or leader.sg.statemem.occupying_bathingpool ~= nil
        end
    end,
    keepgoing = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.SOAKIN or leader.sg.statemem.occupying_bathingpool ~= nil
        end
    end,
    finder = function(inst, leaderdist, finddist)
        local leader = GetLeader(inst)
        if leader ~= nil then
            local leaderact, leadertarget = GetLeaderAction(leader)
            return leaderact == ACTIONS.SOAKIN
                and BufferedAction(inst, leadertarget, ACTIONS.SOAKIN)
                or nil
        end
    end,
    shouldrun = true,
}

local SpDamageUtil = require("components/spdamageutil")
local function IsValidZapRemote(inst, item)
    return item:HasTag("wx_remotecontroller")
        and item.components.equippable ~= nil
        and not item.components.equippable:IsRestricted(inst)
        and (item.components.finiteuses == nil or item.components.finiteuses:GetUses() > 0)
end

-- MODDED: weapon "tiers" so ranged weapons are picked over tools.
local function IsRangedWeapon(item)
    return item ~= nil
        and item.components.weapon ~= nil
        and item:HasTag("rangedweapon")
end

local WEAPON_TIER_MELEE = 1
local WEAPON_TIER_RANGED = 2
local WEAPON_TIER_TOOL = 3 -- lowest priority: only used as a weapon as a last resort
local function GetWeaponTier(item)
    if item == nil or item.components.weapon == nil then
        return nil
    elseif IsRangedWeapon(item) then
        return WEAPON_TIER_RANGED
    elseif item.components.tool ~= nil or item:HasTag("tool") then
        return WEAPON_TIER_TOOL
    end
    return WEAPON_TIER_MELEE
end

local function IsWeaponBetter(inst, weapon1, weapon2, target)
    if weapon2 == nil or not weapon2.components.weapon then
        return true
    elseif weapon1 == nil or not weapon1.components.weapon then
        return false
    end

    -- MODDED: a higher priority tier always wins, regardless of raw damage.
    local tier1, tier2 = GetWeaponTier(weapon1), GetWeaponTier(weapon2)
    if tier1 ~= tier2 then
        return tier1 < tier2
    end

    local itemdmg, itemspdmg = inst.components.combat:CalcDamage(target, weapon1)
    local dmg, spdmg = inst.components.combat:CalcDamage(target, weapon2)

	itemspdmg = SpDamageUtil.CalcTotalDamage(SpDamageUtil.ApplySpDefense(target, itemspdmg))
	spdmg = SpDamageUtil.CalcTotalDamage(SpDamageUtil.ApplySpDefense(target, spdmg))

    return (itemdmg + itemspdmg) > (dmg + spdmg)
end

-- Keep in sync with wagdrone_projectile::WX78_DRONE_ZAP_TARGET_NOTAGS_PVP
local WX78_DRONE_ZAP_TARGET_NOTAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack", "ghost", "playerghost", "shadowthrall", "shadow", "shadowcreature", "shadowminion", "shadowchesspiece", "brightmare", "brightmareboss", "electric_connector", "wall", "companion" }
local function EquipBestWeapon(inst, target)
    -- Prioritize zap drone!
    local heldweapon = GetTool(inst)
    if not target:HasAnyTag(WX78_DRONE_ZAP_TARGET_NOTAGS) then
        local zap_drone = inst.components.inventory:FindItem(function(item) return IsValidZapRemote(inst, item) end)
        if zap_drone and zap_drone ~= heldweapon and (heldweapon == nil or not IsValidZapRemote(inst, heldweapon)) then
            inst.components.inventory:Equip(zap_drone)
            inst._is_ranged_weapon = IsRangedWeapon(zap_drone)
            return
        elseif heldweapon and IsValidZapRemote(inst, heldweapon) then
            inst._is_ranged_weapon = IsRangedWeapon(heldweapon)
            return
        end
    elseif heldweapon and IsValidZapRemote(inst, heldweapon) then
        inst.components.inventory:GiveItem(heldweapon)
    end

    -- Find highest damage weapon to use
    -- Not the best since it doesnt take into account damage multipliers, can be improved.
    local bestweapon
    inst.components.inventory:ForEachItem(function(item)
        if item.components.weapon ~= nil
            and (bestweapon == nil or IsWeaponBetter(inst, item, bestweapon, target)) then
            bestweapon = item
        end
    end)
    if bestweapon and bestweapon ~= heldweapon and IsWeaponBetter(inst, bestweapon, heldweapon, target) then
        inst.components.inventory:Equip(bestweapon)
        heldweapon = bestweapon
    end

    -- MODDED: cache whether we're wielding a ranged weapon here, at selection time, so
    -- other brain logic (kiting range while the leader isn't attacking) doesn't need to
    -- re-check the weapon every tick.
    inst._is_ranged_weapon = IsRangedWeapon(heldweapon)
end

local function SetTargetOnLeaderTarget(inst)
    local leader = GetLeader(inst)
    if leader ~= nil then
        local leaderact, leadertarget = GetLeaderAction(leader)
        if leaderact == ACTIONS.ATTACK and leadertarget ~= nil then
            inst.components.combat:SetTarget(leadertarget)
            EquipBestWeapon(inst, leadertarget)
        elseif leader.components.combat.target ~= nil then
            inst.components.combat:SetTarget(leader.components.combat.target)
            EquipBestWeapon(inst, leader.components.combat.target)
        end
    end
end

--MODDED: no emote for standby mode --

local function ShouldEmote(inst)
    local leader = GetLeader(inst)
    return not inst:HasTag(STANDBY_TAG)
        and inst._brain_emotedata ~= nil
        and leader ~= nil and leader.sg.currentstate.name == "emote"
        and not inst.sg:HasStateTag("emoting")
end

local function DoEmote(inst)
    if inst:HasTag(STANDBY_TAG) then
        return
    end
    inst:PushEventImmediate("emote", inst._brain_emotedata)
end

-- MODDED: Sitting emote for standby function
local function DoStandbySit(inst)
    -- NUEVO: Si el chasis salió del estado "emote" (por ejemplo, replicó al jugador o se movió),
    -- reseteamos nuestra variable de control para que vuelva a sentarse.
    if inst._chassis_sitting and (inst.sg == nil or not inst.sg:HasStateTag("emoting")) then
        inst._chassis_sitting = false
    end

    if inst._chassis_sitting then
        return
    end
    inst._chassis_sitting = true

    local emotes = GetCommonEmotes()
    local sitdata = emotes and emotes.sit and emotes.sit.data

    if sitdata ~= nil then
        inst._brain_emotedata = sitdata
        inst:PushEventImmediate("emote", inst._brain_emotedata)

        -- Ese onupdate del estado "emote" nos devuelve a "idle" si el líder
        -- no está también emoteando (es para sincronizarse con él, no aplica aquí)
        if inst.sg ~= nil and inst.sg.statemem ~= nil then
            inst.sg.statemem.loopingemote = nil
        end
    end
end

-- MODDED: Now can eat while in combat
local function EatFoodAction(inst)
        -- We're well topped off, just return for optimization sake.
        local ishurt = inst.components.health:GetPercent() <= 0.9
        if ishurt or inst.components.hunger:GetPercent() <= 0.9 or inst.components.sanity:GetPercent() <= 0.9 then
            local health = inst.components.health.currenthealth
            local hunger = inst.components.hunger.current
            local sanity = inst.components.sanity.current

            local maxhealth = inst.components.health:GetMaxWithPenalty() * 1.1 -- Some leniency for healing.
            local maxhunger = inst.components.hunger.max
            local maxsanity = inst.components.sanity:GetMaxWithPenalty()

            local besthealth
            local besthunger
            local bestsanity

            inst.components.inventory:ForEachItem(function(item)
                local edible = item.components.edible
                if edible ~= nil and inst.components.eater:CanEat(item) then
                    local itemhealth = edible:GetHealth(inst)
                    local itemhunger = edible:GetHunger(inst)
                    local itemsanity = edible:GetSanity(inst)

                    if itemhealth >= TUNING.HEALING_MEDSMALL and (health + itemhealth) <= maxhealth
                        and ishurt then -- check if we're hurt, for the leniency added above
                        if besthealth == nil or (itemhealth > besthealth.components.edible:GetHealth(inst)) then
                            besthealth = item
                        end
                    elseif itemhunger > 0 and (hunger + itemhunger) <= maxhunger then
                        if besthunger == nil or (itemhunger > besthunger.components.edible:GetHunger(inst)) then
                            besthunger = item
                        end
                    elseif itemsanity >= TUNING.SANITY_SMALL and (sanity + itemsanity) <= maxsanity then
                        if bestsanity == nil or (itemsanity > bestsanity.components.edible:GetSanity(inst)) then
                            bestsanity = item
                        end
                    end
                end
            end)

            local foodtoeat = besthealth or besthunger or bestsanity
            if foodtoeat ~= nil then
                return BufferedAction(inst, foodtoeat, ACTIONS.EAT)
            end
        end

        if inst.components.eater:IsSpoiledProcessor() then
            local spoiledtoeat = inst.components.inventory:FindItem(function(item)
                local edible = item.components.edible
                return edible ~= nil
                    and inst.components.eater:CanEat(item)
                    and inst.components.eater:CanProcessSpoiledItem(item)
            end)

            if spoiledtoeat ~= nil then
                return BufferedAction(inst, spoiledtoeat, ACTIONS.EAT)
            end
        end
end

--MODDED: now can repair in combat
local function DoForgeRepairAction(inst)

    local repair_kits = {} -- [type] = item
    inst.components.inventory:ForEachItem(function(item)
        if item.components.forgerepair ~= nil
            and item.components.forgerepair.repairmaterial ~= nil
            and repair_kits[item.components.forgerepair.repairmaterial] == nil then
            repair_kits[item.components.forgerepair.repairmaterial] = item
        end
    end)

    local itemtorepair = inst.components.inventory:FindItem(function(item)
        return item:HasTag("broken")
            and item.components.forgerepairable ~= nil
            and item.components.forgerepairable.repairmaterial ~= nil
            and repair_kits[item.components.forgerepairable.repairmaterial]
    end)

    if itemtorepair then
        local repairkit = repair_kits[itemtorepair.components.forgerepairable.repairmaterial]
        local buffaction = BufferedAction(inst, itemtorepair, ACTIONS.REPAIR, repairkit)

        buffaction:AddSuccessAction(function()
            if itemtorepair and itemtorepair.components.equippable and not itemtorepair.components.equippable:IsRestricted(inst) then
                local equipslot = itemtorepair.components.equippable.equipslot
                if not inst.components.inventory:GetEquippedItem(equipslot) then
                    inst.components.inventory:Equip(itemtorepair)
                end
            end
        end)

        return buffaction
    end
end

local function DoUpgradeModuleAction(inst)
    if inst.sg:HasStateTag("busy") or (inst.last_upgrade_module_action and GetTime() - inst.last_upgrade_module_action < 5)then
        return
    end

    local actions = {}
    inst:CollectUpgradeModuleActions(actions)
    for i, v in ipairs(actions) do
        inst.last_upgrade_module_action = GetTime()
        return BufferedAction(inst, nil, v)
    end
end

local function RescueLeaderAction(inst)
    return BufferedAction(inst, GetLeader(inst), ACTIONS.UNPIN)
end

local KEEP_LAST_TARGET_TIME = 4
local function GetTarget(inst)
	local target = inst.components.combat.target
	if target == nil then
		local leader = GetLeader(inst)
		if leader then
			local leaderact, leadertarget = GetLeaderAction(leader)
			if leaderact == ACTIONS.ATTACK and leadertarget and leadertarget:IsValid() then
				target = leadertarget
			end
		end
		if target == nil then
			local last_target = Ents[inst.components.combat.lasttargetGUID]
			if last_target then
				if GetTime() - (inst.components.combat.laststartattacktime or 0) < KEEP_LAST_TARGET_TIME then
					--keep last target for at least [KEEP_LAST_TARGET_TIME] seconds
					target = last_target
				else
					--otherwise keep last target as long as they're still in combat with us
					local theirtarget = last_target.components.combat and last_target.components.combat.target
					if theirtarget and inst.components.combat:IsAlly(theirtarget) then
						target = last_target
					end
				end
			end
		end
	end
	return target and not IsEntityDead(target) and target or nil
end

local DROP_TARGET_KITE_DIST_SQ = 14 * 14
local function LeaderInRangeOfTarget(inst)
    local leader = GetLeader(inst)
    local target = GetTarget(inst)
    if leader ~= nil and target ~= nil then
        if leader:GetDistanceSqToInst(target) > DROP_TARGET_KITE_DIST_SQ then
            inst.components.combat:SetTarget(nil)
            return false
        end
    end
    return true
end

--MODDED: runaway behaviour
local FLEE_SEARCH_DIST = 10      -- radio for detecting threats
local FLEE_DIST        = 5      -- minimum distance from threat
local FLEE_STOP_DIST   = 8      -- distancewhich to stop from threat
local FLEE_MAX_DIST_FROM_LEADER = 15  -- maximum distance away from leader

local function GetFleeTarget(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    -- 1. For fires
    local fires = TheSim:FindEntities(x, y, z, FLEE_SEARCH_DIST, { "fire" }, { "INLIMBO" })
    if #fires > 0 then
        return fires[1]
    end

    -- 2. Avoid runaway if leader is in combat
    local leader = GetLeader(inst)
    if leader ~= nil
        and leader.components.combat ~= nil
        and leader.components.combat.target ~= nil then
        return nil
    end

    -- 3. Runaway if the chassis is target of threat outside of combat
    local ents = TheSim:FindEntities(x, y, z, FLEE_SEARCH_DIST, nil,
        { "INLIMBO", "noattack", "player", "companion", "wall" }, { "_combat" })
    for _, ent in ipairs(ents) do
        if ent ~= inst
            and ent.prefab ~= inst.prefab
            and ent.components.combat ~= nil
            and inst.components.combat ~= nil
            and not inst.components.combat:IsAlly(ent)
            and ent.components.combat.target == inst then
            return ent
        end
    end

    -- 4. Burning
    if inst.components.burnable and inst.components.burnable:IsBurning() then
        return inst
    end
end

local function IsAttackingOrEating(inst)
    return inst.sg:HasStateTag("attack")
end

local function ShouldFlee(inst)
    if IsAttackingOrEating(inst) then
        return false
    end
    local leader = GetLeader(inst)
    if leader and inst:GetDistanceSqToInst(leader) > FLEE_MAX_DIST_FROM_LEADER * FLEE_MAX_DIST_FROM_LEADER then
        return false
    end
    inst._flee_target = GetFleeTarget(inst)
    return inst._flee_target ~= nil
end

local RUNTODIST_PARAM = { getfn = GetTarget }
local MAX_KITE_DIST = 10
local TOLERANCE_DIST = .75

local function GetAttackRange(inst)
    if not IsLeaderAttacking(inst) then
        -- MODDED: if we're holding a ranged weapon (cached at selection time in
        -- EquipBestWeapon), keep our attack range/kiting distance even while the leader
        -- isn't attacking, as long as the leader is still within kiting range of the target.
        if inst._is_ranged_weapon then
            local leader = GetLeader(inst)
            local target = GetTarget(inst)
            if leader == nil or target == nil or leader:GetDistanceSqToInst(target) > MAX_KITE_DIST * MAX_KITE_DIST then
                return 0
            end
            -- fall through to the normal range calculation below
        else
            return 0 -- So that ranged attackers don't just constantly run back and forth to the target
        end
    end

    local weapon = GetTool(inst)
    if weapon then
        -- #GLOOMERANG_HACK
        if weapon.prefab == "voidcloth_boomerang" then
            return TUNING.VOIDCLOTH_BOOMERANG_ATTACK_DIST
        elseif weapon:HasTag("wx_remotecontroller") then
			local max_range = WX78Common.CalcDroneZapRange(inst)
			local range = math.sqrt(max_range) * 2.4
			return range, 6, max_range
        end
    end

	if inst.sg:HasStateTag("spinning") then
		return TUNING.WX78_SPIN_START_RANGE, TUNING.WX78_SPIN_RADIUS - 0.5
	end

    return inst.components.combat:GetAttackRange()
end

local function UseDroneRemoteAction(inst)
    if inst.sg:HasStateTag("doing") then
        return
    end
    local heldweapon = GetTool(inst)
    if heldweapon and heldweapon:HasTag("wx_remotecontroller") then
        local attack_range = GetAttackRange(inst)
        local target = GetTarget(inst)
        if target and target:IsValid() then
            local dist_to_target = math.sqrt(inst:GetDistanceSqToInst(target))
            if dist_to_target < attack_range then
                return BufferedAction(inst, nil, ACTIONS.USEEQUIPPEDITEM, heldweapon)
            end
        end
    end
end

local function GetRunDist(inst, hunter)
	local attack_range, min_range, max_range = GetAttackRange(inst)
	local using_drone = min_range ~= nil and max_range ~= nil
	if not using_drone then
		attack_range = math.max(0, attack_range + hunter:GetPhysicsRadius(0) - 0.5)
	end

    local leader = GetLeader(inst)
    if leader ~= nil then
        local leader_dist = math.sqrt(leader:GetDistanceSqToInst(hunter))
        local dist = math.max(attack_range, math.min(leader_dist, MAX_KITE_DIST))
        if inst._lastdist == nil or (math.abs(inst._lastdist - dist) >= TOLERANCE_DIST) then
            inst._lastdist = dist
            return dist
        else
            return inst._lastdist
        end
    end

    return 1 -- Shrug?
end

local function ShouldMoveAnyways(inst)
    local leader = GetLeader(inst)
    local target = GetTarget(inst)
    if leader ~= nil and target ~= nil then
		local attack_range, min_range, max_range = GetAttackRange(inst)
        local dist_to_target = math.sqrt(inst:GetDistanceSqToInst(target))

        ------
        -- :,) copy of some RunToDist:GetRunPosition logic. Make sure we actually have a valid offset we're going to move to, otherwise we can't move, so just attack.
        local pt = inst:GetPosition()
    	local angle = inst:GetAngleToPoint(target:GetPosition()) + 180
        if angle > 360 then
            angle = angle - 360
        end
        local result_offset, result_angle, deflected = FindWalkableOffset(pt, angle*DEGREES, GetRunDist(inst, target), 8, true, false, nil, false, true) -- try avoiding walls
        if result_offset == nil then
            return false
        end
        ------

		local using_drone = min_range ~= nil and max_range ~= nil
		if using_drone then
			local deployed = inst:HasTag("using_drone_remote")
			if deployed then
				if dist_to_target >= max_range then
					return true --target is out of max range
				elseif dist_to_target >= min_range then
					return false --target is not too close, don't move
				end
			end
			if math.abs(dist_to_target - attack_range) <= 1 then
				return false
			end
			local leader_dist = math.sqrt(leader:GetDistanceSqToInst(target)) + 0.5
			if deployed and leader_dist < dist_to_target then
				return false
			end
			return attack_range >= leader_dist
		end

		local physrad = target:GetPhysicsRadius(0)
		if min_range then
			min_range = min_range + physrad
		end
		attack_range = attack_range + physrad

		if min_range and inst.sg:HasStateTag("spinning") then
			if dist_to_target >= min_range - 1 and dist_to_target <= attack_range + 1 then
				return false
			end
		elseif dist_to_target >= attack_range - 1 and dist_to_target < attack_range then
			return false
		end

		local leader_dist = math.sqrt(leader:GetDistanceSqToInst(target)) + 0.5
        return attack_range >= leader_dist
    end
end

local function ShouldAttack(inst)
    -- #GLOOMERANG_HACK
    local item = GetTool(inst)
    if item and item.prefab == "voidcloth_boomerang" and item.components.rechargeable and not item.components.rechargeable:IsCharged() then
        return false
    end

    return true
end
--------------------------------------------------------------------------------------------------------------------------------

-- MODDED: new priority nodes for more actions to take into account
local UPDATE_RATE = 0.1
local STOP_USING_DRONE_DELAY = 3
function Wx78_PossessedBodyBrain:OnStart()
    local root = PriorityNode(
    {
        -- 0: Standby (máxima prioridad)
        WhileNode(function() return self.inst:HasTag(STANDBY_TAG) end, "Chassis Standby",
            ActionNode(function() DoStandbySit(self.inst) end)),

		WhileNode(function()
			return not self.inst.sg:HasStateTag("jumping")
				or self.inst.sg:HasAnyStateTag("prespin", "spinning")
		end,
        "<busy state guard",
        PriorityNode({

            -- 1: Runaway
            WhileNode(function() return ShouldFlee(self.inst) end, "Fleeing danger",
                RunAway(self.inst, GetFleeTarget, FLEE_DIST, FLEE_STOP_DIST)),

            FaceEntity(self.inst, GetInteractorFn, KeepInteractorFn),

            WhileNode(function() local leader = GetLeader(self.inst) return leader and leader.components.pinnable and leader.components.pinnable:IsStuck() end, "Leader Phlegmed",
                DoAction(self.inst, RescueLeaderAction, "Rescue Leader", true)),

            -- 2: Attack
			WhileNode(
				function()
                    if not LeaderInRangeOfTarget(self.inst) then
                        self._last_drone_time = nil
                        return false
                    end
					if IsLeaderAttacking(self.inst) and not ShouldMoveAnyways(self.inst) then
						self._last_drone_time = self.inst:HasTag("using_drone_remote") and GetTime() or nil
						return true
					elseif self._last_drone_time then
						if self.inst:HasTag("using_drone_remote") and GetTime() - self._last_drone_time < STOP_USING_DRONE_DELAY then
							return true
						end
						self._last_drone_time = nil
					end
					return false
				end,
				"is leader attacking",
				ParallelNodeAny{
					ConditionWaitNode(function()
						SetTargetOnLeaderTarget(self.inst)
						return false
					end),
					PriorityNode({
						FailIfSuccessDecorator(ConditionWaitNode(function()
                            if self.inst:HasTag("using_drone_remote") then
								self.inst:PushEventImmediate("ms_wx_clone_use_drone_zap_attack", { doattack = IsLeaderAttacking(self.inst) })
								return false
							end
							return true
						end)),
						DoAction(self.inst, UseDroneRemoteAction, nil, true),
                        WhileNode(function() return ShouldAttack(self.inst) end, "Should we attack?",
                            ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST)),
					}, UPDATE_RATE),
				}
            ),

            DoAction(self.inst, DoUpgradeModuleAction, nil, true),

            WhileNode(function() return (ShouldMoveAnyways(self.inst) or (not IsLeaderAttacking(self.inst) and IsLeaderMoving(self.inst))) and LeaderInRangeOfTarget(self.inst) end, "is leader not attacking",
                RunToDist(self.inst, RUNTODIST_PARAM, GetRunDist, nil, nil, nil, true)),

            -- 3: Help action
            BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_SOAKIN_ACTION),
            BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_RAISE_ANCHOR_ACTION),

            BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_LOWER_SAIL_ACTION),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.CHOP) end, "chop with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_CHOP_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.MINE) end, "mine with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_MINE_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.HAMMER) end, "hammer with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_HAMMER_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.DIG) end, "dig with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_DIG_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.TILL) end, "till with tool",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_TILL_ACTION)),

            WhileNode(function() return HasToolForAction(self.inst, ACTIONS.ROW) end, "row with oar",
                BrainCommon.NodeAssistLeaderDoAction(self, NODE_ASSIST_ROW_ACTION)),

            -- 4: Repair (Only if no threat closeby)
            WhileNode(function() return not ShouldFlee(self.inst) end, "Safe to repair",
                DoAction(self.inst, DoForgeRepairAction, nil, true)),

            -- 5: Eat/Heal (Only if no threat closeby)
            WhileNode(function() return not ShouldFlee(self.inst) end, "Safe to eat",
                DoAction(self.inst, EatFoodAction, nil, true)),

            -- 6: Follow leader
            SequenceNode{
                ConditionWaitNode(function()
                    return (GetTarget(self.inst) == nil) or not LeaderInRangeOfTarget(self.inst)
                end, "Wait after kiting"),
                Follow(self.inst, GetLeader, FOLLOW_MIN_DIST, FOLLOW_TARGET_DIST, FOLLOW_MAX_DIST, true)
            },

            WhileNode(function() return ShouldEmote(self.inst) end, "Emoting",
                ActionNode(function() DoEmote(self.inst) end)),

            FaceEntity(self.inst, GetFaceLeaderFn, KeepFaceLeaderFn),
            StandStill(self.inst),
        }, UPDATE_RATE))
    }, UPDATE_RATE)

    self.bt = BT(self.inst, root)
end

return Wx78_PossessedBodyBrain