local L = locale
local function translate(language_table)  -- use this fn can be automatically translated according to the language in the table
	language_table.zhr = language_table.zh
	language_table.zht = language_table.zht or language_table.zh
	return language_table[L] or language_table.en
end
--The name of the mod displayed in the 'mods' screen.
name = translate({en = "Status Announce", zh = "快捷宣告 (中文)", zht = "快捷宣告 (繁體中文)"})
--Who wrote this awesome mod?
author = "rezecib + 傳說覺悟 汉化"
--A version number so you can ask people if they are running an old version of your mod.
version = "2.13.8"
--A description of the mod.
description = translate({
	en = "version:"..version.."\n"..[[
Alt click parts of the HUD to announce their status (I'm wounded!, I have 2 twigs., We need more drying racks.). ALT+SHIFT click to announce items.
]],
	zh = "当前版本: "..version.."  更新：优化草图和蓝图名称；修复摄氏温度及多世界降雨宣告。\n"..[[
1、同屏宣告支持生物血量宣告，添加ping宣告；
2、Alt+Shift+鼠标左键/右键 点击周围物件进行宣告；
3、Alt+Shift+鼠标左键 点击季节时钟MOD 世界温度UI进行宣告世界温度与降雨；
4、Alt+Shift+鼠标左键 点击计分板TAB上的信号图标进行宣告延迟；
5、修复部分容器宣告显示MISSNAME的问题；

注：
1.同屏宣告，宣告群体可使用鼠标右键宣告为单体；
2.世界温度、雨宣告需要季节时钟开启世界温度显示；
3.MacOS 对应按键Alt > option，除非你改过键。

基于模组Status Announcements上汉化，并在 快捷宣告-Shang汉化 模组上进行修复发布；

按住 Alt 键单击 HUD 的某些部分以宣布它们的状态（我受伤了！、我有 2 根树枝。、我们需要更多的晾肉架。）。 Alt+Shift 单击以宣布项目。
]],
	zht = "當前版本: "..version.."  更新：優化草圖和藍圖名稱；修復攝氏溫度及多世界降雨宣告。\n"..[[
1、同屏宣告支持生物血量宣告，添加ping宣告；
2、Alt+Shift+滑鼠左鍵/右鍵 點擊周圍物件進行宣告；
3、Alt+Shift+滑鼠左鍵 點擊季節時鐘MOD 世界溫度UI進行宣告世界溫度與降雨；
4、Alt+Shift+滑鼠左鍵 點擊計分板TAB上的信號圖示進行宣告延遲；
5、修復部分容器宣告顯示MISSNAME的問題；

注：
1.同屏宣告，宣告群體可使用滑鼠右鍵宣告為單體；
2.世界溫度、雨宣告需要季節時鐘開啟世界溫度顯示；
3.MacOS 對應按鍵Alt > option，除非伱改過鍵。

基於模組Status Announcements上漢化，並在 快捷宣告-Shang漢化 模組上進行修復發佈；

按住 Alt 鍵按一下 HUD 的某些部分以宣佈它們的狀態（我受傷了！、我有 2 根樹枝。、我們需要更多的晾肉架。）。 Alt+Shift 按一下以宣佈專案。
]],
})
--This lets other players know if your mod is out of date. This typically needs to be updated every time there's a new game update.
api_version = 10
dst_compatible = true
--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = true

--This determines whether it causes a server to be marked as modded (and shows in the mod list)


--This lets people search for servers with this mod by these tags
server_filter_tags = {}

icon_atlas = "statusannouncements.xml"
icon = "statusannouncements.tex"

forumthread = ""

local options_list = {
	{description = translate({
		en = "Yes",
		zh = "是",
		}), data = true,},
	{description = translate({
		en = "No",
		zh = "否",
		}), data = false,},
}

--[[
Credits:
	A ton of people have helped with writing quotes, I wouldn't have been able to do it without them. A huge thanks to all of you!
	Character quotes:
		Most of the core crew of characters: Silentdarkness1
		Woodie: Acemurdock and OSMRhodey
		Webber, Wanda, Walter: SuperPsiPower (and friends)
		Wormwood + Wurt: Checkered Scars
		Wortox: RatRat
		Shipwrecked characters: Lying Cake
	Translators:
		Brazilian Portuguese: Vinicius Araújo
		Chinese: GoforDream and Shang
		German: Redhead
		Korean: AFS
		Spanish: Gum, oPt
		Russian: deshkas and Shire
]]

configuration_options =
{
	{
		name = "LANGUAGE",
		label = translate({en = "Which language to use",zh = "宣告语言",zht = "宣告語言"}),
		options =	{
						{description = translate({
							en = "Detect",
							zh = "自动检测",
							zht = "自動檢測",
						}), data = "detect", hover = translate({
							en = "Detect the language based on language mods installed.",
							zh = "根据安装的语言模块检测语言。",
							zht = "根據安裝的語言模組檢測語言。",
							}),
						},
						{description = "English", data = "english"},
						{description = "简体中文", data = "chinese"},
						{description = "繁體中文", data = "chinese_cht"},
					},
		default = translate({en = "detect",zh = "chinese",zht = "chinese_cht"}),
	},
	
	{
		name = "WHISPER",
		label = translate({
			en = "Whisper by default",
			zh = "默认宣告为密语",
			zht = "默認宣告為密語",
		}),
		hover = translate({
			en = "",
			zh = "习惯性设置，在游戏中宣告可以加 Ctrl 键互相切换私密与公开",
			zht = "習慣性設置，在遊戲中宣告可以加 Ctrl 鍵互相切換私密與公開",
		}),
		options =	{
						{description = translate({
							en = "Yes",
							zh = "是",
							}), data = true, hover = translate({
							en = "",
							zh = "Alt+Shift 宣告只有附近玩家能看到。",
							}),
						},
						{description = translate({
							en = "No",
							zh = "否",
							}), data = false, hover = translate({
							en = "",
							zh = "Alt+Shift 宣告全部玩家都能看到。",
							}),
						},
					},
		default = false,
	},
	
	{
		name = "EXPLICIT",
		label = translate({
			en = "Show current/max",
			zh = "显示(当前值)/(最大值)",
			zht = "顯示(當前值)/(最大值)",
			}),
		options =	{
						{description = translate({
							en = "Yes",
							zh = "是",
							}), data = true, hover = translate({
								en = "",
								zh = "开启是正确的选择。",
								zht = "開啟是正確的選擇。",
								}),},
						{description = translate({
							en = "No",
							zh = "否",
							}), data = false, hover = translate({
								en = "",
								zh = "关闭后异常的尴尬。",
								zht = "關閉後異常的尷尬。",
							}),
						},
					},
		default = true,
		hover = translate({
			en = "When announcing stats, show the numbers for your current and max stat.",
			zh = "在宣告三维状态时，是否显示当前值和最大值。(Current)/(Max)",
			zht = "在宣告三維狀態時，是否顯示當前值和最大值。(Current)/(Max)",
			}),
	},
	
	{
		name = "SHOWPROTOTYPER",
		label = translate({
			en = "Announce Prototyper",
			zh = "宣告标准原型体",
			zht = "宣告標準原型體",
			}),
		options = options_list,
		default = true,
		hover = translate({
			en = "When announcing a crafting recipe, whether to announce that you need a science machine or another prototyper.",
			zh = "宣告制定配方时，是否要宣告“你需要一个科学机器”或“一个原型样本”。",
			zht = "宣告制定配方時，是否要宣告“你需要一個科學機器”或“一個原型樣本”。",
			}),
	},
	
	{
		name = "SHOWEMOJI",
		label = translate({
			en = "Announce Emoji",
			zh = "宣告三维符号",
			zht = "宣告三維符號",
			}),
		options = options_list,
		default = true,
		hover = translate({
			en = "When announcing stats, show an emoji for the stat (if using \"Show current/max\").",
			zh = "宣告时，用图标来表示 (若不使用 \"当前值/最大值\").",
			zht = "宣告時，用圖標來表示 (若不使用 \"當前值/最大值\").",
			}),
	},
	
	{
		name = "SHOWDURABILITY",
		label = translate({
			en = "Announce Durability",
			zh = "宣告装备耐久性",
			zht = "宣告裝備耐久性",
			}),
		options = options_list,
		default = true,
		hover = translate({
			en = "Whether to announce the durability/freshness of an item when announcing that you have it.",
			zh = "是否要宣告一个装备的耐久性或耐用时限。",
			zht = "是否要宣告一個裝備的耐久性或耐用時限。",
			}),
	},
	
	{
		name = "OVERRIDEB",
		label = translate({
			en = "Controller Cancel",
			zh = "手柄控制器宣告",
			}),
		options = options_list,
		default = true,
		hover = translate({
			en = "When controller inventory is open, allow the B/cancel button\nto be used to announce temperature\n(if you are using Combined Status).",
			zh = "当使用手柄控制器且库存是打开时，允许用 B (取消按钮) 来宣告 体温。",
			zht = "當使用手柄控制器且庫存是打開時，允許用 B (取消按鈕) 來宣告 體溫。",
			}),
	},
	
	{
		name = "OVERRIDESELECT",
		label = translate({
			en = "Controller Map",
			zh = "手柄控制器地图宣告",
			zht = "手柄控制器地圖宣告",
			}),
		options = options_list,
		default = true,
		hover = translate({
			en = "When controller inventory is open, allow the SELECT/map button\nto be used to announce the season\n(if you are using Combined Status).",
			zh = "当使用手柄且库存是打开时, 允许使用按钮 选择/地图 来宣布季节\n你必须正在使用Mod：Combined Status(季节时钟).",
			zht = "當使用手柄且庫存是打開時, 允許使用按鈕 選擇/地圖 來宣佈季節\n你必須正在使用Mod：Combined Status(季節時鐘).",
			}),
	},
	
	{
		name = "HIDEANNOUNCEMENTS",
		label = translate({
			en = "Hide Announcements",
			zh = "隐藏宣告",
			zht = "隱藏宣告",
			}),
		options = options_list,
		default = false,
		hover = translate({
			en = "If you don't like other people announcing things constantly,\nyou can turn this on to filter out all announcements.",
			zh = "如果您不喜欢其他人不断地发布通知，您可以打开此功能以过滤掉所有通知。",
			zht = "如果您不喜歡其他人不斷地發佈通知，您可以打開此功能以過濾掉所有通知。",
			}),
	},
	
	{
		name = "WILSON",
		label = translate({
			en = "Custom Wilson Quotes",
			zh = "定制科学家 威尔逊语录",
			zht = "定制科學家 威爾遜語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是威尔逊时，会宣告科学家专有语录。",
			zht = "當你是威爾遜時，會宣告科學家專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WILLOW",
		label = translate({
			en = "Custom Willow Quotes",
			zh = "定制纵火者 薇洛语录",
			zht = "定制縱火者 薇洛語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是薇洛时，会宣告纵火者专有语录。",
			zht = "當你是薇洛時，會宣告縱火者專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WX78",
		label = translate({
			en = "Custom WX-78 Quotes",
			zh = "定制机器人 WX-78语录",
			zht = "定制機器人 WX-78語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是WX-78时，会宣告机器人专有语录。",
			zht = "當你是WX-78時，會宣告機器人專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WICKERBOTTOM",
		label = translate({
			en = "Custom Wickerbottom Quotes",
			zh = "定制 薇克巴顿 语录",
			zht = "定制 薇克巴頓 語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是薇克巴顿时，会宣告图书管理员专有语录。",
			zht = "當你是薇克巴頓時，會宣告圖書管理員專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WOLFGANG",
		label = translate({
			en = "Custom Wolfgang Quotes",
			zh = "定制大力士 沃尔夫冈语录",
			zht = "定制大力士 沃爾夫岡語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是沃尔夫冈时，会宣告大力士专有语录。",
			zht = "當你是沃爾夫岡時，會宣告大力士專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WENDY",
		label = translate({
			en = "Custom Wendy Quotes",
			zh = "定制 温蒂 语录",
			zht = "定制 溫蒂 語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是温蒂时，会宣告丧失亲人的女孩专有语录。",
			zht = "當你是溫蒂時，會宣告喪失親人的女孩專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WOODIE",
		label = translate({
			en = "Custom Woodie Quotes",
			zh = "定制伐木工 伍迪语录",
			zht = "定制伐木工 伍迪語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是伍迪时，会宣告伐木工专有语录。",
			zht = "當你是伍迪時，會宣告伐木工專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WES",
		label = translate({
			en = "Custom Wes Quotes",
			zh = "定制 韦斯 语录",
			zht = "定制 韋斯 語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是韦斯时，会宣告哑剧演员专有语录。",
			zht = "當你是韋斯時，會宣告默劇演員專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WAXWELL",
		label = translate({
			en = "Custom Maxwell Quotes",
			zh = "定制傀儡师 麦斯威尔语录",
			zht = "定制傀儡師 麥斯威爾語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是麦斯威尔时，会宣告傀儡师专有语录。",
			zht = "當你是麥斯威爾時，會宣告傀儡師專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WEBBER",
		label = translate({
			en = "Custom Webber Quotes",
			zh = "定制蜘蛛男孩 韦伯语录",
			zht = "定制蜘蛛男孩 韋伯語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是韦伯时，会宣告蜘蛛男孩专有语录。",
			zht = "當你是韋伯時，會宣告蜘蛛男孩專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WATHGRITHR",
		label = translate({
			en = "Custom Wigfrid Quotes",
			zh = "定制女武神 薇格弗德语录",
			zht = "定制女武神 薇格弗德語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是薇格弗德时，会宣告女武神专有语录。",
			zht = "當你是薇格弗德時，會宣告女武神專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WINONA",
		label = translate({
			en = "Custom Winona Quotes",
			zh = "定制女工人 薇诺娜语录",
			zht = "定制女工人 薇諾娜語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是薇诺娜时，会宣告女工人专有语录。",
			zht = "當你是薇諾娜時，會宣告女工人專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WORMWOOD",
		label = translate({
			en = "Custom Wormwood Quotes",
			zh = "定制植物人 沃姆伍德语录",
			zht = "定制植物人 沃姆伍德語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是沃姆伍德时，会宣告植物人专有语录。",
			zht = "當你是沃姆伍德時，會宣告植物人專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WURT",
		label = translate({
			en = "Custom Wurt Quotes",
			zh = "定制小鱼人 沃特语录",
			zht = "定制小魚人 沃特語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是沃特时，会宣告小鱼人专有语录。",
			zht = "當你是沃特時，會宣告小魚人專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WORTOX",
		label = translate({
			en = "Custom Wortox Quotes",
			zh = "定制小恶魔 沃拓克斯语录",
			zht = "定制小惡魔 沃拓克斯語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是小恶魔时，会宣告沃拓克斯专有语录。",
			zht = "當你是小惡魔時，會宣告沃拓克斯專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WARLY",
		label = translate({
			en = "Custom Warly Quotes",
			zh = "定制厨师 沃利语录",
			zht = "定制廚師 沃利語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是沃利时，会宣告厨师专有语录。",
			zht = "當你是沃利時，會宣告廚師專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WALANI",
		label = translate({
			en = "Custom Walani Quotes",
			zh = "定制冲浪者 瓦拉尼语录",
			zht = "定制沖浪者 瓦拉尼語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是瓦拉尼时，会宣告冲浪者专有语录。",
			zht = "當你是瓦拉尼時，會宣告沖浪者專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WOODLEGS",
		label = translate({
			en = "Custom Woodlegs Quotes",
			zh = "定制海盗船长 木腿语录",
			zht = "定制海盜船長 木腿語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是木腿时，会宣告海盗船长专有语录。",
			zht = "當你是木腿時，會宣告海盜船長專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WILBUR",
		label = translate({
			en = "Custom Wilbur Quotes",
			zh = "定制小红猪 威尔伯语录",
			zht = "定制小紅豬 威爾伯語錄",
			}),
		hover = translate({
			en = "",
			zh = "当你是威尔伯时，会宣告猪公主专有语录。",
			zht = "當你是威爾伯時，會宣告豬公主專有語錄。",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WANDA",
		label = translate({
			en = "Custom Wanda Quotes",
			zh = "定制 旺达 语录",
			zht = "定制 旺達 語錄",
			}),
		options = options_list,
		default = true,
	},
	
	{
		name = "WALTER",
		label = translate({
			en = "Custom Walter Quotes",
			zh = "定制 沃尔特 语录",
			zht = "定制 沃爾特 語錄",
			}),
		options = options_list,
		default = true,
	},
}
