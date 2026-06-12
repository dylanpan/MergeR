extends Node

# ============================================================
# 全局信号总线（替代 Cocos EventManager）
# 所有系统间的通信通过信号而不是直接调用
#
# 【架构重构说明】
# 旧版：22 个细粒度信号，每个仅差参数不同
# 新版：合并为类别级信号 + payload Dictionary，减少信号数量
# 旧信号保留为别名以保证向后兼容，但新代码应使用新信号
# ============================================================

# ==================== 新：通用事件信号（推荐使用） ====================

signal event_battle_update(data: Dictionary)    # 战斗更新：{ type: "damage"|"reload"|"atk"|"hit"|"shield"|"step", ... }
signal event_round_update(data: Dictionary)     # 回合更新：{ type: "start"|"end"|"new_level"|"step_limit", ... }
signal event_game_state(data: Dictionary)       # 游戏状态：{ type: "over"|"win"|"restart", ... }
signal event_ui_update(data: Dictionary)        # UI 更新：{ type: "refresh"|"order"|"attack_state", ... }

