extends Node

# ============================================================
# 游戏常量定义（替代 GameConsts.js）
# ============================================================

# 阶段常量
const StageNone: int = 0
const StageInit: int = 1
const StagePreBattle: int = 2
const StageSelfBattle: int = 3
const StageEnermyBattle: int = 4
const StageEndSelfBattle: int = 5
const StageEndEnermyBattle: int = 6
const StageShop: int = 7

# 回合状态
const RoundState_Normal: int = 1
const RoundState_GameStart: int = 2
const RoundState_GameOver: int = 3
const RoundState_RoundOver: int = 4
const RoundState_MaxStep: int = 5
const RoundState_LevelOver: int = 6

# 订单类型
const OrderType_Self: int = 1
const OrderType_Enermy: int = 2

# 区域ID
const AreaId_Element: int = 0
const AreaId_Launcher: int = 1
const AreaId_Bullet: int = 2
const AreaId_Shot: int = 3

# 地图层节点类型
const MapNodeType: Dictionary = {
	"BATTLE": "battle",
	"SHOP": "shop",
	"REST": "rest",
	"BOSS": "boss",
	"ELITE": "elite",
	"EVENT": "event",
	"TREASURE": "treasure",
}

# 实体类型名称常量
const EntityTypeName: Dictionary = {
	"ORDER_ENEMY": "OrderEnermy",
	"ORDER_SELF": "OrderSelf",
	"ELEMENT": "Element",
	"LAUNCHER": "Launcher",
	"BULLET": "Bullet",
	"SHOP": "Shop",
	"EVENT": "Event",
}

# Boss回合ID常量（程序化地图生成使用）
const BossRoundId: Dictionary = {
	"BOSS_1": 50010,
	"BOSS_2": 50014,
	"FINAL_BOSS": 50015,
}