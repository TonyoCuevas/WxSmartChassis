--处理器电路

local sanitySailMult = GetModConfigData("sanity_sailmult")
local sanity1WorkMult1 = GetModConfigData("sanity_workmult1")
local sanity1WorkMult2 = GetModConfigData("sanity_workmult2")
local sanityWorkMult1 = (sanity1WorkMult1 ~= 1 and sanity1WorkMult1 * 2) or 1
local sanityWorkMult2 = (sanity1WorkMult2 ~= 1 and sanity1WorkMult2) or 1

--处理器电路快速动作
local sanityAction = {}
if GetModConfigData("sanity_quickpick") then
	table.insert(sanityAction, ACTIONS.PICK)
	table.insert(sanityAction, ACTIONS.PICKUP)
	table.insert(sanityAction, ACTIONS.TAKEITEM)
	table.insert(sanityAction, ACTIONS.HARVEST)
	table.insert(sanityAction, ACTIONS.SHAVE)
end
if GetModConfigData("sanity_quickfram") then
	table.insert(sanityAction, ACTIONS.TILL)
	table.insert(sanityAction, ACTIONS.PLANTSOIL)
	table.insert(sanityAction, ACTIONS.INTERACT_WITH)
	table.insert(sanityAction, ACTIONS.DIG)
end
if GetModConfigData("sanity_quickcraft") then
	table.insert(sanityAction, ACTIONS.BUILD)
	table.insert(sanityAction, ACTIONS.REPAIR)
	table.insert(sanityAction, ACTIONS.ERASE_PAPER)
end

--处理器电路激活
local function sanity1_activate(modu, wx)
	wx.WMB_sanity1num = (wx.WMB_sanity1num or 0) + 1

	--航海效率加成
	if sanitySailMult then
		if wx.components.expertsailor == nil then
			wx:AddComponent("expertsailor")
		end
		wx.components.expertsailor:SetRowForceMultiplier(TUNING.MIGHTY_ROWER_MULT)
		wx.components.expertsailor:SetRowExtraMaxVelocity(TUNING.MIGHTY_ROWER_EXTRA_MAX_VELOCITY)
		wx.components.expertsailor:SetAnchorRaisingSpeed(TUNING.MIGHTY_ANCHOR_SPEED)
		wx.components.expertsailor:SetLowerSailStrength(TUNING.MIGHTY_SAIL_BOOST_STRENGTH)		
	end

	--工作效率加成
	if wx.components.workmultiplier == nil then
		wx:AddComponent("workmultiplier")
	end
	local source = "WMB_sanity1workmult"
	wx.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, sanity1WorkMult1, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.REMOVELUNARBUILDUP, sanity1WorkMult1, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.MINE, sanity1WorkMult2, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.DIG, sanity1WorkMult1, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, sanity1WorkMult2, source)
end
local function sanity_activate(modu, wx)
	wx.WMB_sanitynum = (wx.WMB_sanitynum or 0) + 1

	--航海效率加成
	if sanitySailMult then
		if wx.components.expertsailor == nil then
			wx:AddComponent("expertsailor")
		end
		wx.components.expertsailor:SetRowForceMultiplier(TUNING.MIGHTY_ROWER_MULT)
		wx.components.expertsailor:SetRowExtraMaxVelocity(TUNING.MIGHTY_ROWER_EXTRA_MAX_VELOCITY)
		wx.components.expertsailor:SetAnchorRaisingSpeed(TUNING.MIGHTY_ANCHOR_SPEED)
		wx.components.expertsailor:SetLowerSailStrength(TUNING.MIGHTY_SAIL_BOOST_STRENGTH)		
	end

	--工作效率加成
	if wx.components.workmultiplier == nil then
		wx:AddComponent("workmultiplier")
	end
	local source = "WMB_sanityworkmult"
	wx.components.workmultiplier:AddMultiplier(ACTIONS.CHOP, sanityWorkMult1, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.REMOVELUNARBUILDUP, sanityWorkMult1, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.MINE, sanityWorkMult2, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.DIG, sanityWorkMult1, source)
	wx.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER, sanityWorkMult2, source)
end

--处理器电路关闭
local function sanity1_deactivate(modu, wx)
	wx.WMB_sanity1num = math.max(0, (wx.WMB_sanity1num or 0) - 1)
	wx.WMB_sanitynum = wx.WMB_sanitynum or 0

	--取消工作效率加成
	if wx.components.workmultiplier and wx.WMB_sanity1num <= 0 then
		local source = "WMB_sanity1workmult"
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.REMOVELUNARBUILDUP, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.DIG, source)		
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, source)		
	end

	--取消科航海效率加成
	if wx.WMB_sanity1num <= 0 and wx.WMB_sanitynum <= 0 then
		wx:RemoveComponent("expertsailor")
	end
