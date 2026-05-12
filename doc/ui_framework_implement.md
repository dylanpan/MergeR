## 1. 概述与目标

### 1.1 核心功能
- **统一管理**：集中创建、打开、关闭、替换游戏内所有 UI 界面（主菜单、设置、背包、对话、弹窗等）。
- **层级控制**：支持不同层（例如背景层、HUD 层、弹出层、提示层），每层可独立管理 Z 轴顺序和输入阻塞。
- **历史堆栈**：自动维护每个层的 UI 打开历史，支持「返回」功能（如关闭当前面板，恢复上一个）。
- **按需加载**：仅在需要时加载 UI 场景资源，减少启动内存占用；支持预加载常用 UI。
- **动画过渡**：内置进出动画的占位逻辑，开发者可自定义动画。
- **输入阻塞**：模态层自动禁止下层 UI 交互，半透明遮罩可选。

### 1.2 设计原则
- 非侵入式：使用自动加载单例，无需修改现有节点树结构。
- 接口一致：所有 UI 面板继承同一基类，获得通用的生命周期方法。
- 灵活扩展：支持参数传递、关闭回调、差异化过渡动画。

---

## 2. 架构设计

### 2.1 整体类图
```
UIManager (Autoload)
   ├── ── 管理多个 UILayer
   ├── ── 提供全局 API：open_ui, close_ui, close_top, back, preload_ui...
   └── ── 内部使用 Dictionary 存储预加载资源

UILayer (Node2D/Control)
   ├── canvas_layer: CanvasLayer (确保独立渲染)
   ├── stack: Array[UIBase]      // 当前层打开的面板索引
   ├── config: UILayerConfig
   └── ── 方法：add_to_layer(), remove_from_layer(), clear_layer()

UIBase (Control)
   ├── ui_name: String
   ├── layer_name: String (所属层)
   ├── animate_in(), animate_out()  → 可重写
   ├── on_opened(params), on_closed()
   └── ── 信号：closed (携带返回值)

UILayerConfig (Resource)
   ├── layer_name: String
   ├── z_index: int
   ├── block_input: bool            // 是否阻塞下层触摸/鼠标
   ├── enable_stack: bool           // 是否记录历史
   └── show_overlay: bool          // 是否自动显示半透明遮罩
```

### 2.2 节点树示例
```
SceneTree
├── root (默认 Viewport)
└── UIManager (自动加载，无界面节点)
运行时动态生成：
    ├── UILayer_BG          (z=-10, 无遮罩)
    ├── UILayer_HUD         (z=0,  无遮罩)
    ├── UILayer_Popup       (z=50, 有遮罩，阻塞下层)
    ├── UILayer_Tooltip     (z=100, 无遮罩，不阻塞)
    └── UILayer_Loading     (z=200, 有遮罩，阻塞所有)
```

---

## 3. 核心组件实现

### 3.1 UIBase (基类)
所有 UI 面板必须继承自 `UIBase`，其脚本模板如下：
```gdscript
extends Control
class_name UIBase

@export var ui_name: String = "unnamed"
@export var layer_name: String = "popup"
@export var close_on_overlay_click: bool = false  # 点击遮罩关闭（仅模态层有效）

# 生命周期（由 UIManager 调用）
func _ready():
    pass

func on_opened(params = null):
    # 界面打开后调用，可接收参数
    pass

func on_closed():
    # 界面关闭时调用，用于清理
    pass

# 动画模板（可选覆盖）
func animate_in():
    # 默认立即显示，可写 Tween 动画
    visible = true

func animate_out():
    visible = false
    await get_tree().process_frame  # 等待一帧，确保动画完成信号
    queue_free()

# 关闭自身（通常由 UI 内部按钮调用）
func close(return_data = null):
    UIManager.close_ui(ui_name, return_data)
```

### 3.2 UILayerConfig (资源文件)
新建 `Resource` 脚本：
```gdscript
extends Resource
class_name UILayerConfig

@export var layer_name: String = "popup"
@export var z_index: int = 0
@export var block_input: bool = true   # 是否阻塞下层输入
@export var enable_stack: bool = true
@export var overlay_color: Color = Color(0, 0, 0, 0.5)
@export var show_overlay: bool = false
```

