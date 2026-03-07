# Swift CBTI Sleep App

一个用 Swift 开发的 iOS 睡眠管理应用，围绕 CBTI（认知行为疗法治疗失眠）的核心行为训练来设计。

## 这是什么

这不是一个普通的闹钟 app，而是一个把 `计划睡眠窗口` 和 `真实睡眠日志` 分开的 CBTI 训练工具。

核心原则只有一句话：

- `Sleep Window` 是算法给出的训练计划
- `Sleep Diary` 是用户真实发生的行为日志
- 算法只应该根据真实日志来调整下一步建议

## 当前功能

### 睡眠计划

- 显示今晚的 CBTI 计划窗口
- 支持设置目标起床时间
- 基于最近日志的睡眠效率做每周窗口调整

### 真实睡眠日志

- 记录真实 `bed time`
- 记录真实 `sleep latency`
- 记录真实 `wake time`
- 自动推导 `sleep time`、`TIB`、`TST`、`sleep efficiency`
- 支持第二天早晨补录
- 支持 `Edit Last Night` 快速修正不符合计划的实际睡眠

### 晚间流程

- `I'm Going To Bed` 用于记录实际上床时间
- 如果夜里睡不着，可进入 `I Can't Sleep` 指导
- 给出 Stimulus Control 的核心提示：

  - 离开床
  - 做安静活动
  - 困了再回床

### 进度统计

- 查看过去 14 天睡眠效率趋势
- 查看平均睡眠时长
- 查看平均夜间醒来次数

## 当前界面结构

目前实际是 3 个 Tab：

1. **Home**
   - `Tonight's Plan`
   - `Last Night`
   - `Morning Check-in`
   - `Edit Last Night`
   - `I'm Going To Bed`
2. **Progress**
   - 睡眠效率趋势
   - 平均睡眠统计
3. **Settings**
   - 提醒开关
   - 目标起床时间

## CBTI 数据模型

### 1. 计划时间

`SleepWindow`

这是 CBTI 的训练窗口，例如：

```text
23:00 - 06:00
```

它代表行为目标，不代表真实发生的数据。

### 2. 真实时间

`SleepDiaryEntry`

这是算法真正需要的日志数据，核心字段包括：

```text
bed_time
sleep_latency
wake_time
```

例如：

```text
bed_time = 23:00
sleep_latency = 180m
wake_time = 07:00
```

或者：

```text
plan = 23:00
actual bed_time = 02:00
sleep_latency = 10m
```

这两种情况都属于有效 CBTI 数据。

## 技术栈

- **语言**: Swift
- **UI 框架**: SwiftUI
- **图表**: Charts
- **数据持久化**: SwiftData
- **最低系统要求**: iOS 17+

## 项目结构

```text
cbti-sleep/
├── cbti_sleepApp.swift
├── ContentView.swift
├── Models.swift
└── SleepDataService.swift
```

## 如何运行

1. 用 Xcode 打开 `cbti-sleep/cbti-sleep.xcodeproj`
2. 选择 iPhone Simulator 或真机
3. 运行项目

## 设计方向

- 默认自动记录，但始终允许修正真实日志
- 假设用户经常偏离计划，而不是假设用户完美执行
- 让计划与日志并列出现，减少“我失败了”的感觉
- 尽量使用原生组件完成时间录入，降低交互成本

## 许可证

本项目为个人学习 / 研究用途。
