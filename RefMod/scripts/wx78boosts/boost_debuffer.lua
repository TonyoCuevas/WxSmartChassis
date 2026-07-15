--破绽机

TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_WALKSPEED = (GetModConfigData("debuffer_spd") or 1) * TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_WALKSPEED
TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED = (GetModConfigData("debuffer_spd") or 1) * TUNING.SKILLS.WX78.SHADOWDRONE_DEBUFFER_RUNSPEED
TUNING.SKILLS.WX78.SHADOWDRONE_DAMAGEMULT_PER_DRONE = GetModConfigData("debuffer_mult") or TUNING.SKILLS.WX78.SHADOWDRONE_DAMAGEMULT_PER_DRONE

local debuffer_vulnerable = GetModConfigData("debuffer_vulnerable")
local debuffer_slow = GetModConfigData("debuffer_slow")


AddPrefabPostInit("wx78_shadowdrone_debuffer", function(inst)
	if not TheWorld.ismastersim then return inst end
	
	--开始扫描
	local oldfn = inst.OnStartScanning or function() end
	inst.OnStartScanning = function(inst, ...)
		oldfn(inst, ...)
		
		local target = inst.target
		if not target then return end
		
		--易伤
		if debuffer_vulnerable and target.components.combat and target.components.combat.externaldamagetakenmultipliers then
			target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1 + TUNING.SKILLS.WX78.SHADOWDRONE_DAMAGEMULT_PER_DRONE)
		end
		
		--减速
		if debuffer_slow > 0 and target.components.locomotor then
			target.components.locomotor:SetExternalSpeedMultiplier(inst, "WMB_debufferspdmult", 1 - debuffer_slow)	
		end
		
		--关闭取消任务
		if inst.WMB_debufftargets_tasks == nil then
			inst.WMB_debufftargets_tasks = {}
		end
		if inst.WMB_debufftargets_tasks[target] then		
			inst.WMB_debufftargets_tasks[target]:Cancel()
			inst.WMB_debufftargets_tasks[target] = nil
		end
	end

	--取消扫描
	local oldfn = inst.OnStopScanning or function() end
	inst.OnStopScanning = function(inst, ...)
		local target = inst.target
		if not target then return oldfn(inst, ...) end
		
		-- --易伤
		-- if debuffer_vulnerable and target.components.combat and target.components.combat.externaldamagetakenmultipliers then
			-- target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1)
		-- end
		
		-- --减速
		-- if debuffer_slow > 0 and target.components.locomotor then
			-- target.components.locomotor:SetExternalSpeedMultiplier(inst, "WMB_debufferspdmult", 1)	
		-- end
		
		--启用取消任务
		if inst.WMB_debufftargets_tasks == nil then
			inst.WMB_debufftargets_tasks = {}
		end
		if not inst.WMB_debufftargets_tasks[target] then		
			inst.WMB_debufftargets_tasks[target] = inst:DoTaskInTime(2, function(inst, target)

				--易伤
				if debuffer_vulnerable and target.components.combat and target.components.combat.externaldamagetakenmultipliers then
					target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1)
				end
				
				--减速
				if debuffer_slow > 0 and target.components.locomotor then
					target.components.locomotor:SetExternalSpeedMultiplier(inst, "WMB_debufferspdmult", 1)	
				end			
			
			end, target)
		end
		
		oldfn(inst, ...)
	end	
	
	--取消扫描
	local oldfn = inst.ClearScanTarget or function() end
	inst.ClearScanTarget = function(inst, ...)
		local target = inst.target
		if not target then return oldfn(inst, ...) end
		
		-- --易伤
		-- if debuffer_vulnerable and target.components.combat and target.components.combat.externaldamagetakenmultipliers then
			-- target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1)
		-- end
		
		-- --减速
		-- if debuffer_slow > 0 and target.components.locomotor then
			-- target.components.locomotor:SetExternalSpeedMultiplier(inst, "WMB_debufferspdmult", 1)	
		-- end
	
		--启用取消任务
		if inst.WMB_debufftargets_tasks == nil then
			inst.WMB_debufftargets_tasks = {}
		end
		if not inst.WMB_debufftargets_tasks[target] then		
			inst.WMB_debufftargets_tasks[target] = inst:DoTaskInTime(2, function(inst, target)

				--易伤
				if debuffer_vulnerable and target.components.combat and target.components.combat.externaldamagetakenmultipliers then
					target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1)
				end
				
				--减速
				if debuffer_slow > 0 and target.components.locomotor then
					target.components.locomotor:SetExternalSpeedMultiplier(inst, "WMB_debufferspdmult", 1)	
				end			
			
			end, target)
		end
	
		oldfn(inst, ...)
	end	
	
end)
