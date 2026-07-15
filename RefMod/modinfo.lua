name = "WX78机械飞升"
author = "wiefean"
version = "2.034"

description = "版本: "..version.."\n"..
"为WX78提供强化效果。当然，只要你想，也可以是削弱。\n"..
"进入配置以查看更详细的描述。\n\n"..
"󰀏注意，部分配置将覆盖技能树。\n"..
"󰀏Attention, some options kill skilltree.\n"


server_filter_tags = {"wx", "wx78"}

forumthread = ""
priority = -7800
api_version = 10

icon_atlas = "modicon.xml"
icon = "modicon.tex"

dst_compatible = true
dont_starve_compatible = false
all_clients_require_mod = true

--标题
local function Title(title)
	return	{
		name = "",
		label = title,
		options = {{description = "", data = 0}},
		default = 0,
	}
end

--物品制作难度配置
local function RecipeOptions(Name, Label, defaultRecipe, originalRecipe)
	return	{
		name = "recipe_"..Name,
		hover = "配方 / Recipes",
		label = Label,
		options = {
			{description = "修改 / Modified", hover = defaultRecipe, data = true},
			{description = "原版 / Vanilla", hover = originalRecipe, data = false},
		},
		default = true,
	}
end

--电气化电路伤害范围配置
local function TaserRangeOptions(Name, Default)
	return {
        name = Name,
        label = "半径 / Radius",
        hover = "单位：墙体 / Unit: Wall",
        options = {
			{description = "单体 / Single", data = 0},
			{description = "1", data = 1},
			{description = "1.5", data = 1.5},
			{description = "2", data = 2},
			{description = "2.5", data = 2.5},
			{description = "3", data = 3},
			{description = "3.5", data = 3.5},
			{description = "4", data = 4},
			{description = "4.5", data = 4.5},
			{description = "5", data = 5},
			{description = "5.5", data = 5.5},
			{description = "6.5", data = 6.5},
			{description = "7", data = 7},
			{description = "7.5", data = 7.5},
			{description = "7.8 !", data = 7.8},
        },
        default = Default
    }
end

--合唱盒电路音量配置
local function MusicVolumeOptions()
	return 	{
        name = "music_volume",
        label = "音量 / Volume",
        hover = "",
        options = {
			{description = "0", data = 0},
			{description = "0.2", data = 0.2},
			{description = "0.4", data = 0.4},
			{description = "0.6", data = 0.6},
			{description = "0.8", data = 0.8},
			{description = "1", data = 1},
			{description = "1.2", data = 1.2},
			{description = "1.4", data = 1.4},
			{description = "1.6", data = 1.6},
			{description = "1.8", data = 1.8},
			{description = "2", data = 2},
		},
        default = 1
    }
end

--光电电路揭示实体位置配置
local function NightOptions(Name, Label)
	return 	{
        name = "night_"..Name,
        label = Label,
        hover = "实时显示位置 / Show position in real time",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    }
end

--总开关配置
local function MainSwitch(Name)
	return 	{
        name = Name..'_main',
        label = "总开关 / Main Switch",
        hover = "关闭后改动完全失效 / Make the modifier invalid completely",
        options = {
            {description = "启用 / On", data = true},
            {description = "禁用 / Off", data = false},
        },
        default = true
    }
end

--是否型配置
local function Bool(Name, Label, Hover)
	return {
        name = Name,
        label = Label,
		hover = Hover,
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,	
	}
end

--是否型配置(默认为"否")
local function Bool2(Name, Label, Hover)
	return {
        name = Name,
        label = Label,
		hover = Hover,
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = false,	
	}
end

