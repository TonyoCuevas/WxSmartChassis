--WX78

local LANG = GetModConfigData("language")

local wx78PotatoCharge = GetModConfigData("wx78_potatocharge")
local wx78NitreCharge = GetModConfigData("wx78_nitrecharge")
local wx78Discharge = GetModConfigData("wx78_discharge")
local wx78LightningCharge = GetModConfigData("wx78_lightningcharge")
local wx78Dry = GetModConfigData("wx78_dry")
local wx78_noknockedout = GetModConfigData("wx78_noknockedout")
local wx78_erase = GetModConfigData("wx78_erase")
local wx78_insight = GetModConfigData("wx78_insight")

local skilltreedefs = require "prefabs/skilltree_defs"
local skilltree = skilltreedefs.SKILLTREE_DEFS.wx78

local allSkills = {}
for k,_ in pairs(skilltree) do
	allSkills[k] = true
end

local ChargingFoods = {}

--土豆充电(机器人技能树更新后,TUNING.WX78_CHARGING_FOODS被弃用了只能用作参考)
if wx78PotatoCharge then
	ChargingFoods["potato"] = 1
	TUNING.WX78_CHARGING_FOODS["potato"] = 1
end

--硝石充电(机器人技能树更新后,TUNING.WX78_CHARGING_FOODS被弃用了只能用作参考)
if wx78NitreCharge then
	ChargingFoods["nitre"] = 3
	TUNING.WX78_CHARGING_FOODS["nitre"] = 3
end


