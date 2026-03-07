# CBTI Sleep App UI 设计输入 

## 1. 产品 Idea（一句话）

这是一款 **基于 CBTI（失眠认知行为疗法）** 的睡眠训练 app：  
它不追求“监测得多精细”，而是通过 **固定起床时间 + 可调整睡眠窗口 + 真实睡眠日志反馈**，帮助用户逐步重建稳定睡眠节律。

---

## 2. 要解决的核心问题

- 用户常见困境：越想“睡够”，越在床上清醒，焦虑持续放大。
- 普通睡眠 app 常把“计划”和“现实”混在一起，让用户产生失败感。
- 本产品将二者明确分离：  
  - `Sleep Window` = 行为训练计划（目标）  
  - `Sleep Diary` = 真实发生日志（事实）
- 算法只基于“事实”调节下一步计划，避免自欺或过度惩罚。

---

## 3. 核心算法（可视化与文案都要围绕它）

### 3.1 核心指标

- `TIB`（Time in Bed，在床时长）= `wake_time - bedtime`
- `TST`（Total Sleep Time，实际睡眠时长）= `wake_time - sleep_start`
- `Sleep Efficiency`（睡眠效率）= `TST / TIB`，区间限制在 `0~1`

> UI 建议：关键页面统一展示 `Efficiency %`，并给出语义状态（低/稳定/优秀）。

### 3.2 近 14 天效率（趋势层）

- 使用最近 14 条日志计算整体效率与趋势图。
- 用于 Progress 页展示：
  - 折线图：`Sleep Efficiency — 14 Days`
  - 汇总卡片：平均效率、平均睡眠时长、平均夜醒次数

### 3.3 每周窗口调整（干预层，CBTI 核心）

前提：最近 7 天有至少 5 天有效日志。  
依据最近一周效率做窗口调整：

- `efficiency > 90%` -> 窗口 `+15 min`
- `85% <= efficiency <= 90%` -> 窗口 `0 min`（保持）
- `efficiency < 85%` -> 窗口 `-15 min`

并做边界约束（当前实现）：

- 最短窗口：`5h`
- 最长窗口：`9h`

### 3.4 初始建议窗口（冷启动）

- 依据历史平均睡眠时长估算窗口；无数据时默认 `7.5h`。
- 限制在 `4h~12h` 后，倒推 bedtime：
  - `bedtime = targetWakeTime - windowDuration`

### 3.5 偏移提醒（行为校正）

若用户与计划偏差 >= 30 分钟，生成引导文案：

- 晚于计划上床 30 分钟以上 -> 强调固定起床时间
- 早于计划上床 30 分钟以上 -> 强调保持窗口稳定
- 起床时间偏差 30 分钟以上 -> 强调先锚定早晨

---

## 4. 交互理念（UI/UX 设计原则）

### 4.1 事实优先，不做道德评判

- 所有记录入口文案强调：**“记录真实发生”**，不是“打卡完成任务”。
- 即使用户严重偏离计划，界面仍提供修正与继续路径，不出现“失败”语义。

### 4.2 低摩擦记录，允许事后补录

- 晚上 1 次点击记录 `I'm Going To Bed`
- 早晨通过 `Morning Check-in` 完整补齐 bedtime / wake / latency / quality / awakenings
- `Edit Last Night` 快速修正昨天数据

### 4.3 干预在当下，计算在背后

- 夜间 “I Can’t Sleep” 不是复杂表单，而是即时指导（Stimulus Control 三步）
- 算法计算与每周调整尽量后台化，前台仅呈现简洁建议

### 4.4 计划与现实并列展示

- 同屏出现 `Tonight’s Plan` 与 `Last Night Actual`
- 目的：减少羞耻感，强化“训练中”心智模型

---

## 5. 信息架构（建议给 Figma Make 的页面结构）

当前主架构为 3 Tab：

1. `Home`
   - Tonight's Plan（计划窗口 + 当前效率）
   - Last Night（真实日志摘要）
   - Guidance / Coach（算法建议与偏移提醒）
   - Action Row（Record Last Night / I'm Going To Bed）
   - Morning Check-in Banner（早晨时段优先提示）
2. `History`
   - Progress Summary（14 天趋势 + 统计卡）
   - Sleep Logs 列表（可编辑）
3. `Settings`
   - 通知开关（Bedtime Reminder / Morning Check-in）
   - Target Wake Time（单时间滑条）
   - Data Export（占位能力）

---

## 6. 关键用户流程（端到端）

### 流程 A：首次使用（冷启动）

1. 用户设置目标起床时间（Target Wake Time）
2. 系统生成初始睡眠窗口（默认约 6h~7.5h 逻辑）
3. Home 展示 Tonight’s Plan，提示“按计划训练，不必完美”

### 流程 B：晚间入睡

1. 用户点击 `I'm Going To Bed`
2. 进入 Bedtime Flow（Routine -> Sleep Mode）
3. 记录 bedtime 时间戳（支持次日补录其余字段）