end
local function sanity_deactivate(modu, wx)
	wx.WMB_sanitynum = math.max(0, (wx.WMB_sanitynum or 0) - 1)
	wx.WMB_sanity1num = wx.WMB_sanity1num or 0

	--取消工作效率加成
	if wx.components.workmultiplier and wx.WMB_sanitynum <= 0 then
		local source = "WMB_sanityworkmult"
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.CHOP, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.REMOVELUNARBUILDUP, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.MINE, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.DIG, source)
		wx.components.workmultiplier:RemoveMultiplier(ACTIONS.HAMMER, source)
	end

	if wx.WMB_sanitynum <= 0 and wx.WMB_sanity1num <= 0 then
		wx:RemoveComponent("expertsailor")
	end
end


--处理器电路初始化
local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions
for _,modu in pairs(module_definitions) do
	if modu.name == "maxsanity1" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading)
			oldonactivatedfn(modu, wx, isloading)
			sanity1_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx)
			oldondeactivatedfn(modu, wx)
			sanity1_deactivate(modu, wx)
		end
	end
	if modu.name == "maxsanity" then
		local oldonactivatedfn, oldondeactivatedfn = modu.activatefn, modu.deactivatefn
		modu.activatefn = function(modu, wx, isloading, ...)
			oldonactivatedfn(modu, wx, isloading, ...)
			sanity_activate(modu, wx)
		end
		modu.deactivatefn = function(modu, wx, ...)
			oldondeactivatedfn(modu, wx, ...)
			sanity_deactivate(modu, wx)
		end
	end
end


-- AddPrefabPostInit("wx78module_maxsanity1", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- sanity1_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- sanity1_deactivate(modu, wx)
		-- end
    -- end
-- end)
-- AddPrefabPostInit("wx78module_maxsanity", function(modu)
    -- if TheWorld.ismastersim and modu.components.upgrademodule then
		-- local oldonactivatedfn = modu.components.upgrademodule.onactivatedfn or function() end
		-- local oldondeactivatedfn = modu.components.upgrademodule.ondeactivatedfn or function() end

		-- modu.components.upgrademodule.onactivatedfn = function(modu, wx, isloading)
			-- oldonactivatedfn(modu, wx, isloading)
			-- sanity_activate(modu, wx)
		-- end

		-- modu.components.upgrademodule.ondeactivatedfn = function(modu, wx)
			-- oldondeactivatedfn(modu, wx)
			-- sanity_deactivate(modu, wx)
		-- end
    -- end
-- end)


--快速动作
if #sanityAction > 0 then

local function sanity_actionhandler(inst, act)
	if act.target then --防止大垃圾堆翻不了
		if act.target.prefab == "junk_pile_big" then
			return
		end
	end
	if (inst.WMB_sanitynum and inst.WMB_sanitynum > 0) then
		return "WMB_doshortaction"
	elseif (inst.WMB_sanity1num and inst.WMB_sanity1num > 0) then
		return "domediumaction"
	end
end
local function sanity_quickfn(sg)
	sg.states["WMB_doshortaction"] = State{
		name = "WMB_doshortaction",
		onenter = function(inst) inst.sg:GoToState("dolongaction", 0.2) end
    }

    if sg.actionhandlers ~= nil then
		for _,action in pairs(sanityAction) do
			local handler = sg.actionhandlers[action] or {}
			local oldfn = handler.deststate or function() end
			handler.deststate = function(inst, act)
				local oldresult = oldfn(inst, act)
				if oldresult == "dolongaction" 
					or oldresult == "domediumaction" 
					or oldresult == "till_start" 
					or oldresult == "dig_start" 
				then
					return sanity_actionhandler(inst, act) or oldresult
				end
				return oldresult
			end
		end
	end
end
AddStategraphPostInit("wilson", sanity_quickfn)
AddStategraphPostInit("wilson_client", sanity_quickfn)
AddStategraphPostInit("wx78_possessedbody", sanity_quickfn) --附身底盘兼容
AddStategraphPostInit("wx", sanity_quickfn) --WX自动化兼容

end

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_maxsanity1", function(modu)
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
AddPrefabPostInit("wx78module_maxsanity", function(modu)
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
