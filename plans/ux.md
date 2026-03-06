# iOS UX Design Guide

## Core Principles

> **Clarity, Deference, Fluidity** (Apple HIG)
>
> **CBT-i 核心理念**：可控、可视化、渐进式

---

## CBT-i Home Dashboard

首页回答用户三个核心问题：**今天做什么？进度如何？今晚怎么睡？**

### Layout

```
┌─────────────────────────────────────────────────────┐
│  🌙                    CBT-i 睡眠疗法              │
│  Day 7 / 28              疗程进度                  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │           🎯 今日首要任务                      │  │
│  │                                               │  │
│  │     ⏰ 06:30 起床提醒                         │  │
│  │                                               │  │
│  │     "坚持固定起床时间，打破失眠循环"          │  │
│  │                                               │  │
│  │           [✓ 完成]  [💡 提示]                 │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📊 睡眠计划                            ▸            │
│  ┌───────────────────────────────────────────────┐  │
│  │   就寝窗口    22:30 - 23:00                   │  │
│  │   起床时间    06:30 (固定)                    │  │
│  │   睡眠时长    7.5h                            │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📈 疗程追踪                            ▸            │
│  ┌───────────────────────────────────────────────┐  │
│  │   ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐       │  │
│  │   │ ✓ │ │ ✓ │ │ ✓ │ │ - │ │   │ │   │       │  │
│  │   └───┘ └───┘ └───┘ └───┘ └───┘ └───┘       │  │
│  │     M     T     W     T     F     S     S     │  │
│  │   本周完成 5/7 次      连续 3 天 ✓            │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
├─────────────────────────────────────────────────────┤
│                                                     │
│  📝 快速记录                              ▸         │
│  ┌───────────────────────────────────────────────┐  │
│  │   入睡时间    [ 23:15 ]    清醒时间 [ 06:20 ] │  │
│  │   睡眠效率    [ 85% ]      主观评价  ★★★★☆  │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### Tab Structure

```
┌─────────────────────────────────────────────────────┐
│  🏠         📝         📊         📚         ⚙️   │
│  首页       记录       统计       课程       设置   │
└─────────────────────────────────────────────────────┘

✓ Max 4 tabs (Apple HIG)
✓ 首页 = Home = 任务 + 进度 + 计划
✓ 记录 = Log = 每日睡眠记录
✓ 统计 = Statistics = 可视化分析
✓ 设置 = Settings = 个人配置
```

### Dashboard Components

| 区块 | 交互 | 目的 |
|------|------|------|
| 今日任务 | 卡片主视觉，点击展开详情 | 明确每日行动 |
| 睡眠计划 | 弹出编辑 sheet | 快速调整窗口 |
| 疗程追踪 | 周历视图 + 连胜标记 | 可视化进度 |
| 快速记录 | 内联时间选择器 | 最低门槛记录 |

### Design Principles

- **任务优先**：首页第一屏展示今日任务
- **渐进式披露**：点击展开详情
- **正向激励**：连胜标记、完成状态
- **低门槛记录**：快速记录在第二屏

---

## 1. Time Input

### Component

**`UIDatePicker`** in `.timeInterval` mode or **Custom Wheel Picker**

### Interactions

- **Scroll to select**: Vertical swipe on wheel components
- **Quick adjust**: `+15m`, `+30m`, `-15m` buttons below picker
- **Smart default**: Pre-fill with last used time

### Layout

```
┌─────────────────────────────────────┐
│            Bedtime                  │
│            10:30 PM                 │
│    ┌───┐   ┌───┐                   │
│    │ ▲ │   │ ▼ │   Hour            │
│    └───┘   └─────────────────────┐ │
│    ┌───┐   ┌───┐                 │ │
│    │ ▲ │   │ ▼ │   Minute        │ │
│    └───┘   └─────────────────────┘ │
├─────────────────────────────────────┤
│   [-15m]  [+15m]  [+30m]  [+1h]    │
└─────────────────────────────────────┘

✓ Place picker in sheet or inline
✓ Show duration hint below (e.g., "8h recommended")
```

### Sleep-Specific

- Auto-calculate sleep duration when bedtime > wake time
- Show cross-day indicator when applicable

---

## 2. Selection

### Components

- **`.menu`**: Contextual actions
- **`.confirmationDialog`**: Binary choices
- **Picker / Stepper**: Numeric selections

### Interactions

- **Tap to present**: Full-screen sheet or popover
- **Recent first**: Sort by usage frequency

### Layout

```
Sleep Goal
┌─────────────────────────────────────┐
│                                     │
│    6   7   8   9   10   11   12     │
│    ○   ●   ●   ○   ○    ○    ○     │
│          hours                      │
│                                     │
├─────────────────────────────────────┤
│  Range: 4 - 12 hours                │
└─────────────────────────────────────┘

