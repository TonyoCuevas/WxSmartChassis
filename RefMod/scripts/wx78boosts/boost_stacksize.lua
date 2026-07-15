--空间扩展电路

local wx78_moduledefs = require("wx78_moduledefs")
local module_definitions = wx78_moduledefs.module_definitions

for _,modu in pairs(module_definitions) do
	if modu.name == "stacksize" then
		modu.type = CIRCUIT_BARS.GAMMA
		
		--修改贴图
		modu.overridebuild = "wmb_wx_chips"
		modu.overrideuibuild = "wmb_status_wx_chest"
	end
end

--修改物品栏贴图
RegisterInventoryItemAtlas("images/inventoryimages/wmb/wx78module_stacksize.xml", "wx78module_stacksize.tex")