--洞察改动
if wx78_insight then
	
	--洞察点改动
	do
		--交换端初始化时清空技能,防止游戏过程中主客不同步
		AddPrefabPostInit("player_classified", function(inst)
			inst:DoTaskInTime(1, function(inst)
				if TheSkillTree then
					TheSkillTree:RespecSkills("wx78")
				end
			end)
		end)
	
		AddClassPostConstruct("skilltreedata", function(SkillTreeData)
		
			--获取可用点数(自动点满所以是0)
			local oldfn = SkillTreeData.GetAvailableSkillPoints or function() end
			function SkillTreeData:GetAvailableSkillPoints(characterprefab, ...)
				if characterprefab == "wx78" then	
					return 0
				end
				return oldfn(self, characterprefab, ...)
			end
			
			--自动点满技能检测
			local oldfn = SkillTreeData.IsActivated or function() end
			function SkillTreeData:IsActivated(skill, characterprefab, ...)
				if characterprefab == "wx78" and skilltree[skill] ~= nil then
					return true
				end
				return oldfn(self, skill, characterprefab, ...)
			end	
			
			--自动点满技能检测
			local oldfn = SkillTreeData.GetActivatedSkills or function() end
			function SkillTreeData:GetActivatedSkills(characterprefab, ...)
				if characterprefab == "wx78" then
					return allSkills
				end
				return oldfn(self, characterprefab, ...)
			end	
		end)
	
		
	end
	
	--解除亲和限制
	do
		local lunarLock = skilltree["wx78_allegiance_lunar_lock_1"]
		if lunarLock then
			lunarLock.desc = (LANG and "找到并击败天体英雄。") or "Find and defeat the Celestial Champion." 

			lunarLock.lock_open = function(prefabname, activatedskills, readonly)
				if readonly then
					return "question"
				end
				return TheGenericKV:GetKV("celestialchampion_killed") == "1"
			end		
		end
		local shadowLock = skilltree["wx78_shadow_allegiance_lock_1"]
		if shadowLock then
			shadowLock.desc = (LANG and "找到并击败远古织影者。") or "Find and defeat the Ancient Fuelweaver." 
		
			shadowLock.lock_open = function(prefabname, activatedskills, readonly)
				if readonly then
					return "question"
				end
				return TheGenericKV:GetKV("fuelweaver_killed") == "1"
			end			
		end
		
		--月影同辉
		local UIAnim = require "widgets/uianim"
		local SkillTreeWidget = require "widgets/redux/skilltreewidget"
		local oldfn = SkillTreeWidget.SpawnFavorOverlay or function() end
		function SkillTreeWidget:SpawnFavorOverlay(pre, ...)
			if not self.target or self.target ~= "wx78" then
				return oldfn(self, pre, ...)
			end
		
			if not self.fromfrontend and self.midlay ~= nil then
				local activatedskills, characterprefab
				if self.readonly then
					characterprefab = self.targetdata.prefab
					activatedskills = TheSkillTree:GetNamesFromSkillSelection(self.targetdata.skillselection, characterprefab)
				else
					characterprefab = self.target
					-- NOTES(JBK): This is not readonly so the player accessing it has access to its state and it is safe to assume TheSkillTree here.
					activatedskills = TheSkillTree:GetActivatedSkills(characterprefab)
				end
				
				local lunar = skilltreedefs.FN.CountTags(characterprefab, "lunar_favor", activatedskills) > 0
				local shadow = skilltreedefs.FN.CountTags(characterprefab, "shadow_favor", activatedskills) > 0

				if lunar and self.midlay.splash == nil then
					local favor = "skills_lunar"
					self.midlay.splash = self.midlay:AddChild(UIAnim())
					self.midlay.splash:GetAnimState():SetBuild(favor)
					self.midlay.splash:GetAnimState():SetBank(favor)
					self.midlay.splash:GetAnimState():SetMultColour(0.7,0.7,0.7,0.7)
					self.midlay.splash:SetPosition(0,-10)          
					if pre then
						TheFrontEnd:GetSound():PlaySound("wilson_rework/ui/lunar_skill")
						self.midlay.splash:GetAnimState():PlayAnimation("pre",false)
						self.midlay.splash:GetAnimState():PushAnimation("idle",false)
					else
						self.midlay.splash:GetAnimState():PlayAnimation("idle",false)
					end

					self.midlay.splash.inst:ListenForEvent("animover", function()
						local chance = 0.05
						if math.random() < chance then
							self.midlay.splash:GetAnimState():PlayAnimation("twitch",false)
							self.midlay.splash:GetAnimState():PushAnimation("idle",false)
						else
							self.midlay.splash:GetAnimState():PlayAnimation("idle",false)
						end
					end)
				end
				
				if shadow and self.midlay.WMB_splash == nil then
					local favor = "skills_shadow"
					self.midlay.WMB_splash = self.midlay:AddChild(UIAnim())
					self.midlay.WMB_splash:GetAnimState():SetBuild(favor)
					self.midlay.WMB_splash:GetAnimState():SetBank(favor)
					self.midlay.WMB_splash:SetPosition(0,-12)
					if pre then
						TheFrontEnd:GetSound():PlaySound("wilson_rework/ui/shadow_skill")
						self.midlay.WMB_splash:GetAnimState():PlayAnimation("pre",false)
						self.midlay.WMB_splash:GetAnimState():PushAnimation("idle",false)
					else
						self.midlay.WMB_splash:GetAnimState():PlayAnimation("idle",false)
					end

					self.midlay.WMB_splash.inst:ListenForEvent("animover", function()
						local chance = 0.3
						if math.random() < chance then
							self.midlay.WMB_splash:GetAnimState():PlayAnimation("twitch",false)
							self.midlay.WMB_splash:GetAnimState():PushAnimation("idle",false)
						else
							self.midlay.WMB_splash:GetAnimState():PlayAnimation("idle",false)
						end
					end)					
				end
				
			end			
		end
	end

	--解除备份底盘亲和限制
	do
		local WX78Common = require("prefabs/wx78_common")
	
		AddPrefabPostInit("wx78_backupbody", function(inst)
			
			--扩展网络变量
			if inst.components.socketholder then
				local self = inst.components.socketholder
				local i = 2
				
				self.socketed[i] = net_bool(self.inst.GUID, "socketholder.socketed" .. i, "onsocketeddirty" .. i)
					
				local socketquality_net_enum = GetIdealUnsignedNetVarForCount(SOCKETQUALITY_MAXVALUE)
				self.socketquality[i] = socketquality_net_enum(self.inst.GUID, "socketholder.socketquality" .. i)

				self.socketnames[i] = net_hash(self.inst.GUID, "socketholder.socketname" .. i)
			end
			
			if not TheWorld.ismastersim then return inst end
			
			inst.CheckSocketStatesFrom = function(inst, owner)
				if owner and owner.prefab == "wx78" then
					WX78Common.ActivateSocketsIn(inst, 1, SOCKETNAMES.SHADOW)
					WX78Common.ActivateSocketsIn(inst, 2, SOCKETNAMES.GESTALTTRAPPER)
				else
					WX78Common.DeactivateSocketsIn(inst, 1)
					WX78Common.DeactivateSocketsIn(inst, 2)
				end
			end
		end)
	end
	
	--防止触发bug,不能为暗影线的底盘安装传输器
	do	
		--传输器
		AddPrefabPostInit("wx78_gestalttrapper", function(inst)
			if not TheWorld.ismastersim then return inst end
			
			if inst.components.useabletargeteditem then
				local oldfn = inst.components.useabletargeteditem.onusefn or function() end
				
				inst.components.useabletargeteditem.onusefn = function(inst, target, doer, ...)
					if target and target.prefab == "wx78_backupbody"
						and target.components.socketholder
					then
						local quality = target.components.socketholder:GetHighestQualitySocketed(SOCKETNAMES.SHADOW)
						if doer and quality ~= SOCKETQUALITY.NONE then
							return false
						end
						
						--贴心地关闭容器
						if target.components.container and target.components.container:IsOpen() then
							target.components.container:Close()
						end
					end
					return oldfn(inst, target, doer, ...)
				end
			end
		end)
		
		--黑心
		local function ConflictWithLunar(inst)
			if not TheWorld.ismastersim then return inst end
			
			if inst.components.useabletargeteditem then
				local oldfn = inst.components.useabletargeteditem.onusefn or function() end
				
				inst.components.useabletargeteditem.onusefn = function(inst, target, doer, ...)
					if target and target.prefab == "wx78_backupbody"
						and target.components.socketholder
					then
						local quality = target.components.socketholder:GetHighestQualitySocketed(SOCKETNAMES.GESTALTTRAPPER)
						if doer and quality ~= SOCKETQUALITY.NONE then
							return false
						end
					end
					return oldfn(inst, target, doer, ...)
				end
			end		
		end
		AddPrefabPostInit("shadowheart", ConflictWithLunar)
		AddPrefabPostInit("shadowheart_infused", ConflictWithLunar)
		
	end
