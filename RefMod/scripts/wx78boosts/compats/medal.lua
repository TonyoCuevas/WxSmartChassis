--勋章内容兼容


AddPrefabPostInit("wx78_possessedbody", function(wx)
	if not TheWorld.ismastersim then return wx end
	
	--让机器人装备勋章也有效果
	wx:ListenForEvent("equip", function(wx, data)
		local item = data.item
		if item ~= nil and item:HasTag("medal") then
			if item.onequipfn then
				item:onequipfn(wx)
			end

			--融合勋章
			if item:HasTag("multivariate_certificate") and item.components.container then
				if item.prefab == "origin_certificate" then
					wx:AddTag("has_origin_medal")
				end
				for _,v in pairs(item.components.container.slots) do
					if v:HasTag("medal") and v.onequipfn then
						v:onequipfn(wx)
					end
				end
			end
		end
	end)
	wx:ListenForEvent("unequip", function(wx, data)
		local item = data.item
		if item ~= nil and item:HasTag("medal") then
			if item.onunequipfn then
				item:onunequipfn(wx)
			end	
			
			--融合勋章
			if item:HasTag("multivariate_certificate") and item.components.container then
				for _,v in pairs(item.components.container.slots) do
					if v:HasTag("medal") and v.onunequipfn then
						v:onunequipfn(wx)
					end
				end
				if item.prefab == "origin_certificate" then
					wx:RemoveTag("has_origin_medal")
				end
			end				
		end
	end)
	
	--勋章风暴修复(附身底盘不会受到风暴影响,不需要这个)
	-- wx:AddComponent("medal_spacetimestormwatcher")
	-- if wx.components.medal_spacetimestormwatcher then		
		-- function wx.components.medal_spacetimestormwatcher:UpdateSpacetimestormWalkSpeed()
			-- local level = self:GetSpacetimeStormLevel()
			-- if level and self.spacetimestormspeedmult < 1 then
				-- if level < TUNING.SANDSTORM_FULL_LEVEL or
					-- self.inst.components.inventory:EquipHasTag("goggles") or
					-- self.inst.components.rider:IsRiding() then
					-- self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "spacetimestorm")
				-- else
					-- self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst, "spacetimestorm", self.spacetimestormspeedmult)
				-- end
			-- end
		-- end		
	-- end
end)

