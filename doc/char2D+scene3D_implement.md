
## 执行方案：类《Replaced》风格游戏（Godot 4.x）

### 0. 项目准备
- **创建项目**：Godot 4.x → 新建项目 `Replaced_Style_Demo`  
- **导入资源**（占位阶段可用程序生成）：
  - 2D 角色：单张 PNG 精灵表（待机/奔跑/攻击，建议 128x128 逐帧或 Spine 动画）
  - 3D 场景：简单几何体（方块、圆柱体）搭配低多边形和像素风纹理
  - 音效/音乐（后期可加）

---

## 阶段一：搭建最小原型（2D 角色行走于 3D 横版平面）

### 目标
实现 `CharacterBody3D` + `Sprite3D` 的基础控制，摄像机固定侧面跟随。

### 步骤

1. **创建角色场景** `player.tscn`
   - 根节点：`CharacterBody3D`
   - 子节点：
     - `Sprite3D`（命名为 `Sprite2D`）  
       - `Texture` = 你的角色图片  
       - `Billboard` = `Enabled`（始终面向相机）  
       - `Centered` = `true`
     - `CollisionShape3D`：`BoxShape3D` 或 `CapsuleShape3D`，大小匹配角色脚底位置
   - 脚本 `player.gd`（基础移动）：

```gdscript
extends CharacterBody3D

@export var speed := 5.0

func _physics_process(delta):
    var input_dir = Input.get_vector("left", "right", "up", "down")
    var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    move_and_slide()
```

2. **创建主场景** `main.tscn`
   - 根节点 `Node3D`
   - 添加 `WorldEnvironment`（设置暗色背景 + 简单的天空）
   - 添加 `DirectionalLight3D`（主光源）
   - 添加 `Camera3D` 并设为 **侧视跟随**：
     - 位置 `(0, 3, -8)`
     - 将以下脚本挂到相机上实现简单跟随：

```gdscript
extends Camera3D

@export var target: Node3D
@export var offset := Vector3(0, 2, -6)

func _process(delta):
    if target:
        global_position = target.global_position + offset
```

3. **添加测试地面**
   - 创建一个 `StaticBody3D` + `BoxMesh`（长 20，高 0.2，宽 10）作为地面
   - 放置几个简单的立方体作为障碍物

4. **运行测试**  
   - 角色可以用 WASD 在地面上移动，相机始终跟随

---

## 阶段二：实现“电影感”摄像机状态机（借鉴《Replaced》）

### 目标
摄像机根据游戏状态切换：**探索（远景）**、**战斗（近景 + 震动）**、**剧情（固定路径动画）**。

### 步骤

1. **定义摄像机状态枚举**
```gdscript
enum CamState { EXPLORE, COMBAT, CUTSCENE }
var current_state = CamState.EXPLORE
```

2. **实现状态切换逻辑**
   - 由 GameManager 或角色脚本发射信号（如进入战斗区域 → `combat_started`）
   - 在相机脚本中连接信号并更改状态和相关参数（FOV, 距离, 是否震动）

3. **探索状态（默认）**
   - offset = `Vector3(0, 2.5, -8)`，拉远视野

4. **战斗状态**
   - offset = `Vector3(0, 1.5, -4)`，拉近相机
   - 轻微屏幕震动：在 `_process` 中随机偏移相机位置（可用 `Tween` 或每帧叠加噪声）

5. **剧情状态**
   - 禁用跟随逻辑，使用 `Path3D` + `PathFollow3D` 让相机沿预设曲线移动
   - 完成后返回探索状态

### 交付物
- 相机脚本完整类，含状态切换函数
- 一个测试区域（进入后触发战斗状态，按 `T` 键模拟剧情相机）

---

## 阶段三：3D 背景的“像素风材质”与动态光照

### 目标
让纯 3D 几何体呈现类似像素画的风格，并与 2D 角色共存时视觉统一。

### 步骤

