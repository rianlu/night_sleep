# SleepFlow App 重构步骤文档（基于新设计稿）

## 1. 重构目标
- 以你提供的设计稿为唯一 UI 标准，重建主流程和视觉风格。
- 删除与新产品方向无关页面与交互，降低维护成本。
- 主题系统先完成“可扩展架构”，为后续“用户自定义主题色”预留能力。
- 保留核心能力：本地库、播放、链接解析导入、播放区间裁剪。

## 2. 信息架构（新）
- `首页`：今晚播放 + 播放控制 + 待播放队列。
- `本地库`：搜索、列表、快速加入队列、入口到“添加音频”。
- `我的`：先保留轻量占位（后续再扩展）。
- `添加音频`：独立页面（从本地库 `+` 进入），承载链接解析 + 区间裁剪 + 保存。

## 3. 范围裁剪（删除/保留）

### 3.1 直接删除
- `lib/features/ambience/**`（氛围空间整套）
- `lib/features/stats/**`（睡眠报告）
- 与上述页面强绑定的入口、Provider、样式和常量

### 3.2 改造后保留
- `lib/features/player/**`：保留播放能力，UI 全量改造到设计稿风格
- `lib/features/import/**`：保留解析链路，页面重构为“添加音频”新稿
- `lib/features/home/**`：重写为“首页 + 本地库 + 我的”导航壳和页面实现
- `lib/data/**`：保留数据模型与 DB 能力，按新页面补字段/查询

## 4. 主题系统重构（重点：支持未来自定义主题色）

### 4.1 目标
- 由“写死色值”升级为“语义 Token + 主题生成器”。
- 默认实现设计稿米白+暖橙风格。
- 后续只需替换用户主色，即可联动所有控件状态色。

### 4.2 实施
- 新增 `ThemeSeed`（用户主色、模式、对比度偏好）。
- 新增语义色层：
  - `bgBase/bgElevated/bgCard`
  - `textPrimary/textSecondary/textTertiary`
  - `accent/ accentOn / accentSoft`
  - `border/subtleBorder/success/warn/error`
- 新增 `ThemeController`（后续可接本地持久化）。
- 页面中禁止直接写 `Color(0x...)`，统一走语义 token。

### 4.3 先做但不开放 UI 的能力
- 预留 `setPrimaryColor(Color)` 接口。
- 预留主题配置持久化仓库接口（可先用 stub）。

### 4.4 “奶油晚霞”主题 Token（当前默认主题，强约束）
- Core Palette
  - `bgBase = #FFFBF2`（全站底色）
  - `accent = #F59E0B`（主强调：播放、激活、保存）
  - `bgCard = #FFFFFF`（卡片/输入框）
  - `bgSoft = #FFEDD5`（胶囊、未选中态、软轨道）
  - `textPrimary = #4B5563`（主文本）
  - `textSecondary = #9CA3AF`（次文本）
- Component Tokens
  - `radiusCard = 24~32`
  - `radiusControl = 16`
  - `radiusPill = 999`（full-round）
  - `shadowAmber = rgba(245, 158, 11, 0.08)`
  - `spacingBase = 8`（8px 网格）
  - `pagePadding = 20~24`
- Key Elements
  - 播放器胶囊：`bg=#FFEDD5`，`fg=#B45309`
  - 进度条：`active=#F59E0B`，`inactive=#FEF3C7`
  - 底部导航：`bg=#FFFBF2`，`active=#F59E0B`，`inactive=#D1D5DB`
- Interaction
  - 点击 Ripple：`accent`，alpha `0.1`
  - 页面切换：`淡入淡出 + 轻微位移`，避免大幅平移
- 开发硬约束
  - 新 UI 禁止直接写色值；必须引用语义 token。
  - 除非你确认改设计，不允许替换当前默认主题基色。

## 5. 分阶段开发步骤

### Phase 0：基线整理
- 建立 `refactor/v2-design` 分支。
- 记录当前可运行状态（`flutter analyze` / `flutter test`）。
- 输出“旧页面->新页面”映射表，防止遗漏路由。

### Phase 1：导航壳重建
- 重写 `MainNavigationScreen`：
  - Tab 固定：`首页 / 本地库 / 我的`
  - 底部栏改为设计稿样式（浅底、选中高亮、图标和文字同步状态）
- 暂时保留空内容页，先跑通结构。

### Phase 2：主题 Token 落地
- 拆分 `promax_colors.dart` 和 `app_theme.dart` 的硬编码依赖。
- 引入语义化主题对象（浅色默认主题）。
- 修正全局控件主题：按钮、输入框、卡片、分割线、Slider、BottomNav。

### Phase 3：首页重构（今晚播放）
- 搭建顶部标题区（“今晚播放/SLEEPFLOW”）。
- 搭建主播放卡：
  - 封面、标题、副标题、时段信息
  - 进度条、播放控制（上一首/播放暂停/下一首）
  - 速率入口与剩余时间入口
  - 可展开区域（播放倍率 + 睡眠定时）
- 搭建待播放列表：
  - 当前播放高亮
  - 条目拖拽柄、标题、副标题、时段
  - “清空队列”“队列设置”

### Phase 4：本地库重构
- 新建本地库页面结构：
  - 标题 + 副标题
  - 搜索框
  - 右上角 `+` 悬浮按钮
  - 音频条目卡片（封面、标题、UP、分段、最近播放）
  - 条目右侧“加入队列”按钮
- 点击 `+` 进入“添加音频”页。

### Phase 5：添加音频页重构
- 将 `ImportScreen + AudioParserScreen` 统一为新设计流程：
  - 粘贴链接 -> 开始解析
  - 解析结果卡片展示
  - 播放区间（开始/结束 + 双滑块）
  - 错误提示、成功提示、保存按钮
- 保留现有 B 站解析服务，不改核心协议逻辑。

### Phase 6：清理与回归
- 删除无用文件、路由、Provider、常量、依赖。
- 补齐页面间导航与返回行为。
- 统一间距/字号/圆角规范，做视觉走查。

## 6. 建议目录目标（重构后）
- `lib/features/home/presentation/home_play_screen.dart`
- `lib/features/library/presentation/library_screen.dart`
- `lib/features/library/presentation/add_audio_screen.dart`
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/core/theme/theme_tokens.dart`
- `lib/core/theme/theme_seed.dart`
- `lib/core/theme/theme_controller.dart`

## 7. 验收标准（每阶段）
- 视觉：与设计稿结构和层级一致，色彩和状态明显可区分。
- 功能：播放、队列、搜索、解析、保存链路可用。
- 架构：页面不再直接依赖硬编码色值；主题切换接口可调用。
- 清理：无废弃页面入口、无悬空引用、无无用依赖。
- 质量：`flutter analyze` 无新增错误；关键流程至少 1 条冒烟测试通过。

## 8. 风险与应对
- 风险：旧页面耦合较高（导航、播放器浮层、导入链路交叉）。
- 应对：先重建导航壳与主题，再逐页替换；每 Phase 结束可运行。
- 风险：设计稿含状态较多（展开/收起/错误/成功）。
- 应对：先实现主状态，再补全边界状态和动效，不一次性堆叠复杂度。

## 9. 执行顺序建议
1. Phase 1 + Phase 2 先落地（骨架与主题）。
2. Phase 3 首页完成并接入真实播放状态。
3. Phase 4 本地库完成并接入数据。
4. Phase 5 添加音频完成并打通保存。
5. Phase 6 清理收尾并回归测试。