✓ Use Picker for 3-12 numeric options
✓ Direct tap to select, auto-save
```

---

## 3. Numeric Input

### Components

- **`.stepper`**: `-` / `+` buttons
- **Slider**: With value label
- **TextField**: With keyboard

### Interactions

- **Stepper tap**: Increment/decrement by step value
- **Slider drag**: Continuous adjustment
- **Keyboard tap**: Direct numeric entry

### Layout

```
┌─────────────────────────────────────┐
│          Sleep Duration             │
│              7.5 hours              │
│                                     │
│    ┌─────┐                          │
│    │  -  │    ───────────●────────  │
│    └─────┘               7.5        │
│    ┌─────┐         4         12     │
│    │  +  │                          │
│    └─────┘                          │
├─────────────────────────────────────┤
│  Range: 4 - 12 hours                │
└─────────────────────────────────────┘

✓ SF Symbols: `minus`, `plus`, `capsule.fill`
✓ Show min/max labels below slider
✓ Stepper for discrete values (0.5h)
```

---

## 4. Form Editing

### Components

- **`.sheet`**: Modal form presentation
- **NavigationStack**: Push to detail view

### Interactions

- **Tap to expand**: Present sheet or navigate
- **Auto-save**: On dismiss, no save button needed
- **Discard**: Swipe down to dismiss

### Flow

```
View Mode                    Edit Mode
┌─────────────────────┐   ┌─────────────────────┐
│  Bedtime            │   │  Bedtime            │
│  ▸ 10:30 PM        ───▶│  10:30 PM          │
│                     │   │  ┌───┐   ┌───┐    │
│                     │   │  │ ▲ │   │ ▼ │    │
│                     │   │  └───┘   └───┘    │
│                     │   │                     │
│                     │   │      Cancel  Save   │
└─────────────────────┘   └─────────────────────┘
        ↓ swipe down to dismiss
```

### Guidelines

- **Edit in sheet**: For 1-3 fields
- **Navigate**: For 4+ fields
- **No save button**: Auto-save on dismiss
- **Confirm discard**: If unsaved changes exist

---

## 5. Date Selection

### Component

**`UIDatePicker`** with `.graphical` or `.compact` style

### Interactions

- **Tap date**: Open date picker
- **Quick nav**: Today / Yesterday / This Week
- **Swipe month**: Horizontal swipe on calendar

### Layout

```
┌─────────────────────────────────────┐
│  <    December 2024    >           │
│                                     │
│    S   M   T   W   T   F   S       │
│   25  26  27  28  29  30   1       │
│    2   3   4   5   6   7   8       │
│    9  10  11  12  13  14  15       │
│   16  17  18  19  20  21  22       │
│   23  24  25  26  27  28  29       │
│   30  31                           │
│                                     │
├─────────────────────────────────────┤
│  [Today]  [Yesterday]  [This Week] │
└─────────────────────────────────────┘

✓ Use `.graphical` for date range selection
✓ Use `.compact` for single date inline
✓ Dot indicator for dates with records
```

---

## 6. List Operations

### Components

- **Swipe Actions**: Leading/trailing
- **Edit Mode**: Bulk selection

### Interactions

- **Swipe left**: Reveal destructive action
- **Swipe right**: Reveal secondary action
- **Long press**: Enter edit mode
- **Tap checkbox**: Multi-select

### Layout

```
┌─────────────────────────────┐
│  Q   Today                  │
├─────────────────────────────┤
│  ○  7h 30m                  │
│     10:30 PM → 6:00 AM      │
├─────────────────────────────┤
│  ○  8h 15m                  │
│     11:00 PM → 7:15 AM      │
└─────────────────────────────┘
       ↑ Swipe Right  ↓ Swipe Left
┌─────────────────────────────┐
│  [Pin]        [Delete]     │
└─────────────────────────────┘

✓ Use `.destructive` for delete (red)
✓ Use `.warning` for caution actions (orange)
✓ Use `.idle` for secondary actions (gray)
✓ Max 2 swipe actions per side
```

### Edit Mode

```
┌─────────────────────────────┐
│  Cancel          Delete (2)│
├─────────────────────────────┤
│  ☑  7h 30m                  │
│  ☑  8h 15m                  │
│     9h 00m                  │
├─────────────────────────────┤
│         [Add to Favorites]  │
└─────────────────────────────┘
```

---

## 7. Feedback

### Components

- **Toast**: For brief confirmation (SwiftUI)
- **Alert**: For errors requiring action
- **Banner**: For persistent messages
- **ProgressView**: For loading states

### Usage

```
✓ Toast (1-2s): Operation success
┌─────────────────────────────┐
│  ✓ Saved                    │
└─────────────────────────────┘

✓ Alert (user action required):
┌─────────────────────────────┐
│  Delete Record?             │
│                             │
│  This cannot be undone.     │
│                             │
│      Cancel   Delete        │
└─────────────────────────────┘

✓ Banner (persistent info):
┌─────────────────────────────┐
│  ✓ 数据仅保存在本地         │
│  无需登录即可使用           │
└─────────────────────────────┘

