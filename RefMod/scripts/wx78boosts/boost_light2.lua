--超级照明电路
--(胃增益电路饥饿充电功能在对应的文件中)

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

local light_activate, light_deactivate = function()end, function()end
local night_activate, night_deactivate = function()end, function()end
local light2_2in1 = GetModConfigData("light2_2in1")

--二合一
for _,modu in pairs(module_definitions) do
	if modu.name == "light" then
		light_activate = modu.activatefn
		light_deactivate = modu.deactivatefn
	end
end

if light2_2in1 then
	for _,modu in pairs(module_definitions) do
		if modu.name == "nightvision" then
			night_activate = modu.activatefn
			night_deactivate = modu.deactivatefn
		end	
	end
end

--超级照明电路激活
local function light2_activate(modu, wx, isloading, ...)
	light_activate(modu, wx, isloading, ...)
	
	if light2_2in1 then	
		night_activate(modu, wx, isloading, ...)
	end
end

--超级照明电路关闭
local function light2_deactivate(modu, wx, ...)
	light_deactivate(modu, wx, ...)
	
	if light2_2in1 then	
		night_deactivate(modu, wx, ...)
	end
end

for _,modu in pairs(module_definitions) do
	if modu.name == "light2" then
		modu.activatefn = light2_activate
		modu.deactivatefn = light2_deactivate
		
		modu.client_activatefn = night_activate
		modu.client_deactivatefn = night_deactivate
	end
end

--屏蔽技能树监听(硬核)
AddPrefabPostInit("wx78module_light2", function(modu)
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