### 3.3 UILayer (节点)
```gdscript
extends Node2D
class_name UILayer

var config: UILayerConfig
var stack: Array[UIBase] = []
var overlay: ColorRect = null


func setup(cfg: UILayerConfig):
    config = cfg
    # 创建 CanvasLayer 实现独立层
    var canvas = CanvasLayer.new()
    canvas.layer = cfg.z_index
    add_child(canvas)
    
    # 如果该层需要 blocking，设置 input 处理
    if cfg.block_input:
        canvas.process_mode = CanvasItem.PROCESS_MODE_WHEN_PAUSED
        # 可通过设置 CanvasLayer 的 blocking 属性？实际上需要挂载一个全屏触摸拦截节点
        _create_blocker(canvas)
    
    if cfg.show_overlay:
        _create_overlay(canvas)


func add_to_layer(ui: UIBase):
    ui.get_parent()?.remove_child(ui)   # 确保没有父节点
    var canvas = get_child(0)           # CanvasLayer
    canvas.add_child(ui)
    stack.append(ui)
    # 调整 Z 顺序：最新加入的排在顶层
    for i in range(stack.size()):
        stack[i].z_index = i
    if config.enable_stack:
        pass  # 历史已由 stack 维护


func remove_from_layer(ui: UIBase, skip_free: bool = false):
    var idx = stack.find(ui)
    if idx != -1:
        stack.remove_at(idx)
        ui.get_parent()?.remove_child(ui)
        if not skip_free:
            ui.queue_free()
        # 重新调整剩余 UI 的 Z 顺序
        for i in range(stack.size()):
            stack[i].z_index = i


func clear_layer():
    while stack.size():
        var ui = stack.pop_back()
        ui.queue_free()


func _create_blocker(parent: CanvasLayer):
    # 全屏透明区阻断输入
    var blocker = ColorRect.new()
    blocker.color = Color.TRANSPARENT
    blocker.mouse_filter = Control.MOUSE_FILTER_STOP
    blocker.size = DisplayServer.window_get_size()
    parent.add_child(blocker)
    blocker.move_to_front()   # 确保在最前
    
    # 可选：点击遮罩关闭顶层 UI（需要信号传递到 UIManager）
    blocker.gui_input.connect(func(event):
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            if stack.size() > 0 and stack[-1].close_on_overlay_click:
                UIManager.close_ui(stack[-1].ui_name)
    )


func _create_overlay(parent: CanvasLayer):
    overlay = ColorRect.new()
    overlay.color = config.overlay_color
    overlay.size = DisplayServer.window_get_size()
    parent.add_child(overlay)
    overlay.move_to_back()
```

### 3.4 UIManager (自动加载单例)
```gdscript
extends Node
# UIManager.gd

var layers: Dictionary = {}          # { "layer_name": UILayer }
var loaded_scenes: Dictionary = {}   # { "ui_name": PackedScene }
var preloaded_resources: Array = []  # 需要预加载的 UI 名称列表
var default_layer_config = {
    "bg":    {z= -10, block=false, stack=true, overlay=false},
    "hud":   {z= 0,   block=false, stack=false, overlay=false},
    "popup": {z= 50,  block=true,  stack=true,  overlay=true, color="00000080"},
    "tooltip": {z=100, block=false, stack=false, overlay=false},
    "loading": {z=200, block=true, stack=false, overlay=true, color="000000aa"}
}


func _ready():
    _create_default_layers()
    # 预加载（如有配置）
    for ui_name in preloaded_resources:
        preload_ui(ui_name)


func _create_default_layers():
    for name, cfg_dict in default_layer_config:
        var cfg = UILayerConfig.new()
        cfg.layer_name = name
        cfg.z_index = cfg_dict.get("z", 0)
        cfg.block_input = cfg_dict.get("block", false)
        cfg.enable_stack = cfg_dict.get("stack", true)
        cfg.show_overlay = cfg_dict.get("overlay", false)
        cfg.overlay_color = Color(cfg_dict.get("color", "00000080"))
        _create_layer(cfg)


func _create_layer(cfg: UILayerConfig):
    var layer = UILayer.new()
    layer.setup(cfg)
    add_child(layer)
    layers[cfg.layer_name] = layer


func preload_ui(ui_path_or_name: String) -> PackedScene:
    # 如果传入的是 UI 名称（需要在某个字典中映射到实际路径）
    var path = _resolve_ui_path(ui_path_or_name)
    if not loaded_scenes.has(ui_path_or_name):
        var scene = load(path)
        loaded_scenes[ui_path_or_name] = scene
    return loaded_scenes[ui_path_or_name]


func _resolve_ui_path(ui_name: String) -> String:
    # 简单映射，可扩展为配置文件
    var mapping = {
        "main_menu": "res://ui/main_menu.tscn",
        "settings": "res://ui/settings.tscn",
        "inventory": "res://ui/inventory.tscn",
    }
    return mapping.get(ui_name, "res://ui/" + ui_name + ".tscn")


func open_ui(ui_name: String, params = null, layer_override: String = "") -> UIBase:
    # 如果已经打开且不允许重复，可判断（可选）
    var packed = preload_ui(ui_name)
    var ui_instance: UIBase = packed.instantiate()
    # 确定所属层
    var target_layer_name = layer_override if layer_override != "" else ui_instance.layer_name
    var layer = layers.get(target_layer_name)
    if not layer:
        printerr("未找到UI层: ", target_layer_name)
        return null
    layer.add_to_layer(ui_instance)
    ui_instance.on_opened(params)
    ui_instance.animate_in()
    return ui_instance


func close_ui(ui_name: String, return_data = null):
    # 遍历所有层查找该 UI（也可根据唯一标识查找）
    for layer in layers.values():
        for ui in layer.stack:
            if ui.ui_name == ui_name:
                ui.on_closed()
                ui.animate_out()
                await ui.tree_exited  # 等待动画结束
                layer.remove_from_layer(ui, true)  # 已经 queue_free 过了
                # 向调用者发出信号（可选）
                return return_data
    printerr("未找到打开的UI: ", ui_name)


func close_top(layer_name: String):
    var layer = layers.get(layer_name)
    if layer and layer.stack.size() > 0:
        var top = layer.stack[-1]
        close_ui(top.ui_name)


func back(layer_name: String = "popup"):
    # 回退上一层：关闭当前 UI，自动恢复到前一个 UI（若有 stack）
    var layer = layers.get(layer_name)
    if layer and layer.stack.size() > 1:
        close_ui(layer.stack[-1].ui_name)
    else:
        close_top(layer_name)  # 只剩下一个时直接关闭


func is_ui_open(ui_name: String) -> bool:
    for layer in layers.values():
        if layer.stack.any(func(ui): return ui.ui_name == ui_name):
            return true
    return false


func close_all():
    for layer in layers.values():
        layer.clear_layer()
```