### 流程 C：夜间睡不着

1. 在 Sleep Mode 点击 `I Can’t Sleep`
2. 进入 `Can’t Sleep Toolkit`（助眠工具面板），先给出 Stimulus Control 指导：
   - 离开床
   - 做安静活动
   - 困了再回床
3. 用户可继续选择放松功能（非强制）：
   - 渐进式肌肉放松（PMR）：从脚部到面部，按肌群轮询；每个肌群紧张 5-7 秒，放松 15-20 秒，强化对比感知
   - 呼吸练习：4-7-8 呼吸法、腹式呼吸训练、正念呼吸锚定
4. 完成后返回休息，不强迫填写复杂内容；仅提供可选“我已尝试”轻量反馈

### 流程 D：晨间补录

1. Home 在上午显示 `Morning Check-in` Banner
2. 用户填写实际 wake time、latency、quality、awakenings
3. 系统自动推导 TST/TIB/效率并更新卡片与趋势

### 流程 E：每周调窗

1. 每周检查最近 7 天（至少 5 条）日志
2. 按效率阈值进行 `-15 / 0 / +15 min` 调整
3. Home 显示本周建议（保持/收紧/扩展窗口）

---

## 7. 组件级设计建议（给 Figma Make 的约束）

### 必备组件

- `PlanCard`：显示计划窗口、效率徽章、本周调整提示
- `ActualSleepCard`：显示 Bed / Sleep / Wake + Latency / Duration / Quality
- `GuidanceCard`：偏移提醒（drift）与行为建议
- `CoachCard`：教练式短文案（由效率触发）
- `CheckInBanner`：晨间高优先 CTA
- `ActionRow`：晚间开始与补录入口
- `TrendChartCard`：14 天效率趋势图
- `StatCard`：平均效率 / 平均睡眠 / 平均夜醒

### 状态设计

- 空状态：无日志、无趋势数据（提示“至少 2 条可看趋势”）
- 进行中状态：已记录 bedtime，待晨间补全
- 偏差状态：与计划偏移 >= 30 分钟
- 正向状态：效率 >= 90%，提示可扩窗

### 反馈语气（copy tone）

- 中性、教练式、低羞耻感
- 强调“继续训练”而非“达标失败”
- 少用命令，多用建议（Keep, Anchor, Log, Continue）

---

## 8. Figma Make Prompt（可直接粘贴）

请设计一款 iOS 深色模式的 CBTI 睡眠训练 app，风格克制、专业、平静，强调行为训练而非监测炫技。  
信息架构为 3 个 Tab：Home / History / Settings。  

Home 要包含：
- Tonight’s Plan（计划睡眠窗口，带效率百分比）
- Last Night（真实睡眠摘要：Bed/Sleep/Wake、Latency、Duration、Quality）
- Guidance 与 Coach 文案卡片（基于效率与偏移）
- Morning Check-in banner（早晨高优先入口）
- Action Row（Record Last Night、I’m Going To Bed）

History 要包含：
- 14 天睡眠效率折线图
- 平均效率、平均睡眠时长、平均夜醒次数
- 可点击编辑的日志列表

Settings 要包含：
- Bedtime Reminder / Morning Check-in 通知开关
- Target Wake Time 时间设置
- Data Export 入口

交互理念：
- 计划与现实并列展示
- 用户可偏离计划，系统允许修正并继续
- 夜间 “I Can’t Sleep” 提供分层支持：Stimulus Control + PMR + 呼吸练习（4-7-8、腹式、正念）
- 文案语气为非评判、支持式、可持续训练导向

算法约束（需体现在文案和状态反馈）：
- 睡眠效率 = TST / TIB
- 每周根据最近 7 天（至少 5 天）日志调整窗口：>90% 加 15 分钟，85%-90% 保持，<85% 减 15 分钟
- 与计划偏移 >= 30 分钟时触发提醒

---

## 9. 产出目标（给设计师）

- 重点不是“睡眠监测 dashboard”，而是“CBTI 训练引导界面”
- 核心体验是：**记录真实 -> 获得反馈 -> 微调窗口 -> 持续训练**
- UI 要让用户感受到“可恢复、可持续、可执行”

---

## 10. 主题色体系（UI Tokens，Coffee）

仅保留 Figma Variables 命名（约 15 色）：

- `color/coffee/50` = `#F8F3EF`
- `color/coffee/100` = `#EFE2D8`
- `color/coffee/200` = `#DCC4B1`
- `color/coffee/300` = `#C8A58B`
- `color/coffee/400` = `#B28767`
- `color/coffee/500` = `#996D4F`
- `color/coffee/600` = `#7E573F`
- `color/coffee/700` = `#664636`
- `color/coffee/800` = `#4E362B`
- `color/coffee/900` = `#38261F`
- `color/latte/200` = `#F7E6D4`
- `color/bg/canvas` = `#F5EEE8`
- `color/bg/surface` = `#FFFAF5`
- `color/text/primary` = `#38261F`
- `color/border/default` = `#D9C8BB`
