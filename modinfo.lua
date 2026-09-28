local L = locale
local STEAM_WORKSHOP_URL = "https://steamcommunity.com/sharedfiles/filedetails/?id=3754888241"
local function translate(language_table)  -- use this fn can be automatically translated according to the language in the table
	language_table.zhr = language_table.zh
	language_table.zht = language_table.zht or language_table.zh
	return language_table[L] or language_table.en
end
--A version number so you can ask people if they are running an old version of your mod.
version = "2.13.16"
--The name of the mod displayed in the 'mods' screen.
name = translate({
	en = "Status Announce (Chinese)",
	zh = "快捷宣告（中文）",
	zht = "快捷宣告（中文）",
})
--Who wrote this awesome mod?
author = "Codex"
--A description of the mod.
description = translate({
	en = "Version: "..version.."  Update: added a controller radial announcement wheel.\n\n"..[[
Announce your status, inventory items, recipes, nearby entities, ping, world temperature and rain timing in chat.

Keyboard/mouse:
• Hold Alt and click HUD badges to announce their status.
• Hold Alt+Shift and left/right click visible world entities to announce single/group targets.
• Hold Alt+Shift and click supported Combined Status widgets to announce world temperature, rain timing or ping.

Controller:
• Hold Y to open the radial announcement wheel around your character.
• Use the left stick to select a target, Y to announce a single target, X to announce same-type targets, LB/RB to turn pages, and B to exit.

Steam Workshop:
]]..STEAM_WORKSHOP_URL,
	zh = "当前版本: "..version.."  更新：添加手柄径向宣告轮盘。\n\n"..[[
功能：
1、支持宣告角色状态、背包/容器物品、制作配方、附近实体、延迟、世界温度和降雨时间；
2、同屏宣告支持生物血量宣告，并支持 ping 宣告；
3、修复和优化多种原版/跨世界/容器/蓝图/草图宣告问题；
4、手柄支持围绕角色显示径向宣告轮盘。

键鼠操作：
• 按住 Alt 点击 HUD 状态图标宣告状态；
• 按住 Alt+Shift 左键/右键点击可见世界实体，宣告单体/同类；
• 按住 Alt+Shift 点击支持的季节时钟/计分板组件，宣告世界温度、降雨或延迟。

手柄操作：
• 长按 Y 打开角色周围的径向宣告轮盘；
• 左摇杆选择目标，Y 宣告单体，X 宣告同类，LB/RB 翻页，B 退出。

注：
1、世界温度、降雨宣告需要季节时钟开启世界温度显示；
2、MacOS 对应按键 Alt 通常为 Option，除非你改过键；
3、本模组基于 Status Announcements，并结合中文环境进行修复和扩展。

Steam 创意工坊：
]]..STEAM_WORKSHOP_URL,
	zht = "當前版本: "..version.."  更新：添加手柄徑向宣告輪盤。\n\n"..[[
功能：
1、支援宣告角色狀態、背包/容器物品、製作配方、附近實體、延遲、世界溫度和降雨時間；
2、同屏宣告支援生物血量宣告，並支援 ping 宣告；
3、修復和優化多種原版/跨世界/容器/藍圖/草圖宣告問題；
4、手柄支援圍繞角色顯示徑向宣告輪盤。

鍵鼠操作：
• 按住 Alt 點擊 HUD 狀態圖示宣告狀態；
• 按住 Alt+Shift 左鍵/右鍵點擊可見世界實體，宣告單體/同類；
• 按住 Alt+Shift 點擊支援的季節時鐘/計分板元件，宣告世界溫度、降雨或延遲。

手柄操作：
• 長按 Y 打開角色周圍的徑向宣告輪盤；
• 左搖桿選擇目標，Y 宣告單體，X 宣告同類，LB/RB 翻頁，B 退出。

注：
1、世界溫度、降雨宣告需要季節時鐘開啟世界溫度顯示；
2、MacOS 對應按鍵 Alt 通常為 Option，除非你改過鍵；
3、本模組基於 Status Announcements，並結合中文環境進行修復和擴展。

Steam 工作坊：
]]..STEAM_WORKSHOP_URL,
})
--This lets other players know if your mod is out of date. This typically needs to be updated every time there's a new game update.
api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
hamlet_compatible = false
--This lets clients know if they need to get the mod from the Steam Workshop to join the game
all_clients_require_mod = true
client_only_mod = false
server_only_mod = false

--This determines whether it causes a server to be marked as modded (and shows in the mod list)


--This lets people search for servers with this mod by these tags
server_filter_tags = {
	"status announce",
	"status announcements",
	"announce",
	"chinese",
	"controller",
	"快捷宣告",
}

icon_atlas = "statusannouncements.xml"
icon = "statusannouncements.tex"

forumthread = STEAM_WORKSHOP_URL

local options_list = {
	{description = translate({
		en = "Yes",
		zh = "是",
		zht = "是",
		}), data = true,},
	{description = translate({
		en = "No",
		zh = "否",
		zht = "否",
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
			en = "Default Alt+Shift announcements to whisper mode. Hold Ctrl while announcing to switch between whisper and public chat.",
			zh = "习惯性设置，在游戏中宣告可以加 Ctrl 键互相切换私密与公开",
			zht = "習慣性設置，在遊戲中宣告可以加 Ctrl 鍵互相切換私密與公開",
		}),
		options =	{
						{description = translate({
							en = "Yes",
							zh = "是",
							zht = "是",
							}), data = true, hover = translate({
							en = "Alt+Shift announcements are visible only to nearby players.",
							zh = "Alt+Shift 宣告只有附近玩家能看到。",
							zht = "Alt+Shift 宣告只有附近玩家能看到。",
							}),
						},
						{description = translate({
							en = "No",
							zh = "否",
							zht = "否",
							}), data = false, hover = translate({
							en = "Alt+Shift announcements are visible to all players.",
							zh = "Alt+Shift 宣告全部玩家都能看到。",
							zht = "Alt+Shift 宣告全部玩家都能看到。",
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
							zht = "是",
							}), data = true, hover = translate({
								en = "Show exact current and maximum values in stat announcements.",
								zh = "开启是正确的选择。",
								zht = "開啟是正確的選擇。",
								}),},
						{description = translate({
							en = "No",
							zh = "否",
							zht = "否",
							}), data = false, hover = translate({
								en = "Hide exact current and maximum values in stat announcements.",
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
			zh = "宣告状态时，用图标表示对应属性（需要开启“显示当前值/最大值”）。",
			zht = "宣告狀態時，用圖標表示對應屬性（需要開啟「顯示當前值/最大值」）。",
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
			en = "Controller temperature",
			zh = "手柄温度宣告",
			zht = "手柄溫度宣告",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
			en = "Enable character-specific announcement lines when playing this character.",
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
		hover = translate({
			en = "Enable character-specific announcement lines when playing this character.",
			zh = "当你是旺达时，会宣告旺达专有语录。",
			zht = "當你是旺達時，會宣告旺達專有語錄。",
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
		hover = translate({
			en = "Enable character-specific announcement lines when playing this character.",
			zh = "当你是沃尔特时，会宣告沃尔特专有语录。",
			zht = "當你是沃爾特時，會宣告沃爾特專有語錄。",
			}),
		options = options_list,
		default = true,
	},
}
