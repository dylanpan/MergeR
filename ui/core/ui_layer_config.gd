extends Resource
class_name UILayerConfig

# ============================================================
# UI 层级配置资源
# 定义每个层级的行为属性
# ============================================================

@export var layer_name: String = "popup"
@export var z_index: int = 0
@export var block_input: bool = true   # 是否阻塞下层输入
@export var enable_stack: bool = true
@export var overlay_color: Color = Color(0, 0, 0, 0.5)
@export var show_overlay: bool = false