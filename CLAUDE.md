## Agent skills

### Issue tracker

Issues are tracked on GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage labels with default names matching the role names. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. See `docs/agents/domain.md`.

---

## Git Guardrails

Git 操作的防护规则，分为 **硬性阻断**（需人类授权）和 **建议警告**（允许绕过）两个级别。

### G1 — 提交前空白检查（建议警告）

`commit` 前自动执行 `git diff --check`，检测以下问题：
- Trailing whitespace
- 混用空格与 Tab 缩进

如检测到问题，**发出警告并建议修复**，但允许 `--no-verify` 绕过。

### G2 — 分支保护（硬性阻断）

- 禁止直接向 `main` 分支提交或推送代码
- 应使用 feature branch 工作流：`feature/xxx` → PR → `main`
- 如需直接操作 `main`，必须获得人类明确授权

### G3 — 提交信息格式（建议警告）

提交信息必须遵循约定式提交（Conventional Commits）格式：

```
type(scope): description
```

允许的 type：`feat`, `fix`, `docs`, `refactor`, `test`, `chore`

示例：
- `feat(battle): 添加暴击机制`
- `fix(map): 修复房间生成坐标越界`
- `docs(readme): 更新安装说明`

不合规格式**发出警告**，允许 `--no-verify` 绕过。

### G4 — 敏感文件保护区（硬性阻断）

以下文件的修改必须获得人类明确授权，不得擅自改动：

| 文件 | 原因 |
|------|------|
| `project.godot` | 项目配置，影响构建和运行 |
| `autoload/*.gd` | 全局单例，影响整个生命周期 |
| `main.tscn` | 主场景入口 |
| `main.gd` | 主场景脚本 |

### G5 — 敏感信息检查（硬性阻断）

禁止提交包含以下内容的代码：
- API keys / tokens
- 数据库密码或连接字符串
- 私钥证书（`.pem`, `.key`）
- 任何硬编码的认证凭据

如检测到疑似敏感信息，**立即终止操作**并报告人类处理。

### G6 — 大文件警告（建议警告）

超过 **500KB** 的二进制文件应：
1. 检查是否应使用 Git LFS 跟踪
2. 在提交信息中说明大文件引入原因

### G7 — Push 前同步检查（建议警告）

执行 `git push` 前：
1. 检查本地分支是否落后于远程
2. 如落后，提示执行 `git pull --rebase`
3. 禁止 force push，除非获得人类明确授权

### G8 — 测试通过要求（建议警告）

当修改涉及以下核心逻辑时，提交前应运行相关测试：
- `core/system/` — 系统逻辑
- `core/entity/` — 实体
- `core/buffs/` — Buff 系统
- `core/skills/` — 技能系统

运行命令参考：测试文件位于 `tests/` 目录，在 Godot 编辑器中加载对应测试场景执行。
