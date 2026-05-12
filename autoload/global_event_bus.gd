extends Node

# ============================================================
# 全局信号总线（替代 Cocos EventManager）
# 所有系统间的通信通过信号而不是直接调用
# ============================================================

# 战斗信号
signal event_ui_update_damage(entity, damage, is_weakness, is_resistance)
signal event_ui_update_self_atk
signal event_ui_update_enermy_atk
signal event_ui_update_self_hit
signal event_ui_update_enermy_hit
signal event_ui_update_step(progress)
signal event_ui_update_enermy_reload
signal event_ui_update_refresh_warning(data)
signal event_ui_update_shield_absorb(entity_id)
signal event_on_entity_destroyed(entity)
signal event_on_boss_phase_change(entity, phase)
signal event_on_enemy_spawn(entity)

# 回合信号
signal event_round_new_level_start
signal event_round_end
signal event_round_start(round_idx)

# 游戏状态信号
signal event_update_game_over
signal event_update_game_win
signal event_game_restart

# 商店信号
signal event_shop_open(shop_id, shop_data)
signal event_shop_buy(item_id, index)
signal event_shop_close
signal event_shop_refresh(items, remaining_count)

# 事件信号
signal event_event_open(event_id, event_data)
signal event_event_close
signal event_event_option_select(option_id)

# 休息点信号
signal event_rest_open(rest_id, rest_data)
signal event_rest_close
signal event_rest_confirm
signal event_rest_skip

# UI 系统信号
signal event_update_by_step
signal event_ui_update_order_self
signal event_ui_update_attack_state(is_attacking)