end

--WX78初始化
AddPrefabPostInit("wx78", function(wx)

	if not TheWorld.ismastersim then return wx end
	
	--雷击充电优化
	if wx78LightningCharge and wx.components.playerlightningtarget then
		wx.components.playerlightningtarget:SetOnStrikeFn(function(inst)
			if inst.components.health and not inst.components.health:IsDead() then
				local charge = 6
				local empty = inst.components.upgrademoduleowner.max_charge - inst.components.upgrademoduleowner.charge_level

				if inst.components.inventory:IsInsulated() then
					charge = 2
				else
					inst.components.sanity:DoDelta(-TUNING.SANITY_LARGE)
					inst.sg:GoToState("electrocute")
				end

				--溢出的电量用于回血
				inst.components.upgrademoduleowner:AddCharge(charge)
				if charge >= empty then
					charge = charge - empty
					if charge > 0 then
						inst.components.health:DoDelta(15*charge, false, "lightning")
					end
				end
			end
		end)
	end
	
	--更快干燥
	if wx78Dry and wx.components.moisture then
		wx.components.moisture.maxDryingRate = wx.components.moisture.maxDryingRate + 0.15
		wx.components.moisture.baseDryingRate = wx.components.moisture.baseDryingRate + 0.15
	end
	
	--洞察改动
	if wx78_insight and wx.components.skilltreeupdater then
		local skilltreeupdater = wx.components.skilltreeupdater
		for skill,_ in pairs(allSkills) do
			skilltreeupdater:ActivateSkill_Server(skill)
		end
	end	
end)
AddPrefabPostInit("wx", function(wx) --WX自动化兼容
	if not TheWorld.ismastersim then return wx end
	
	--雷击充电优化
	if wx78LightningCharge and wx.components.playerlightningtarget then
		wx.components.playerlightningtarget:SetOnStrikeFn(function(inst)
			if inst.components.health and not inst.components.health:IsDead() then
				local charge = 6
				local empty = inst.components.upgrademoduleowner.max_charge - inst.components.upgrademoduleowner.charge_level

				if inst.components.inventory:IsInsulated() then
					charge = 2
				end

				--溢出的电量用于回血
				inst.components.upgrademoduleowner:AddCharge(charge)
				if charge > empty then
					charge = charge - empty
				end
				if charge > 0 then
					inst.components.health:DoDelta(15*charge, false, "lightning")
				end
			end
		end)
	end
	
	--更快干燥
	if wx78Dry and wx.components.moisture then
		wx.components.moisture.maxDryingRate = wx.components.moisture.maxDryingRate + 0.05
		wx.components.moisture.baseDryingRate = wx.components.moisture.baseDryingRate + 0.05
	end	
end)