✓ ProgressView (loading):
┌─────────────────────────────┐
│     ⏳ Loading...           │
└─────────────────────────────┘
```

### Guidelines

- **Toast**: Max 2 lines, auto-dismiss
- **Alert**: Max 2 buttons (Cancel + Action)
- **Banner**: Top of screen, swipe to dismiss
- **Skeleton**: For content loading

---

## 8.5 CBT-i Feedback Patterns

### 任务完成反馈

```
✓ 完成今日任务时:
┌─────────────────────────────────────────────────────┐
│                                                     │
│              🎉 太棒了！                            │
│                                                     │
│        今日任务已完成 ✓                            │
│        连续 3 天坚持                                │
│                                                     │
│              ★★★★★                                 │
│                                                     │
│              [太简单] [刚刚好] [有点难]              │
│                                                     │
└─────────────────────────────────────────────────────┘

✓ 使用 confetti 动画 (1-2s)
✓  haptic.success
✓ 难度反馈: 调整明日任务强度
```

### 疗程进度反馈

```
✓ 周度回顾:
┌─────────────────────────────────────────────────────┐
│                                                     │
│              📈 本周总结                            │
│                                                     │
│        ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐       │
│        │ ✓ │ │ ✓ │ │ ✓ │ │ - │ │ ✓ │ │ ✓ │       │
│        └───┘ └───┘ └───┘ └───┘ └───┘ └───┘       │
│          M     T     W     T     F     S          │
│                                                     │
│        完成任务: 5/7                                │
│        睡眠效率: +5%                                │
│        就寝规律: +30min                             │
│                                                     │
│        🏆 新成就: 一周坚持家                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 异常提醒

```
✓ 未完成记录提醒 (22:00 后):
┌─────────────────────────────────────────────────────┐
│  ⚠️                                              │
│  今日睡眠记录还未填写                              │
│  现在记录 → 忽略                                   │
└─────────────────────────────────────────────────────┘

✓ 就寝时间偏离:
┌─────────────────────────────────────────────────────┐
│  💡                                              │
│  今晚比计划晚 45 分钟                              │
│  坚持固定时间，明晚再调整                           │
└─────────────────────────────────────────────────────┘
```

### Design Principles

- **正向为主**: 80% 正向反馈，20% 提醒
- **数据驱动**: 用具体数值展示进步
- **小步渐进**: 每次只强调一个进步点

---

## 8. Navigation

### Structure

- **TabBar**: Top-level sections (max 5)
- **NavigationStack**: Hierarchical content
- **Sheet**: Secondary content

### CBT-i Tab Structure

```
┌─────────────────────────────────────────────────────┐
│  🏠         📝         📊         📚         ⚙️   │
│  首页       记录       统计       课程       设置   │
└─────────────────────────────────────────────────────┘
```

| Tab | Content | Key Features |
|-----|---------|--------------|
| 🏠 首页 | Home | Daily task, progress, sleep plan |
| 📝 记录 | Log | Sleep entry, edit, delete |
| 📊 统计 | Statistics | Charts, trends, insights |
| ⚙️ 设置 | Settings | Profile, notifications |

本产品不提供独立的 CBT-i 课程页；教育内容通过首页任务和记录流程自然呈现。

### Navigation Patterns

```
Home (Tab 1)          Sleep Plan (Sheet)    Detail (Stack)
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  Today's Task   │   │  Sleep Window   │   │  Task Details   │
│           Edit ───▶│  Bedtime  22:30 │   │  Instructions   │
│                 │   │  Wake    06:30 │   │  Tips           │
│                 │   │  [Save] [Cancel]│  │  [Complete]     │
└─────────────────┘   └─────────────────┘   └─────────────────┘
```

### Guidelines

- **Tab 切换**: 无需保存，自动持久化
- **Sheet**: 用于快速编辑（1-3 字段）
- **Stack**: 用于详细浏览（任务详情、课程内容）
- **底部弹出**: 底部 sheet 用于筛选、选择

---

## 9. Accessibility

### Requirements

- **Dynamic Type**: Support `.largeTitle` → `.caption1`
- **Haptic**: Use `UIImpactFeedbackGenerator`
- **VoiceOver**: Proper accessibility labels
- **Color**: WCAG AA contrast ratio (4.5:1)

### Example

```swift
Button(action: save) {
  Label("Save", systemImage: "checkmark.circle.fill")
}
.accessibilityLabel("Save sleep record")
.accessibilityHint("Double tap to save")
```

---

## Priority Matrix

| Priority | Feature | Complexity |
|----------|---------|------------|
| P0 | 首页 Dashboard | Medium |
| P0 | 今日任务卡片 | Low |
| P0 | 快速睡眠记录 | Low |
| P0 | 睡眠计划编辑 | Low |
| P1 | 疗程进度追踪 | Medium |
| P1 | 睡眠记录列表 | Low |
| P1 | 睡眠统计图表 | Medium |

### P0 关键路径

```
用户打开 App → 看到今日任务 → 快速记录 → 完成闭环
```

---

## Design Resources

- **SF Symbols**: `A` → `Z` + numbers + symbols
- **System Colors**: Primary, Secondary, Tertiary
- **Corner Radius**: 10pt (default), 20pt (cards)
- **Spacing**: 8pt grid system