configuration_options = {
	{
		name = "language",
		label = "语言 / Language",
		hover = "",
		options = {
			{description = "中文", data = true},
			{description = "English", data = false},
		},
		default = true,
	},	
	
	
	Title("模组兼容 / Compats"),
	{
		name = "compat_medal",
		label = "能力勋章 / Functional Medals",
		hover = "让附身底盘可以使用勋章 \n Make medals available to Possessed Chassis",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = false,
	},	
	
	
	Title("WX78"),
	MainSwitch("wx78"),
	{
		name = "wx78_insight",
		label = "全技能 / Get All Skills",
		hover = "为什么要把本来就该有的改动做成技能呢\nWhy they make merited changes as skills",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "wx78_potatocharge",
		label = "土豆充电 / Potato Charge",
		hover = "用生土豆充电 / Use raw potatoes to charge",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "wx78_lightningcharge",
		label = "雷击优化 / Better Lightning",
		hover = "被雷击将恢复6格电量，扣除33精神值并进入一段时间的僵直，多余的电量将转化为15生命值\n绝缘状态下也受影响，但无精神值扣除和僵直，恢复的电量降低为2",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "wx78_nitrecharge",
		label = "硝石充电 / Nitre Charge",
		hover = "用硝石充电 / Use nitre to charge",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
        name = "wx78_discharge",
        label = "输电 / Discharge",
        hover = '消耗电量为晨星或电刑机恢复耐久\nDischarge on Night Stick or Zaptrocuter',
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },
	{
		name = "wx78_dry",
		label = "更快干燥 / Dry faster",
		hover = "潮湿度下降速率提升\n(身为机器人，比热容更小，很合理吧)",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "wx78_noknockedout",
		label = "催眠抗性 / Knockedout Resistance",
		hover = "被催眠时不会进入倒地状态\n(机器人可以拟人，但不能完全拟人)",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "wx78_erase",
		label = "擦纸 / Erase Paper",
		hover = "在地上右键擦纸，类似制图台的功能",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "wx78_scandatacrafts",
		label = "生物数据工艺 / Data Crafts",
		hover = "与生物数据有关的配方\nSome recipes about Bio Data",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "wx78_scrapcrafts",
		label = "废料工艺 / Scrap Crafts",
		hover = "与废料有关的配方\nSome recipes about Scrap",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},


	Title("配方调整 / Recipes"),
	MainSwitch("recipes"),
	RecipeOptions("scanner", "扫描仪 / Scanner", "1电子元件 + 1蜘蛛丝 + 1齿轮 + 1废铁", "1电子元件 + 1蜘蛛丝"),
	RecipeOptions("health1", "强化 / Hardy", "3生物数据 + 1告密的心", "2生物数据 + 1蜘蛛腺体"),
	RecipeOptions("health", "超级强化 / S.Hardy", "8生物数据 + 1重生护符 + 1强化电路", "4生物数据 + 2蜘蛛腺体 + 1强化电路"),
	RecipeOptions("sanity1", "处理器 / Processing", "3生物数据 + 5金块", "1生物数据 + 1花瓣"),
	RecipeOptions("sanity", "超级处理器/ S.Processing", "8生物数据 + 12噩梦燃料 + 4电子原件 + 1处理器电路", "3生物数据 + 1噩梦燃料 + 1处理器电路"),
	RecipeOptions("bee", "豆增压 / Beanbooster", "20生物数据 + 4蜂王浆 + 三种超级电路", "8生物数据 + 1蜂王浆 + 1超级处理器电路"),
	RecipeOptions("music", "合唱盒 / Chorusbox", "20生物数据 + 三种贝壳钟 + 热能电路 + 制冷电路", "4生物数据 + 1低音贝壳钟"),
	RecipeOptions("hunger1", "胃增益 / Gastrogain", "2生物数据 + 3狗牙 + 10怪物肉", "2生物数据 + 1狗牙"),
	RecipeOptions("hunger", "超级胃增益 / S.Gastrogain", "3生物数据 + 1饥饿腰带 + 1胃增益电路", "3生物数据 + 1啜食者皮 + 1胃增益电路"),
	RecipeOptions("heat", "热能 / Thermal", "10生物数据 + 2红宝石 + 1龙鳞", "4生物数据 + 1红宝石"),
	RecipeOptions("cold", "制冷 / Refrigerant", "10生物数据 + 2蓝宝石 + 1巨鹿眼球", "4生物数据 + 1蓝宝石"),
	RecipeOptions("taser", "电气化 / Electrification", "10生物数据 + 1晨星", "5生物数据 + 1羊奶"),
	RecipeOptions("night", "光电 / Optoelectronic", "8生物数据 + 1紫宝石 + 1鼹鼠", "4生物数据 + 1鼹鼠 + 1萤火虫"),
	RecipeOptions("light", "照明 / Illumination", "10生物数据 + 2黄宝石", "6生物数据 + 1荧光果"),
	RecipeOptions("light2", "超级照明 / S.Illumination", "20生物数据 + 2橙宝石 + 1照明电路 + 1光电电路", "6生物数据 + 1萤火虫 + 1照明电路"),
	RecipeOptions("digestion", "再消化 / Redigestion", "5生物数据 + 1绿宝石", "2生物数据 + 1猫尾"),
	RecipeOptions("spin", "旋转 / Spin", "20生物数据 + 6齿轮 + 3超级加速电路", "6生物数据 + 1鹅毛"),
	RecipeOptions("shielding", "格挡 / Blocking", "6生物数据 + 1大理石甲", "6生物数据 + 1背壳头盔"),


	Title("扫描仪"),
	MainSwitch("scanner"),
	{
		name = "scanner_inv",
		label = "物品栏扫描 / Scan Inv.",
		hover = "鼠标拿起扫描仪以扫描物品栏中的物品\nTake scanner in mouse and scan the inventory items",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "scanner_more",
		hover = "拟态蠕虫，毒菌蟾蜍, 眼球Boss, 蘑菇地精\nMimicreep, Toadstool, Eye Bosses, Mush Gnome",
		label = "更多扫描对象 / More To Scan",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "scanner_container",
		label = "容器 / Container",
		hover = "扫描仪在物品状态时具有15格空间\n可储存WX78相关物品和一些机械零件",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "scanner_unload",
		label = "卸货按钮 / Unload Button",
		hover = "一键丢弃所有物品\nDrop all items by a button",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "scanner_perish_mult",
		label = "保鲜效果 / Preserver",
		hover = "为扫描仪中有新鲜度的物品保鲜",
		options = {
			{description = "熊桶 / Bearger Bin", data = 0.05},
			{description = "盐盒 / Salt Box", data = 0.25},
			{description = "冰箱 / Ice Box", data = 0.5},
			{description = "厨师袋 / Chef Pouch", data = 0.75},
			{description = "否 / Off", data = 1},
		},
		default = 0.25,
	},	
	{
		name = "scanner_repair",
		label = "电路修复 / Circuit Repairer",
		hover = "自动修复装在扫描仪中的电路",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "scanner_repairperiod",
		label = "修复间隔 / Repair Period",
		hover = "单位：秒 / Unit: Second",
        options = {	
            {description = "5", data = 5},
			{description = "7.8 !", data = 7.8},
            {description = "10", data = 10},
            {description = "15", data = 15},
            {description = "20", data = 20},
            {description = "25", data = 25},
            {description = "30", data = 30},
            {description = "40", data = 40},
            {description = "50", data = 50},
            {description = "60", data = 60},
            {description = "78 !", data = 78},
            {description = "90", data = 90},
        },
		default = 60,
	},
	{
		name = "scanner_spd",
		label = "移速 / Speed",
		hover = "",
		options = {
			{description = "x1", data = 1},
			{description = "x1.5", data = 1.5},
			{description = "x2", data = 2},
			{description = "x2.5", data = 2.5},
			{description = "x3", data = 3},
			{description = "x4", data = 4},
		},
		default = 1.5,
	},
	{
		name = "scanner_scantime",
		label = "扫描时间 / Scan Time",
		hover = "单位：秒 / Unit: Second",
        options = {
            {description = "1", data = 1},
            {description = "3", data = 3},
            {description = "5", data = 5},
            {description = "7.8 !", data = 7.8},
            {description = "10", data = 10},
            {description = "15", data = 15},
        },
		default = 5,
	},
	{
		name = "scanner_scantime2",
		label = "史诗级扫描时间 / Epic Scan Time",
		hover = "单位：秒 / Unit: Second",
        options = {
            {description = "1", data = 1},
            {description = "3", data = 3},			
            {description = "5", data = 5},
			{description = "7.8 !", data = 7.8},
            {description = "10", data = 10},
            {description = "15", data = 15},
            {description = "20", data = 20},
        },
		default = 10,
	},


	Title("测绘机 / Roto-Mapper"),
	MainSwitch("scout"),
	{
		name = "scout_spd",
		label = "移速 / Speed",
		hover = "",
		options = {
			{description = "x1", data = 1},
			{description = "x2", data = 2},
			{description = "x3", data = 3},
			{description = "x4", data = 4},
			{description = "x5", data = 5},
		},
		default = 2,
	},	


	Title("电刑机 / Zaptrocute"),
	MainSwitch("zap"),
	{
		name = "zap_no_aggro",
		label = "无仇恨 / No Aggro",
		hover = "命中时不引起仇恨\nDo not attract aggro when hit",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},


	Title("运输机 / Delivery"),
	MainSwitch("delivery"),
	{
		name = "delivery_spd",
		label = "移速 / Speed",
		hover = "",
		options = {
			{description = "x1", data = 1},
			{description = "x2", data = 2},
			{description = "x3", data = 3},
			{description = "x4", data = 4},
			{description = "x5", data = 5},
		},
		default = 4,
	},	
	{
		name = "delivery_glow",
		label = "微光 / Glow",
		hover = "发出一点点亮光\nGlow a bit",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},


	Title("抓取机 / Harvester"),
	MainSwitch("harvester"),
	{
		name = "harvester_spd",
		label = "移速 / Speed",
		hover = "",
		options = {
			{description = "x1", data = 1},
			{description = "x2", data = 2},
			{description = "x3", data = 3},
			{description = "x4", data = 4},
			{description = "x5", data = 5},
		},
		default = 3,
	},	


	Title("破绽机 / Debuffer"),
	MainSwitch("debuffer"),
	{
		name = "debuffer_spd",
		label = "移速 / Speed",
		hover = "",
		options = {
			{description = "x1", data = 1},
			{description = "x2", data = 2},
			{description = "x3", data = 3},
			{description = "x4", data = 4},
			{description = "x5", data = 5},
		},
		default = 2,
	},		
	{
		name = "debuffer_mult",
		label = "伤害倍率 / DMG-Mult",
		hover = "决定易伤和WX78的增伤倍率\nDetermines the mult of vulnerability and WX78's damage",
        options = {
            {description = "0", data = 0},
            {description = "1%", data = 0.01},
            {description = "2%", data = 0.02},
            {description = "3%", data = 0.03},
            {description = "4%", data = 0.04},
            {description = "5%", data = 0.05},
            {description = "6%", data = 0.06},
            {description = "7%", data = 0.07},
            {description = "8%", data = 0.08},
            {description = "9%", data = 0.09},
            {description = "10%", data = 0.1},
        },
		default = 0.05,
	},
	{
		name = "debuffer_vulnerable",
		label = "易伤 / Vulnerable",
		hover = "让目标受到更多伤害\nMake the target take more damage",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "debuffer_slow",
		label = "减速 / Slow",
		hover = "让目标的移速减少\nMake the target move slower",
        options = {
            {description = "0", data = 0},
            {description = "10%", data = 0.1},
            {description = "15%", data = 0.15},
            {description = "20%", data = 0.2},
            {description = "25%", data = 0.25},
            {description = "30%", data = 0.3},
            {description = "35%", data = 0.35},
            {description = "40%", data = 0.4},
            {description = "45%", data = 0.45},
            {description = "50%", data = 0.5},
        },
		default = 0.25,
	},	


	Title("备份底盘 / Backup Chassis"),
	MainSwitch("backup"),
	{
		name = "backup_ui",
		hover = "装备栏相关\nAbout equip-slot-bar",
		label = "操作界面 / UI",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "backup_everyone",
		hover = "所有人都可打开\nEveryone can open",
		label = "来者不拒 / For Everyone",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},		
	{
		name = "backup_limit",
		hover = "在原上限的基础上增加\nAdd to the original limit",
		label = "额外上限 / Limit+",
		options = {
			{description = "0", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			--不能再加,7是tinybyte网络变量的上限
		},
		default = 4,
	},	
	{
		name = "backup_protection",
		hover = "",
		label = "不能被锤 / No Hammered",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "backup_no_collision",
		hover = "",
		label = "无碰撞体积 / No Collision",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "backup_return",
		hover = "同时三级捕获可用，并且将返还本身\nAnd the Lv.3 one is available now and returns itself",
		label = "返还捕获机 / Return Encapsulator",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "backup_quick",
		hover = "",
		label = "快速传输 / Quick Transfer",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},


	Title("附身底盘 / Possessed Chassis"),
	MainSwitch("bro"),
	{
		name = "bro_ui",
		hover = "现在可以被打开\nNow can be opened",
		label = "操作界面 / UI",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "bro_detail",
		hover = "你不会想关掉的\nYou won't want to turn off it",
		label = "细节优化 / Detail Optimizing",
		options = {
			{description = "是 / On", data = true},
			--{description = "否 / Off", data = false},
		},
		default = true,
	},		
	{
		name = "bro_no_collision",
		hover = "",
		label = "无碰撞体积 / No Collision",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "bro_normal_damage",
		hover = "伤害倍率变为100%\n100% damage-mult",
		label = "正常伤害 / Normal Damage",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "bro_recycle",
		hover = "满血时可用幻灵捕获机回收虚影\nWhen at Max-HP, can be recycled by Phasmo-Encapsulator",
		label = "回收 / Recycle",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	


	Title("灵体传输模块 / Transfer"),
	MainSwitch("transfer"),
	{
		name = "transfer_remote",
		hover = "用于指挥附身底盘和一些无人机\nUsed to conduct Possessed Chassis and some drones",
		label = "遥控器 / Remote",
		options = {
			{description = "是 / On", data = true},
			--{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "transfer_quick",
		hover = "",
		label = "快速动作 / Quick Action",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	

	Title("电气化 / Electrification"),
	Title("(覆盖技能树 / Kill skilltree)"),
	MainSwitch("taser"),	
    {
        name = "taser_limit",
        label = "叠加上限 / Stack Limit",
        hover = "平衡性选项\nFor balance",
        options = {
            {description = "无 / Off", data = 0},
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
        },
        default = 2
    },	
    {
        name = "taser_dmg1",
        label = "反伤 / Damage Back",
        hover = "对常规目标1.5倍；对潮湿目标2.5倍；对绝缘目标1倍",
        options = {
            {description = "无 / Off", data = -1},
            {description = "7", data = 7},
            {description = "10", data = 10},
            {description = "15", data = 15},
            {description = "20", data = 20},
            {description = "30", data = 30},
            {description = "40", data = 40},
            {description = "50", data = 50},
            {description = "60", data = 60},
            {description = "70", data = 70},
            {description = "78 !", data = 78},
        },
        default = 20
    },
    TaserRangeOptions("taser_range1", 3),
	{
		name = "taser_zap",
		label = "跳闸冷却 / Trip CD",
		hover = "右键主动释放反伤效果，会使得生物进入电击状态\n期间可以躲避伤害",
		options = {
			{description = "关闭跳闸 / No Trip", data = false},
			{description = "无冷却 / No CD", data = 0},
			{description = "0.5", data = 0.5},
			{description = "0.78 !", data = 0.78},
			{description = "1", data = 1},
			{description = "1.5", data = 1.5},
			{description = "2", data = 2},
			{description = "2.5", data = 2.5},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
		},
		default = 2,
	},
	{
		name = "taser_zap_cost",
		label = "血量消耗 / Health Cost",
		hover = "决定使用跳闸时消耗的血量\n不足40%时消耗电量代替",
		options = {
			{description = "0", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
		},
		default = 3,
	},	
    {
        name = "taser_dmg2",
        label = "增伤 / Damage Boost",
        hover = "对常规目标1.5倍；对潮湿目标2.5倍；对绝缘目标1倍",
        options = {
            {description = "无", data = -1},
            {description = "5", data = 5},
            {description = "10", data = 10},
            {description = "11", data = 11},
            {description = "15", data = 15},
            {description = "20", data = 20},
            {description = "25", data = 25},
            {description = "30", data = 30},
            {description = "35", data = 35},
            {description = "40", data = 40},
            {description = "50", data = 50},
            {description = "60", data = 60},
            {description = "70", data = 70},
            {description = "78 !", data = 78},
        },
        default = 11
    },
	TaserRangeOptions("taser_range2", 0),
    {
        name = "taser_dmgtype",
        label = "伤害类型 / Damage Type",
        hover = "物理伤害可以被护甲抵挡\n穿甲伤害无视护甲和非绝缘目标的减伤效果",
        options = {
            --{description = "物理 / Physic", data = 1},
            {description = "穿甲 / Ignore Armor", data = 2},
        },
        default = 2
    },	
    {
        name = "taser_pvp",
        label = "PVP",
        hover = "决定反伤和增伤是否对玩家生效\n(不得不说，这玩意儿在原版除了PVP还真没啥用)",
        options = {
            {description = "是 / On", data = 1},
            {description = "自动 / Auto", data = 2},
            {description = "否 / Off", data = 3},
        },
        default = 2
    },


	Title("制冷 & 热能 / Thermal & Refrigerant"),
	{
		name = "coldheat_temperature",
		label = "温度额外影响 / Extra temprature modifier",
		hover = "在原来影响20度的温度上下限的基础上再增加影响",
		options = {
			{description = "0", data = 0},
			{description = "4", data = 4},
			{description = "6", data = 6},
			{description = "7.8 !", data = 7.8},
			{description = "10", data = 10},
			{description = "12", data = 12},
			{description = "15", data = 15},
			{description = "20", data = 20},
		},
		default = 12,
	},	


	Title("制冷 / Refrigerant"),
	MainSwitch("cold"),
	{
		name = "cold_extinguish",
		label = "灭火 / Extinguish",
		hover = "左键灭火，也可扑灭闷烧物品",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "cold_ice",
		label = "结冰潮湿值 / Icey Moisture",
		hover = "",
		options = {
			{description = "5", data = 4},
			{description = "7.8 !", data = 7.8},
			{description = "10", data = 9},
			{description = "14", data = 13},
			{description = "16", data = 18},
			{description = "20", data = 19},
			{description = "30", data = 29},
			{description = "40", data = 39},
			{description = "50", data = 49},
			{description = "95", data = 94},
		},
		default = 9,
	},	
	{
		name = "cold_icenum",
		label = "结冰数量 / Ice Num",
		hover = "",
		options = {
			{description = "0", data = 0},
			{description = "1", data = 1},
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "6", data = 6},
			{description = "7", data = 7},
			{description = "8", data = 8},
		},
		default = 1,
	},	
	{
		name = "cold_fireresist",
		label = "火焰抗性 / Fire Resistance",
		hover = "",
		options = {
			{description = "0", data = 0},
			{description = "40%", data = 0.4},
			{description = "50%", data = 0.5},
			{description = "60%", data = 0.6},
			{description = "78% !", data = 0.78},
			{description = "90%", data = 0.9},
			{description = "100%", data = 1},
		},
		default = 1,
	},	


	Title("热能 / Thermal"),
	MainSwitch("heat"),
	{
		name = "heat_cooker",
		label = "烹饪 / Cooker",
		hover = "右键烹饪",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "heat_freezeimmune",
		label = "冰冻免疫 / No Freeze",
		hover = "被冰冻时自动解除冰冻，不损失电量\n需要激活才能生效",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "heat_waterproof",
		label = "潮湿免疫 / Moisture Immunity",
		hover = "",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},


	Title("合唱盒 / Chorusbox"),
	MainSwitch("music"),
	{
        name = "music_no_follower",
        label = "关闭招募 / Disable Recruit",
        hover = '不再自动招募猪人和兔人等(这真的很烦)\nStop letting pig or bunny or something in (REALLY ANNOYING)',
        options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
        },
        default = true
    },
	{
        name = "music_heat_cold",
        label = "冷热协调 / Thermolator",
        hover = '具有热能电路和制冷电路的效果，且不再过冷或过热\nThermal Circuit + Refrigerant Circuit, and never over heat or cold',
        options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
        },
        default = true
    },		
	{
        name = "music_wet",
        label = "潮湿目标 / Wet Taget",
        hover = '',
        options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
        },
        default = true
    },	
	{
        name = "music_farm",
        label = "自动浇水 / Auto-Water",
        hover = '站在耕地或作物上时自动浇水\nWater farm or plants when standing on them',
        options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
        },
        default = true
    },		
    {
        name = "music_sanityaura",
        label = "精神光环 / Sanity Aura",
        hover = "单位：每分钟",
        options = {
            {description = "0", data = 1},
            {description = "2.22", data = 2},
            {description = "4.44", data = 3},
            {description = "6.66", data = 4},
            {description = "7.8 !", data = 5},
            {description = "10", data = 6},
            {description = "20", data = 7},
        },
        default = 4
    },
    {
        name = "music_spd",
        label = "移速加成 / Speed Up",
        hover = "不可叠加 / No stack",
        options = {
            {description = "0", data = 1},
            {description = "10%", data = 1.1},
            {description = "15%", data = 1.15},
            {description = "20%", data = 1.2},
            {description = "25%", data = 1.25},
            {description = "30%", data = 1.3},
            {description = "40%", data = 1.4},
            {description = "50%", data = 1.5},
            {description = "60%", data = 1.6},
            {description = "70%", data = 1.7},
            {description = "78% !", data = 1.78},
        },
        default = 1.1
    },
    {
        name = "music_beatcombo",
        label = "战斗模式 / Combat Mode",
		hover = "不可叠加 / No stack",
        options = {
            {description = "无", hover = "不加成", data = 0},
            {description = "自动取消后摇", hover = "攻击间隔缩短大约40%，出现模组冲突时建议切换至其他项", data = 1},
            {description = "伤害倍率", hover = "伤害x1.25，兼容性较好", data = 2},
        },
        default = 1
    },	
	{
        name = "music_music",
        label = "音乐 / Music",
        hover = "",
        options = {
            {description = "无 / Off", data = 0},
            {description = "原版 / Vanilla", data = 1},
            {description = "死亡魅力", data = 2},
        },
        default = 0
    },
	MusicVolumeOptions(),


	Title("加速 / Acceleration"),
	MainSwitch("speed"),
    {
        name = "speed_least",
        label = "最低加速 / Min Speed Up",
        hover = "从第四个开始使用\nStart at 4th and then",
        options = {
            {description = "0", data = 0},
            {description = "3%", data = 0.03},
            {description = "5%", data = 0.05},
            {description = "7%", data = 0.07},
            {description = "10%", data = 0.1},
        },
        default = 0
    },	
    {
        name = "speed_noquipslow",
        label = "装备不减速 / No Equip-Slow",
        hover = "例如猪皮包和大理石甲\ne.g. Piggyback and Marble Suit",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },
    {
        name = "speed_guarantee",
        label = "移速保底 / Speed Guarantee",
        hover = "最低移速不会低于基础移速\nControl minimum speed to basic speed",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },

	Title("强化 / Hardy"),
	Title("(覆盖技能树 / Kill skilltree)"),
	MainSwitch("health"),
    {
        name = "health_absorb",
        label = "减伤 / Absorption",
        hover = "超级版为2倍；相同电路不叠加效果\nSuper version is 2x; not stackable with the same circuit",
        options = {
            {description = "0", data = 0},
            {description = "2.5%", data = 0.025},
            {description = "5%", data = 0.05},
            {description = "7.8% !", data = 0.078},
            {description = "10%", data = 0.1},
            {description = "12.5%", data = 0.125},
            {description = "15%", data = 0.15},
        },
        default = 0.1
    },
    {
        name = "health_antistiff",
        label = "受击硬直抗性 / Anti-Stiff",
        hover = "受击不再具有硬直动作；超级版还能防击飞和黏住\nNo animation when hit; Super version prevents knock back and slimed",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },
	
	
	Title("处理器 / Processing"),
	MainSwitch("sanity"),
    {
        name = "sanity_quickpick",
        label = "快速采集 / Quick Pick",
        hover = "超级版比普通版更快\n出现模组冲突时建议关闭该项",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },	
    {
        name = "sanity_quickfram",
        label = "快速耕作 / Quick Fram",
        hover = "超级版比普通版更快\n出现模组冲突时建议关闭该项",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },	
    {
        name = "sanity_quickcraft",
        label = "快速制造 / Quick Craft",
        hover = "超级版比普通版更快\n出现模组冲突时建议关闭该项",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },
    {
        name = "sanity_sailmult",
        label = "航海加成 / Sail Up",
        hover = "普通版和超级版无区别；加成系数同沃尔夫冈强壮形态\n不可叠加",
        options = {
            {description = "是 / On", data = true},
            {description = "否 / Off", data = false},
        },
        default = true
    },	
    {
        name = "sanity_workmult1",
        label = "砍伐和挖掘效率加成 / Chop and Dig Up",
        hover = "超级版为2倍；相同电路不叠加效果\nSuper version is 2x; not stackable with the same circuit",
        options = {
            {description = "0", data = 1},
            {description = "15%", data = 1.15},
            {description = "20%", data = 1.2},
            {description = "30%", data = 1.3},
            {description = "40%", data = 1.4},
            {description = "50%", data = 1.5},
            {description = "60%", data = 1.6},
            {description = "70%", data = 1.7},
            {description = "78% !", data = 1.78},
        },
        default = 1.5
    },
    {
        name = "sanity_workmult2",
        label = "敲击效率加成 / Mine and Hammer Up",
        hover = "普通版和超级版无区别；相同电路不叠加效果\nSuper version is 2x; not stackable with the same circuit",
        options = {
            {description = "0", data = 1},
            {description = "15%", data = 1.15},
            {description = "20%", data = 1.2},
            {description = "30%", data = 1.3},
            {description = "40%", data = 1.4},
            {description = "50%", data = 1.5},
            {description = "60%", data = 1.6},
            {description = "70%", data = 1.7},
            {description = "78% !", data = 1.78},
        },
        default = 1.5
    },


	Title("胃增益 / Gastrogain"),
	MainSwitch("hunger"),
	{
		name = "hunger_strongstomach",
		label = "强大的胃 / Strong Stomach",
		hover = "食物不会扣除属性\n超级版还会翻倍食物属性 (1.5倍)",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "hunger_fastcharge",
		label = "饥饿充电 / Hunger Charge",
		hover = "无论是否激活，在电量未满的情况下，每隔3秒消耗饥饿值恢复一格电量\n饥饿值低于78%时不生效",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "hunger_fastchargecost",
		label = "饥饿消耗 / Hunger Cost",
		hover = "",
		options = {
			{description = "0", data = 0},
			{description = "5", data = 5},
			{description = "7.8 !", data = 7.8},
			{description = "10", data = 10},
			{description = "15", data = 15},
			{description = "20", data = 20},
			{description = "30", data = 30},
			{description = "40", data = 40},
			{description = "50", data = 50},
		},
		default = 15,
	},	


	Title("豆增压 / Beanbooster"),
	Title("(覆盖技能树 / Kill skilltree)"),
	MainSwitch("bee"),
	{
		name = "bee_3in1",
		label = "三合一 / 3 in 1",
		hover = "超级强化  + 超级处理器 + 超级胃增益\n S.Hardy + S.Processing + S.Gastrogain",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},
	{
		name = "bee_negsanimmune",
		label = "噩梦光环免疫 / Neg-sanity Aura Immunity",
		hover = "",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	{
		name = "bee_heal",
		label = "治疗量 / Heal Value",
		hover = "",
		options = {
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "7.8 !", data = 7.8},
			{description = "10", data = 10},
			{description = "12", data = 12},
			{description = "15", data = 15},
			{description = "20", data = 20},
		},
		default = 5,
	},	
	{
		name = "bee_healperiod",
		label = "治疗间隔 / Heal Period",
		hover = "单位：秒 / Unit: Second",
		options = {
			{description = "2", data = 2},
			{description = "3", data = 3},
			{description = "4", data = 4},
			{description = "5", data = 5},
			{description = "7.8 !", data = 7.8},
			{description = "10", data = 10},
			{description = "12", data = 12},
			{description = "15", data = 15},
			{description = "20", data = 20},
			{description = "25", data = 25},
			{description = "30", data = 30},
		},
		default = 5,
	},


	Title("照明 / Illumination"),
	Title("(覆盖技能树 / Kill skilltree)"),
	MainSwitch("light"),
    {
        name = "light_radius",
        label = "半径",
        hover = "单位：墙体 / Unit: Wall",
        options = {
            {description = "1.25", data = 1.25},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "3.5", data = 3.5},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "7", data = 7},
            {description = "7.8 !", data = 7.8},
            {description = "10", data = 10},
            {description = "15", data = 15},
            {description = "20", data = 20},
        },
        default = 6
    },
    {
        name = "light_spd",
        label = "移速加成 / Speed Up",
        hover = "不可叠加 / No stack",
        options = {
            {description = "0", data = 1},
            {description = "10%", data = 1.1},
            {description = "15%", data = 1.15},
            {description = "20%", data = 1.2},
            {description = "25%", data = 1.25},
            {description = "30%", data = 1.3},
            {description = "35%", data = 1.35},
            {description = "40%", data = 1.4},
            {description = "50%", data = 1.5},
            {description = "60%", data = 1.6},
            {description = "70%", data = 1.7},
            {description = "78% !", data = 1.78},
        },
        default = 1.2
    },
	
	
	Title("超级照明 / S.Illumination"),
	Title("(覆盖技能树 / Kill skilltree)"),
	MainSwitch("light2"),
    {
        name = "light2_2in1",
        label = "二合一 / 2 in 1",
        hover = "照明电路 + 光电电路\n Illumination + Optoelectronic",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
    },
	
	
	Title("空间扩展 / Spatializer"),
	MainSwitch("stacksize"),
    {
        name = "stacksize_togamma",
        label = "伽玛栏 / To Gamma",
        hover = "包括贴图修改\nAlso changes the sprite",
		options = {
			{description = "是 / On", data = true},
			--{description = "否 / Off", data = false},
		},
		default = true,
    },	
	
	
	Title("再消化 / Redigestion"),
	MainSwitch("digestion"),
    {
        name = "digestion_num",
        label = "所需腐烂物 / Spoiled Needed",
        hover = "用于产出营养砖\nFor Nutribrick",
        options = {
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
        },
        default = 1,
    },
    {
        name = "digestion_fast",
        label = "快速生产 / Fast Production",
        hover = "营养砖将直接进入物品栏\nNutribrick will go into inventory",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
    },	
    {
        name = "digestion_mimic",
        label = "模仿 / Mimic",
        hover = "复制另一个电路的能力，除了空间扩展电路\nCopy another circuit, except Spatializer",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
    },
	
	
	Title("旋转 / Spin"),
	MainSwitch("spin"),
	{
        name = "spin_efficiency",
        label = "消耗率 / Consumption",
        hover = "决定武器的消耗量\nDetermine the consumption of weapons",
        options = {
            {description = "0", data = 0},
            {description = "10%", data = 0.1},
            {description = "15%", data = 0.15},
            {description = "20%", data = 0.2},
            {description = "25%", data = 0.25},
            {description = "30%", data = 0.3},
            {description = "40%", data = 0.4},
            {description = "50%", data = 0.5},
            {description = "60%", data = 0.6},
            {description = "70%", data = 0.7},
            {description = "80%", data = 0.8},
            {description = "90%", data = 0.9},
            {description = "100%", data = 1},
        },
        default = 0.5,
    },
	{
        name = "spin_efficiency2",
        label = "采集消耗率 / Pick Consumption",
        hover = "决定武器的消耗量\nDetermine the consumption of weapons",
        options = {
            {description = "0", data = 0},
            {description = "10%", data = 0.1},
            {description = "15%", data = 0.15},
            {description = "20%", data = 0.2},
            {description = "25%", data = 0.25},
            {description = "30%", data = 0.3},
            {description = "40%", data = 0.4},
            {description = "50%", data = 0.5},
            {description = "60%", data = 0.6},
            {description = "70%", data = 0.7},
            {description = "80%", data = 0.8},
            {description = "90%", data = 0.9},
            {description = "100%", data = 1},
        },
        default = 0.1,
    },	
    {
        name = "spin_3speed",
        label = "三重加速 / 3x Acceleration",
        hover = "具有三个加速电路的效果\nHaving the effect of 3 Acceleration Circuits",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
    },
    {
        name = "spin_fast",
        label = "高速旋转 / Fast Spin",
        hover = "大幅提升旋转速度\nSignificantly increase spin speed",
		options = {
			{description = "否 / Off", data = false},
			{description = "1.5x", data = 1.5},
			{description = "1.75x", data = 1.75},
			{description = "2x", data = 2},
		},
		default = 1.75,
    },
    {
        name = "spin_long",
        label = "持久旋转 / Persistent Spin",
        hover = "旋转可持续78分钟\nSpin duration increases to 78 minutes",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
    },	
	
	
	Title("格挡 / Blocking"),
	MainSwitch("shielding"),	
    {
        name = "shielding_absorption",
        label = "格挡减伤 / Blocking Absorption",
        hover = "格挡时生效\nEffective during blocking",
        options = {
            {description = "50%", data = 0.5},
            {description = "55%", data = 0.45},
            {description = "60%", data = 0.4},
            {description = "70%", data = 0.3},
            {description = "75%", data = 0.25},
            {description = "78% !", data = 0.18},
            {description = "80%", data = 0.2},
            {description = "85%", data = 0.15},
            {description = "90%", data = 0.1},
            {description = "95%", data = 0.05},
            {description = "99%", data = 0.01},
        },
        default = 0.05,
    },
	{
		name = "shielding_armor",
		label = "护甲格挡减伤 / Shielded Armors",
		hover = "格挡时的减伤也对装备的护甲生效\nAbsorb damage for equipped armors during blocking",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
    {
        name = "shielding_cd",
        label = "冷却 / Cooldown",
        hover = "单位：秒\nUnit: Second",
        options = {
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "8", data = 8},
            {description = "10", data = 10},
            {description = "12", data = 12},
            {description = "14", data = 14},
            {description = "16", data = 16},
            {description = "18", data = 18},
            {description = "20", data = 20},
        },
        default = 2,
    },
    {
        name = "shielding_capacity",
        label = "最大承伤 / Damage Capacity",
        hover = "达到该值后自动退出格挡\nStop blocking when damage taken is over the value",
        options = {
            {description = "100", data = 100},
            {description = "150", data = 150},
            {description = "200", data = 200},
            {description = "250", data = 250},
            {description = "300", data = 300},
            {description = "350", data = 350},
            {description = "400", data = 400},
            {description = "500", data = 500},
            {description = "780 !", data = 780},
        },
		default = 100,
    },	
    {
        name = "shielding_absorption_armor",
        label = "护甲减伤 / Armor Absorption",
        hover = "未进行格挡时生效\nEffective during not blocking",
        options = {
            {description = "0", data = 1},
            {description = "25%", data = 0.75},
            {description = "30%", data = 0.7},
            {description = "40%", data = 0.6},
            {description = "50%", data = 0.5},
            {description = "55%", data = 0.45},
            {description = "60%", data = 0.4},
            {description = "70%", data = 0.3},
            {description = "75%", data = 0.25},
            {description = "78% !", data = 0.18},
            {description = "80%", data = 0.2},
            {description = "85%", data = 0.15},
            {description = "90%", data = 0.1},
            {description = "95%", data = 0.05},
            {description = "99%", data = 0.01},
        },
        default = 0.75,
    },


	Title("声波 / Sonic"),
	MainSwitch("screech"),
    {
        name = "screech_range",
        label = "半径 / Radius",
        hover = "单位：墙体，可叠加\nUnit: Wall, stackable",
        options = {
            {description = "12", data = 12},
            {description = "14", data = 14},
            {description = "16", data = 16},
            {description = "18", data = 18},
            {description = "20", data = 20},
            {description = "22", data = 22},
            {description = "24", data = 24},
        },
		default = 14,
    },
    {
        name = "screech_cd",
        label = "冷却 / Cooldown",
        hover = "单位：秒\nUnit: Second",
        options = {
            {description = "1", data = 1},
            {description = "2", data = 2},
            {description = "3", data = 3},
            {description = "4", data = 4},
            {description = "5", data = 5},
            {description = "6", data = 6},
            {description = "8", data = 8},
            {description = "10", data = 10},
            {description = "12", data = 12},
            {description = "14", data = 14},
            {description = "16", data = 16},
            {description = "18", data = 18},
            {description = "20", data = 20},
        },
        default = 10,
    },
	{
		name = "screech_shadow",
		label = "恐惧影怪 / Panic Shadows",
		hover = "恐惧效果对影怪生效\nPanic shadow creatures now",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	
	
	Title("光电 / Optoelectronic"),
	MainSwitch("night"),
	{
		name = "night_goggle",
		label = "护目镜效果 / Goggle Effect",
		hover = "防止风暴减速\nPrevent being slowed by storms",
		options = {
			{description = "是 / On", data = true},
			{description = "否 / Off", data = false},
		},
		default = true,
	},	
	NightOptions("altar", "远古祭坛 / Altar"),
	NightOptions("archive_orchestrina", "远古合奏机 / Orchestrina"),
	NightOptions("atrium_gate", "远古大门 / Atrium Gate"),
	NightOptions("antlion", "蚁狮 / Antlion"),
	NightOptions("beefalo", "皮弗娄牛 / Beefalo"),
	NightOptions("beequeen", "巨大蜂窝 / Bee Queen"),
	NightOptions("chester", "眼骨和星空 / Eye Bone and Star-sky"),
	NightOptions("crabking", "帝王蟹 / Crab King"),
	NightOptions("daywalker", "大疯猪 / Werepig"),
	NightOptions("gears", "发条生物 / Gear creatures"),
	NightOptions("hermithouse", "隐士之家 / Hermit Home"),
	NightOptions("klaus_sack", "赃物袋 / Loot Stash"),
	NightOptions("lightninggoat", "伏特羊 / Volt Goat"),
	NightOptions("mandrake", "曼德拉草 / Mandrake"),
	NightOptions("moonbase", "月台 / Moon Stone"),
	NightOptions("monkeyqueen", "猴女王 / Monkey Queen"),
	NightOptions("pigking", "猪王 / Pig King"),
	NightOptions("saltstack", "盐堆 / Salt Stack"),
	NightOptions("sculpture", "可疑大理石 / Suspicious Marble"),
	NightOptions("toadstool", "毒菌蟾蜍 / Toadstool"),
	NightOptions("terrarium", "盒中泰拉 / Terrarium"),
	NightOptions("walrus", "海象 / Walrus"),
	NightOptions("moon_altar", "天体部件 / Moon Altar Component"),
	
}