--催眠抗性
if wx78_noknockedout then

local function NoKnockedout(sg)

	--不会进入催眠倒地状态
	if sg.events and sg.events.knockedout then
		local oldfn = sg.events.knockedout.fn
		sg.events.knockedout.fn = function(inst, ...)
			if inst.prefab == "wx78" then
				return
			elseif oldfn then
				return oldfn(inst, ...)
			end
		end
	end
	
	--跳过哈欠
	if sg.states and sg.states["yawn"] then
		local oldfn = sg.states["yawn"].onenter
		sg.states["yawn"].onenter = function(inst, data)
			if inst.prefab == "wx78" then
				if data ~= nil and
					data.grogginess ~= nil and
					data.grogginess > 0 and
					inst.components.grogginess ~= nil
				then
					inst.sg.statemem.groggy = true
					inst.sg.statemem.knockoutduration = data.knockoutduration
					inst.components.grogginess:AddGrogginess(1, 1)
					inst.sg:RemoveStateTag("yawn")
					inst.sg:GoToState("idle")
				end		
			elseif oldfn then
				return oldfn(inst, data)
			end
		end
	end
end

AddStategraphPostInit("wilson", NoKnockedout)
AddStategraphPostInit("wilson_client", NoKnockedout)

end

--生物数据工艺
if GetModConfigData("wx78_scandatacrafts") then
	--莎草纸转换
	AddRecipe2("wmb_wx78_papyrus_to_scandata",
		{
			Ingredient("papyrus", 1),
			Ingredient(CHARACTER_INGREDIENT.SANITY, 15),
		},
		TECH.NONE, 
		{builder_tag="upgrademoduleowner", numtogive=5, product="scandata", description="wmb_wx78_papyrus_to_scandata", no_deconstruction=true},
		{"MODS", "CHARACTER"}
	)
	AddRecipe2("wmb_wx78_scandata_to_papyrus",
		{
			Ingredient("scandata", 5),
			Ingredient(CHARACTER_INGREDIENT.SANITY, 10),
		},
		TECH.NONE, 
		{builder_tag="upgrademoduleowner", product="papyrus", description="wmb_wx78_scandata_to_papyrus", no_deconstruction=true},
		{"MODS", "CHARACTER"}
	)
	if LANG then
		STRINGS.RECIPE_DESC.WMB_WX78_PAPYRUS_TO_SCANDATA = "生物数据当然可以自己编，就像你大学论文的数据。" 
		STRINGS.RECIPE_DESC.WMB_WX78_SCANDATA_TO_PAPYRUS = "对于看不懂的人来说，是这样的。"
	else
		STRINGS.RECIPE_DESC.WMB_WX78_PAPYRUS_TO_SCANDATA = "Make up data, like what you did in the college." 
		STRINGS.RECIPE_DESC.WMB_WX78_SCANDATA_TO_PAPYRUS = "Just do it, can not read anymore." 	
	end
end

