--声波电路

TUNING.WX78_SCREECH_RANGE = GetModConfigData("screech_range") or TUNING.WX78_SCREECH_RANGE
TUNING.WX78_SCREECH_COOLDOWN = GetModConfigData("screech_cd") or TUNING.WX78_SCREECH_COOLDOWN

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_screech", function(modu)
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

--恐惧影怪
if GetModConfigData("screech_shadow") then
	
	local function GetWX78ScreechRange(inst)
		local num_modules = inst._screech_modules or 1
		return num_modules * TUNING.WX78_SCREECH_RANGE
	end	
	
	local function ClearShadowPanic(inst)
		inst._shadow_creature_panic_task = nil
	end	
	
	--恐惧效果(来自官方声波电路动作和月树花茶)
	local WX_SCARE_MUST_TAGS = { "_combat", "_health", "shadowsubmissive" }
	local WX_SCARE_CANT_TAGS = { "INLIMBO", "epic" }	
	local function DoWX78Screech(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local range = GetWX78ScreechRange(inst)
		local ents = TheSim:FindEntities(x, y, z, range, WX_SCARE_MUST_TAGS, WX_SCARE_CANT_TAGS)
		for i, v in ipairs(ents) do
			if v ~= inst and v:IsValid()
				and not inst.components.combat:IsAlly(v)
			then
				if v._detach_from_boat_fn ~= nil then --恐怖利爪
					v._detach_from_boat_fn(v)
				end
				if v._shadow_creature_panic_task ~= nil then
					v._shadow_creature_panic_task:Cancel()
				end
				v._shadow_creature_panic_task = v:DoTaskInTime(TUNING.WX78_SCREECH_PANIC_TIME, ClearShadowPanic)
			end
		end
	end	
	

	local function ScreechShadow(sg)
		local state = sg.states.wx_screech_loop
		if state then
			local oldfn = state.onupdate or function() end
			state.onupdate = function(inst, dt)
				if inst.sg.statemem.scarecd - dt <= 0 then
					DoWX78Screech(inst)
				end				
				oldfn(inst, dt)
			end
		end
	end
	AddStategraphPostInit("wilson", ScreechShadow)
	AddStategraphPostInit("wx78_possessedbody", ScreechShadow) --附身底盘兼容

end