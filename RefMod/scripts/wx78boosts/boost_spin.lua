--旋转电路

local spin_efficiency = GetModConfigData("spin_efficiency")
TUNING.WX78_SPIN_EFFICIENCY_DECAY = 0
TUNING.WX78_SPIN_EFFICIENCY_DECAY2 = 0
TUNING.WX78_SPIN_PICK_EFFICIENCY = GetModConfigData("spin_efficiency2")

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

local speed_activate, speed_deactivate = function()end, function()end

--三重加速
if GetModConfigData("spin_3speed") then
	for _,modu in pairs(module_definitions) do
		if modu.name == "movespeed2" then
			speed_activate = modu.activatefn
			speed_deactivate = modu.deactivatefn
		end
	end
end

--持久旋转
if GetModConfigData("spin_long") then
    TUNING.WX78_SPIN_TIME_TO_DIZZY = 4680
    TUNING.WX78_SPIN_TIME_TO_DIZZY_2 = 4680
end

--旋转电路激活
local function spin_activate(modu, wx, isloading, ...)
	speed_activate(modu, wx, isloading, ...)
	speed_activate(modu, wx, isloading, ...)
	speed_activate(modu, wx, isloading, ...)
end

--旋转电路关闭
local function spin_deactivate(modu, wx, ...)
	speed_deactivate(modu, wx, ...)
	speed_deactivate(modu, wx, ...)
	speed_deactivate(modu, wx, ...)
end

for _,modu in pairs(module_definitions) do
	if modu.name == "spin" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			spin_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			spin_deactivate(modu, wx)
		end
	end
end

--高速旋转
if GetModConfigData("spin_fast") then
	TUNING.WX78_SPIN_RUNSPEED_MULT = TUNING.WX78_SPIN_RUNSPEED_MULT * 2
	
	local mult = GetModConfigData("spin_fast")
	if type(mult) ~= "number" then mult = 1.75 end

	local function FastSpin(sg)
		local state = sg.states.wx_spin_start
		if state then
			local oldfn = state.onenter or function() end
			state.onenter = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(4)
			end
			
			local oldfn = state.onexit or function() end
			state.onexit = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end
			
			--加速时间线
			if state.timeline then
				for _,v in ipairs(state.timeline) do
					if v.time then
						v.time = v.time / 4
					end
				end
			end
		end	
	
		local state = sg.states.wx_spin
		if state then
			local oldfn = state.onenter or function() end
			state.onenter = function(inst, data)
				oldfn(inst, data)
				inst.AnimState:SetDeltaTimeMultiplier(mult)
				if inst.sg.timeout then
					inst.sg.timeout = inst.sg.timeout / mult
				end
				inst.sg.statemem.quickstart = 2 --保持高加速度
			end
	
			local oldfn = state.onupdate or function() end
			state.onupdate = function(inst, ...)
				--修改耐久消耗
				if inst.sg.statemem.efficiency then
					inst.sg.statemem.efficiency.MINE = spin_efficiency
					inst.sg.statemem.efficiency.CHOP = spin_efficiency
					inst.sg.statemem.efficiency.ATTACK = spin_efficiency
				end
				
				oldfn(inst, ...)
				
				--再试一次结束旋转判定(实验性)
				if inst.components.playercontroller then
					if inst.sg:HasStateTag("busy") and
						not inst.components.playercontroller:IsAnyOfControlsPressed(
								CONTROL_ACTION,
								CONTROL_CONTROLLER_ACTION,
								CONTROL_CONTROLLER_ALTACTION,
								CONTROL_ATTACK,
								CONTROL_CONTROLLER_ATTACK,
								CONTROL_PRIMARY,
								CONTROL_SECONDARY
							)
					then
						inst.sg:RemoveStateTag("busy")
						inst.sg:RemoveStateTag("nopredict")
					end

					if not inst.sg:HasStateTag("busy") and inst.sg.statemem.canrelease then
						local frame = inst.AnimState:GetCurrentAnimationFrame()
						inst.AnimState:PlayAnimation(inst.sg.statemem.anim)
						inst.AnimState:SetFrame(frame + 1)
						inst.AnimState:PushAnimation("wx_spin_attack_pst", false)
						inst.sg:GoToState("idle", true)
						return
					end
				end				
			end
	
			local oldfn = state.onexit or function() end
			state.onexit = function(inst)
				oldfn(inst)
				inst.AnimState:SetDeltaTimeMultiplier(1)
			end
		end	
	end

	AddStategraphPostInit("wilson", FastSpin)
	AddStategraphPostInit("wx78_possessedbody", FastSpin) --附身底盘兼容

	--客机
	AddStategraphPostInit("wilson_client", function(sg)
		local state = sg.states.wx_spin_start
		if state then
			local oldfn = state.onenter or function() end
			state.onenter = function(inst)
				oldfn(inst)
				
				--未知用途,希望能修复问题
				inst.sg:SetTimeout(2 / mult)
			end
		end
	end)	
end


--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_spin", function(modu)
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