--废料工艺
if GetModConfigData("wx78_scrapcrafts") then
	--齿轮废料互换
	AddRecipe2("wmb_gears_to_wagpunk_bits",
		{
			Ingredient("gears", 1),
			Ingredient("trinket_6", 1),
		},
		TECH.NONE, 
		{builder_tag="upgrademoduleowner", numtogive=4, product="wagpunk_bits", description="wmb_gears_to_wagpunk_bits", no_deconstruction=true},
		{"MODS", "CHARACTER"}
	)
	AddRecipe2("wmb_wagpunk_bits_to_gears",
		{
			Ingredient("wagpunk_bits", 4),
			Ingredient("wx78_moduleremover", 0),
		},
		TECH.NONE, 
		{builder_tag="upgrademoduleowner", product="gears", description="wmb_wagpunk_bits_to_gears", no_deconstruction=true},
		{"MODS", "CHARACTER"}
	)
	
	--幻灵捕获机
	AddRecipe2("wmb_gestalt_cage",
		{
			Ingredient("thulecite", 2),
			Ingredient("wagpunk_bits", 4),
		},
		TECH.NONE, 
		{builder_tag="upgrademoduleowner", product="gestalt_cage", description="wmb_gestalt_cage", no_deconstruction=true},
		{"MODS", "CHARACTER"}
	)	
	
	if LANG then
		STRINGS.RECIPE_DESC.WMB_GEARS_TO_WAGPUNK_BITS = "你怎么知道？" 
		STRINGS.RECIPE_DESC.WMB_WAGPUNK_BITS_TO_GEARS = "做一个小小的“变性”手术。"
		STRINGS.RECIPE_DESC.WMB_GESTALT_CAGE = "我早就知道。"
	else
		STRINGS.RECIPE_DESC.WMB_GEARS_TO_WAGPUNK_BITS = "How did you know?" 
		STRINGS.RECIPE_DESC.WMB_WAGPUNK_BITS_TO_GEARS = 'Just a mini "TRANS" operation.' 
		STRINGS.RECIPE_DESC.WMB_GESTALT_CAGE = 'BECAUSE I KNEW.' 
	end
end

--右键充电动作注册
local WMB_CHARGE = Action({priority = 3, mount_valid = true})
WMB_CHARGE.id = "WMB_CHARGE"
WMB_CHARGE.str = (LANG and "充电") or "Charge"
WMB_CHARGE.fn = function(act)
	local target = act.target or act.doer
	if act.invobject == nil or target == nil or target.components.upgrademoduleowner == nil then return false end
	local charge = ChargingFoods[act.invobject.prefab]

	if charge ~= nil then
		if target.components.eater and act.invobject.components.edible and target.components.eater:CanEat(act.invobject) then
			if act.invobject.components.edible.healthvalue < 0 then
				act.invobject.components.edible.healthvalue = 0
			end
			if act.invobject.components.edible.hungervalue < 0 then
				act.invobject.components.edible.hungervalue = 0
			end
			if act.invobject.components.edible.sanityvalue < 0 then
				act.invobject.components.edible.sanityvalue = 0
			end
			target.components.eater:Eat(act.invobject)
			
			--机器人技能树更新后,充电属性记录在edible里,但懒得弄了直接加充能吧
			target.components.upgrademoduleowner:AddCharge(charge)
			return true
		elseif not target.components.upgrademoduleowner:ChargeIsMaxed() then
			if act.invobject.components.stackable then
				act.invobject.components.stackable:Get():Remove()
			else
				act.invobject:Remove()
			end
			target.components.upgrademoduleowner:AddCharge(charge)
			return true
		end
	end

	return false
end

AddAction(WMB_CHARGE)

AddComponentAction("INVENTORY", "edible", function(inst, doer, actions, right)
	if ChargingFoods[inst.prefab] ~= nil and doer:HasTag("upgrademoduleowner") then
        table.insert(actions, ACTIONS.WMB_CHARGE)
    end
end)
AddComponentAction("USEITEM", "edible", function(inst, doer, target, actions, right)
	if right and ChargingFoods[inst.prefab] ~= nil and target:HasTag("upgrademoduleowner") then
        table.insert(actions, ACTIONS.WMB_CHARGE)
    end
end)