---

## 4. 实现步骤（供 Agent 逐步实施）

1. **创建基础脚本**  
   - `UIBase.gd` （class_name UIBase）  
   - `UILayerConfig.gd` （class_name UILayerConfig）  
   - `UILayer.gd` （class_name UILayer）  

2. **实现 UIManager 单例**  
   - 创建 `UIManager.gd`，添加上述全部方法。  
   - 在项目设置 → Autoload 中添加 `UIManager`。  

3. **构建默认层级**  
   - 在 UIManager 的 `_ready()` 中调用 `_create_default_layers()`，配置 HUD、弹窗等多个层。  

4. **制作 UI 模板**  
   - 创建一个示例 UI（如 `PopupPanel.tscn`）：根节点为 `UIBase`，设计按钮“关闭”（调用 `close()`）。  
   - 确保 `ui_name` 和 `layer_name` 导出属性已正确填写。  

5. **添加资源映射**  
   - 完善 `_resolve_ui_path()`，支持从 JSON 或 Exported 变量加载配置。  

6. **测试基础功能**  
   - 在任意场景调用：`UIManager.open_ui("main_menu")` 与 `UIManager.close_ui("main_menu")`。  

7. **增强动画**  
   - 在 UIBase 的 `animate_in()` 中编写 Tween 动画（弹入、淡入等）。  
   - `animate_out()` 中做反向动画，完成后 emit `tree_exited` 或使用信号通知完成。  

8. **添加遮罩点击关闭**  
   - 在 UILayer 的遮罩色块上连接 `gui_input`，判断点击时关闭顶层 UI（并检查 `close_on_overlay_click`）。  

9. **添加参数与回调**  
   - 扩展 `open_ui` 支持 `callback` 参数，用于接收 `closed` 信号。  

10. **性能优化**  
    - 对于常用 UI（如 HUD、小地图），可使用 `preload_ui` 提前加载并在 UIManager 中缓存，打开时直接 `instantiate`。  

---

## 5. 使用示例

### 5.1 打开背包并传递玩家数据
```gdscript
UIManager.open_ui("inventory", { "player": player_node })
```

### 5.2 监听关闭返回值
```gdscript
var my_ui = UIManager.open_ui("dialog")
my_ui.closed.connect(func(data):
    print("对话框关闭，选择结果：", data)
)
```

### 5.3 实现返回键（ESC）
```gdscript
func _input(event):
    if event.is_action_pressed("ui_cancel"):
        UIManager.back("popup")   # 优先关闭弹窗层
```

### 5.4 自定义 UI 基类扩展
```gdscript
extends UIBase

func on_opened(params):
    $Label.text = params["text"]
    $AnimationPlayer.play("fade_in")

func _on_confirm_button_pressed():
    close({"confirmed": true})

func _on_cancel_button_pressed():
    close({"confirmed": false})
```

---

## 6. 注意事项与扩展点

- **触摸/鼠标穿透**：确保阻挡层设置了 `mouse_filter = STOP`，CanvasLayer 的 `process_mode` 正确。  
- **窗口大小适配**：`DisplayServer.window_get_size()` 随窗口变化需要更新 blocker / overlay 的尺寸；可连接 `tree_exiting` 或每帧检查，或在根 Viewport 大小变化时重新计算。  
- **多分辨率**：建议将 UILayer 内的 CanvasLayer 的 `scale` 设置为适应不同分辨率，或使用 `Control` 的 `anchors` 全屏。  
- **预加载性能**：preload_ui 只在首次调用时加载，后续直接返回 PackedScene，节约 I/O。  
- **调试**：为 UILayer 添加 `debug_draw` 模式，显示当前层栈结构。  
- **扩展方向**：  
  - 增加 UI 优先级系统（不同 UI 可打断低优先级 UI）。  
  - 支持 UI 资源热重载（开发模式）。  
  - 集成 UI 布局对齐工具（如对齐到屏幕边缘）。