1. **创建像素风着色器材质**
   - 新建 `ShaderMaterial` → 创建 `StandardMaterial3D`  
   - 在 `Albedo` 纹理中使用低分辨率贴图（例如 64x64）并关闭 `filter`
   - 或在 `Shader` 中直接对采样颜色做“色阶量化”

2. **配置光源**（营造赛博朋克氛围）
   - 主光：`DirectionalLight3D` 强度 0.8，颜色偏冷青
   - 补充光：`OmniLight3D` 放在角色附近，颜色暖橙，营造霓虹对比
   - 添加 `WorldEnvironment` → `Glow` 开启（辉光效果）

3. **为角色增加受光响应**（提升质感）
   - 在 `Sprite3D` 的材质中开启 `Shaded`，并为其添加一个简单的 `StandardMaterial3D`，使角色能接受 3D 光源的明暗变化（虽然还是扁平，但会有亮度差异）

### 验证
- 场景中移动角色，观察阴影和辉光效果是否实时作用在 Sprite3D 上

---

## 阶段四：2D 动画系统（流畅转描风格）

### 目标
实现高质量的角色动画，可选择 **逐帧手绘** 或 **Spine 骨骼动画**。

### 方案 A：逐帧动画（性能较佳）
1. 将动画序列导入为 `SpriteFrames` 资源
2. 在角色场景中添加 `AnimatedSprite3D` 节点（可替代 `Sprite3D`）
3. 用 `AnimationPlayer` 控制动画切换（待机→跑→攻击）

### 方案 B：Spine 动画（更接近《Replaced》流畅感）
1. 安装 Spine Godot 运行时（官方插件）
2. 将 Spine 导出文件（`.json` + 图集）导入
3. 使用 `SpineSprite` 节点代替 `Sprite3D`  
4. 通过代码调用 `set_animation("run", true)`

### 关键点
- 动画切换须与移动状态同步（例如 `velocity.length() > 0.1` 时播放跑动动画）

---

## 阶段五：后期处理与电影化特效

### 步骤
1. **景深效果**  
   - 在 `WorldEnvironment` → `Depth of Field` 中启用，根据相机距离调节远近模糊

2. **体积雾**  
   - 添加 `FogVolume` 节点，设置低密度雾，配合彩色光源产生光柱效果

3. **动态天气系统（可选）**  
   - 使用 `ParticleProcessMaterial` 制作雨/雪粒子系统
   - 随时间随机切换粒子发射并改变全局光照颜色

---

## 阶段六：性能与兼容性检查

- **Sprite3D 数量**：不超过 30 个（否则实例化开销大）
- **像素纹理**：所有纹理导入时关闭 `Filter`，开启 `Repeat` 或 `Mipmaps` 酌情
- **光照烘焙**：静态背景使用 `BakedLightmap` 或 `LightmapGI`
- **摄像机射线**：避免每帧大量 `RayCast3D`

---

## 交付清单（Agent 必须产出的文件结构）

```
Replaced_Style_Demo/
├─ scenes/
│  ├─ main.tscn
│  ├─ player.tscn
├─ scripts/
│  ├─ player.gd
│  ├─ camera_follow.gd
│  ├─ camera_state_machine.gd
├─ materials/
│  ├─ pixel_block.tres
│  ├─ char_shaded.tres
├─ shaders/
│  ├─ pixel_dither.gdshader
├─ assets/
│  ├─ sprites/
│  ├─ animations/
│  ├─ models/
├─ sounds/
├─ default_env.tres
└─ project.godot
```

---

## 扩展建议（后续迭代）

- **可破坏环境**：利用 `StaticBody3D` 替换为 `RigidBody3D` 并触发爆炸粒子
- **2D 与 3D UI 混合**：将血条/对话气泡用 `Control` 节点放在屏幕上层，不受 3D 摄像机影响
- **镜头摇晃插件**：编写 `CameraShake.gd` 供战斗状态调用

---

此方案可直接交给任何熟悉 Godot 的 agent 按顺序实施，每个阶段都可独立验证。如果需要更细粒度的脚本代码或着色器代码片段，可以进一步提供。