local function wmb_charge_action_handler(inst, act)
	if act.target == nil then 
		return "quickeat"
	end
	return "give"
end
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_CHARGE, wmb_charge_action_handler))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_CHARGE, wmb_charge_action_handler))


--右键输电动作注册
local WMB_DISCHARGE = Action({priority = 3, mount_valid = true})
WMB_DISCHARGE.id = "WMB_DISCHARGE"
WMB_DISCHARGE.str = (LANG and "输电") or "Charge"
WMB_DISCHARGE.fn = function(act)
	local target = act.target or act.invobject
	if target == nil or act.doer == nil then return false end

	if act.doer.components.upgrademoduleowner and not act.doer.components.upgrademoduleowner:IsChargeEmpty() then
		if target.components.fueled then		
			local percent = target.components.fueled:GetPercent()
			if percent < 1 then
				act.doer.components.upgrademoduleowner:AddCharge(-1)
				target.components.fueled:SetPercent(math.min(1, percent + 0.2))
				return true
			end
		elseif target.components.finiteuses then	
			local percent = target.components.finiteuses:GetPercent()
			if percent < 1 then
				act.doer.components.upgrademoduleowner:AddCharge(-1)
				target.components.finiteuses:SetPercent(math.min(1, percent + 0.2))
				return true
			end		
		end
	end

	return false
end

AddAction(WMB_DISCHARGE)

AddComponentAction("INVENTORY", "fueled", function(inst, doer, actions, right)
	if right and wx78Discharge and inst.prefab == "nightstick" and doer:HasTag("upgrademoduleowner") then
		if not inst.replica.equippable or not inst.replica.equippable:IsEquipped() then		
			table.insert(actions, ACTIONS.WMB_DISCHARGE)
		end
    end
end)
AddComponentAction("SCENE", "fueled", function(inst, doer, actions, right)
	if right and wx78Discharge and inst.prefab == "nightstick" and doer:HasTag("upgrademoduleowner") then
        table.insert(actions, ACTIONS.WMB_DISCHARGE)
    end
end)
AddComponentAction("INVENTORY", "finiteuses", function(inst, doer, actions, right)
	if right and wx78Discharge and inst.prefab == "wx78_drone_zap_remote" and doer:HasTag("upgrademoduleowner") then
		if not inst.replica.equippable or not inst.replica.equippable:IsEquipped() then	
			table.insert(actions, ACTIONS.WMB_DISCHARGE)
		end
    end
end)
AddComponentAction("SCENE", "finiteuses", function(inst, doer, actions, right)
	if right and wx78Discharge and inst.prefab == "wx78_drone_zap_remote" and doer:HasTag("upgrademoduleowner") then
        table.insert(actions, ACTIONS.WMB_DISCHARGE)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_DISCHARGE, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_DISCHARGE, "give"))




--右键擦纸动作注册
local WMB_ERASE = Action({priority = 1.1, mount_valid = true, invalid_hold_action = true})
WMB_ERASE.id = "WMB_ERASE"
WMB_ERASE.str = (LANG and "擦除") or "Erase"
WMB_ERASE.fn = function(act)
	local target = act.target; if target == nil then return false end
	local doer = act.doer; if doer == nil then return false end

	if target.components.erasablepaper then	
		return target.components.erasablepaper:DoErase(doer, doer) ~= nil
	end

	return false
end

AddAction(WMB_ERASE)

AddComponentAction("SCENE", "erasablepaper", function(inst, doer, actions, right)
	if wx78_erase and right and doer.prefab == "wx78" then
        table.insert(actions, ACTIONS.WMB_ERASE)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.WMB_ERASE, "domediumaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.WMB_ERASE, "domediumaction"))

--行为排队论兼容
AddComponentPostInit("actionqueuer", function(ActionQueuer)
	if ActionQueuer.AddAction ~= nil then
		ActionQueuer.AddAction("rightclick", "WMB_ERASE", true)
	end
end)

