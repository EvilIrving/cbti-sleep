# CBTI睡眠管理应用 - 顶层设计文档

## 一、项目概述

本项目旨在打造一款纯粹、有效的CBTI（失眠认知行为疗法）睡眠管理应用。区别于市面上繁杂的健康类App，本产品聚焦于CBTI核心理念，通过科学的行为干预帮助用户建立健康的睡眠习惯。产品设计强调用户体验的温和性，避免数据焦虑，专注于习惯养成和行为改变。

### 1.1 核心设计理念

CBTI疗法是目前被广泛认可的失眠一线治疗方法，其有效性已得到大量临床研究的证实。本应用将CBTI的核心模块——睡眠限制、刺激控制、睡眠日记和认知引导——转化为可交互的数字产品体验。设计上遵循「温和引导、非评判性反馈、渐进式改变」的原则，确保用户在安全、无压力的环境中逐步改善睡眠质量。

产品命名建议为「睡眠重构」或「CBTI睡眠助手」，强调这是一个帮助用户重新建立健康睡眠模式的过程，而非单纯的睡眠监测工具。交互设计上，App不应成为用户的另一个压力源，而应像一个理解失眠困扰的专业伙伴，提供科学指导的同时给予情感支持。

### 1.2 目标用户画像

本产品面向以下用户群体：经历慢性失眠困扰的成年人群，他们可能已经尝试过多种改善方法但效果有限；对睡眠质量有较高追求的白领人士，希望通过科学方法优化睡眠；以及正在接受CBTI治疗需要日常执行和记录的患者。值得注意的是，本应用定位为辅助工具，不能替代专业医疗诊断和治疗，对于疑似有睡眠障碍（如睡眠呼吸暂停、REM睡眠行为障碍等）的用户，应建议其寻求专业医疗帮助。

### 1.3 商业模式

**首疗程免费：** 用户可免费使用完整的12周标准CBTI治疗周期，确保用户能够充分体验产品价值后再做付费决策。

**后续付费：** 疗程结束后，用户可按需购买下一个疗程。

**无社交功能：** 本产品专注于个人使用，不设社交功能，消除社交压力和比较焦虑。

### 1.4 用户体系

| 状态 | 功能权限 |
|------|----------|
| 未登录 | 基础打卡、今日记录（本地存储） |
| 已注册 | 云同步、多设备登录、完整引导、进度分析 |

### 1.5 可配置治疗周期

- **6周方案：** 轻度失眠用户，快速入门
- **8周方案：** 标准疗程，中度失眠用户
- **12周方案：** 完整疗程，重度失眠用户或需要巩固效果的用户

---

## 二、CBTI核心算法逻辑设计

CBTI算法的核心在于通过系统化的睡眠窗口调整和行为干预，打破失眠的恶性循环。以下详细阐述各个模块的算法逻辑。

### 2.1 睡眠限制算法（Sleep Restriction）

睡眠限制是CBTI中最核心的干预手段，其原理是通过限制用户在床上的时间来提高睡眠效率（即实际睡眠时间与在床时间的比值）。算法实施步骤如下：

**第一步：基线数据收集。** 在开始睡眠限制之前，用户需要记录至少1-2周的基线睡眠数据，包括上床时间、入睡时间、醒来时间、起床时间，以及夜间醒来次数和持续时间。这些数据用于计算当前睡眠效率。

**第二步：计算睡眠窗口。** 睡眠效率的计算公式为：睡眠效率 = 实际睡眠总时间 / 在床总时间 × 100%。例如，用户记录显示平均实际睡眠5.5小时，在床时间为8小时，则睡眠效率为68.75%。根据睡眠效率计算初始睡眠窗口：初始睡眠窗口 = 平均实际睡眠时间 + 30分钟缓冲。例如，上例中初始睡眠窗口为6小时。

**第三步：设定睡眠窗口边界。** 确定固定起床时间（通常是用户日常需要起床的时间往前推睡眠窗口时长）。固定起床时间的选择至关重要，它建立了生理节律的锚点。例如，若用户需要早上7点起床，睡眠窗口为6小时，则睡眠窗口为凌晨1点至早上7点。

**第四步：动态调整机制。** 每两周根据睡眠效率评估调整睡眠窗口。若睡眠效率超过90%，可增加睡眠窗口15-30分钟；若睡眠效率在85-90%之间，维持当前窗口；若睡眠效率低于80%，则需要评估是否存在其他问题（如睡前咖啡、压力事件等），必要时缩短睡眠窗口15-30分钟。睡眠窗口的调整遵循渐进原则，避免剧烈变化。

**代码实现逻辑：** 定义`SleepRestrictionService`类，包含`calculateBaselineSleepEfficiency`、`determineInitialSleepWindow`、`adjustSleepWindow`、`validateWindowBounds`等方法。核心算法使用滚动窗口计算最近14天的睡眠效率，根据效率值区间执行相应的窗口调整策略。

### 2.2 刺激控制算法（Stimulus Control）

刺激控制的核心理念是重建床和卧室与睡眠之间的正向关联，打破「床=清醒」的条件反射。算法包含以下关键规则：

**规则一：仅在困倦时上床。** 用户需要学会识别「困倦」的身体信号（如眼皮沉重、频繁打哈欠、思维放缓），而非按照固定时间上床。若在床上20分钟无法入睡，应起床离开卧室，进行放松活动，直至再次感到困倦。

**规则二：建立睡前仪式。** 固定的睡前30分钟放松仪式，帮助大脑识别「准备入睡」的信号。仪式应包含低刺激活动，如阅读纸质书籍、听轻音乐、渐进式肌肉放松等。避免在床上进行任何与睡眠无关的活动（看手机、吃东西、工作）。

**规则三：固定起床时间。** 无论前一晚睡眠质量如何，每天早上固定时间起床。这有助于巩固身体的昼夜节律。若睡眠不足，身体会通过自然的睡眠驱动力在下一个睡眠窗口更容易入睡。

**规则四：避免白天补觉。** 白天小睡会削弱夜间的睡眠驱动力。若必须小睡，应控制在下午3点之前，时长不超过30分钟。

**代码实现逻辑：** 定义`StimulusControlService`类，包含`checkBedTimeAppropriateness`、`calculateTimeInBed`、`evaluateSleepAssociation`、`generateBedtimeReminder`等方法。算法需要记录用户的睡眠日志，分析是否存在刺激控制失败的情况（如在床上长时间醒着），并给出针对性的改进建议。

### 2.3 睡眠日记算法（Sleep Diary）

睡眠日记是CBTI的基础工具，既是评估工具也是干预手段。标准睡眠日记应包含以下数据点：

**睡前数据：** 记录上床时间、睡前情绪状态评分（1-10分）、睡前咖啡因/酒精摄入情况、睡前屏幕使用情况、当日压力水平评估。

**睡眠中数据：** 入睡时间（若与上床时间不同）、夜间醒来次数和每次持续时间、是否有噩梦或异常觉醒、卧室环境数据（温度、噪音、光线）。

**醒后数据：** 实际醒来时间、起床时间、醒后精神状态评分（1-10分）、夜间睡眠质量主观评价。

**代码实现逻辑：** 定义`SleepDiaryService`类，包含`recordDiaryEntry`、`calculateSleepMetrics`、`generateWeeklyReport`、`analyzePatterns`等方法。睡眠日记数据的结构化存储支持后续的数据分析和模式识别，例如识别周末熬夜、工作日补眠的模式，或发现特定活动与睡眠质量的相关性。

### 2.4 认知重构模块（Cognitive Restructuring）

失眠的认知模型强调，对睡眠的过度担忧和灾难化思维是维持失眠的重要因素。认知重构模块帮助用户识别和挑战这些非理性信念：

**常见睡眠认知扭曲识别：** 包括「全或无」思维（如「没睡够8小时就是失败」）、灾难化推理（如「今晚又睡不着，明天肯定完蛋了」）、选择性注意（只关注睡眠困难而忽视改善）、预测性焦虑（「我肯定又睡不好」）。

**认知重构技术：** 苏格拉底式提问引导用户审视自己的信念，如「有什么证据支持这个想法？有什么证据反对它？」、「最坏的情况是什么？你能应对吗？」、「一个睡眠良好的人会怎么看待这个问题？」

**代码实现逻辑：** 定义`CognitiveRestructuringService`类，包含`identifyCognitiveDistortions`、`generateSocraticQuestions`、`trackBeliefChange`、`provideReframingSuggestions`等方法。通过交互式问答引导用户进行认知调整，并追踪认知变化的历史趋势。

### 2.5 放松训练模块（Relaxation Training）

生理放松与心理放松是CBTI的辅助手段，帮助用户缓解睡前过度唤醒状态：

**渐进式肌肉放松（PMR）：** 指导用户依次收紧和放松全身肌肉群，从脚部开始逐步向上至面部。每个肌群保持5-7秒紧张，然后放松15-20秒，体验紧张与放松的对比。

**呼吸练习：** 4-7-8呼吸法（吸气4秒、屏息7秒、呼气8秒）、腹式呼吸训练、正念呼吸锚定。

**意象放松：** 引导式想象一个宁静、舒适的场景（如海滩、森林），帮助注意力从担忧中转移。

**代码实现逻辑：** 定义`RelaxationTrainingService`类，包含`getTrainingSession`、`trackProgress`、`adjustDifficulty`等方法。音频引导内容采用分步结构，首次使用提供完整引导，后续可选择精简版本或仅提供提示文字。

---

## 三、功能模块架构设计

基于 CBTI 算法逻辑，产品功能模块划分如下：

- **引导系统（Onboarding）**：首次使用体验、失眠评估、目标设定
- **睡眠日记（Sleep Diary）**：睡前/醒后打卡、睡眠记录
- **睡眠限制（Sleep Restriction）**：睡眠窗口可视化、效率追踪
- **刺激控制（Stimulus Control）**：睡前提醒、入睡困难应对
- **认知重构（Cognitive Restructuring）**：睡眠信念检测、认知挑战工具
- **放松训练（Relaxation Training）**：PMR、呼吸练习、正念冥想
- **数据分析（Analytics）**：睡眠趋势、相关性分析、进度追踪
- **智能提醒（Notifications）**：睡前/醒后提醒、勿扰模式
- **数据同步（Sync）**：本地存储、云端同步
- **可选（v2）**：HealthKit、可穿戴设备数据集成

### 3.1 引导系统模块（Onboarding）

引导系统是用户首次使用App时的关键体验，目标是帮助用户理解CBTI原理并正确设置初始参数：

**阶段一：失眠评估。** 通过简短的问卷评估用户的失眠严重程度（ISI量表），了解失眠历史、既往治疗经历和主要困扰。这有助于后续提供个性化的建议。

**阶段二：CBTI原理教育。** 用简洁易懂的语言解释失眠的认知行为模型，让用户理解「为什么单纯努力入睡反而更难入睡」。这一阶段通过动画图解、真实案例分享等方式提高用户的学习动机。

**阶段三：目标设定。** 引导用户设定可实现的改善目标（如「两周内入睡时间缩短至30分钟以内」），而非模糊的「睡得更好」。目标应符合SMART原则（具体、可测量、可达成、相关、有时限）。

**阶段四：初始配置。** 设置固定起床时间、设定提醒时间。

**每日引导：** App 每日展示个性化的 CBTI 任务列表（如「起床打卡」、「完成睡眠日记」），并提供今日小贴士。内容由本地算法根据用户当前治疗阶段和进度生成。

### 3.2 睡眠日记模块（Sleep Diary）

睡眠日记模块是用户日常使用最频繁的功能，界面设计应极简高效：

**睡前打卡流程：** 傍晚时分推送温和的提醒，用户点击后进入简短的打卡流程。界面仅显示几个关键问题：今天感觉如何？今晚预期几点睡？完成简短选择后即结束，避免造成压力。

**醒后打卡流程：** 起床后推送提醒，引导用户完成醒后记录。核心问题包括：昨晚睡眠质量评分？实际睡了几个小时？今天感觉如何？同样保持极简。

**日记查看与编辑：** 提供日历视图展示每日睡眠概况，点击可查看详细记录。支持手动编辑过往记录，但编辑时会温和提示「如实记录比完美记录更重要」。

**数据存储：** 打卡数据先保存到本地（SwiftData），App 启动时自动同步到云端。

### 3.3 睡眠限制模块（Sleep Restriction）

此模块将算法逻辑转化为可视化的用户界面：

**睡眠窗口可视化：** 用时间轴清晰展示医生建议的睡眠窗口，区分「必须在床时段」和「可灵活调整时段」。颜色编码：深蓝色表示睡眠窗口，浅蓝色表示灵活时段，灰色表示应避免卧床的时间。

**效率追踪仪表盘：** 展示当前睡眠效率数值及其变化趋势。用直观的颜色标识：绿色（效率>85%，表现良好）、黄色（效率70-85%，需关注）、红色（效率<70%，需要调整）。配以温和的文案而非冰冷的数字警告。

**窗口调整建议：** 每两周根据数据自动生成睡眠窗口调整建议。用户可选择接受建议或与医生讨论后再调整。界面展示调整的原因和预期效果，帮助用户理解背后的逻辑。

**本地计算：** 睡眠窗口推荐、效率计算、趋势分析全部在本地执行，实时响应无需网络。

### 3.4 刺激控制模块（Stimulus Control）

帮助用户执行刺激控制规则，建立床与睡眠的正向关联：

**睡前准备提醒：** 根据用户设定的睡眠窗口，提前30分钟推送「睡前准备提醒」，提示用户开始放松仪式。若用户标记「已准备入睡」，App可记录作为行为追踪。

**入睡困难应对指导：** 若用户标记「超过20分钟无法入睡」，App提供温和的引导建议，如「建议起床离开卧室，做一些放松活动，待有睡意再返回」。不提供刺激性内容（如新闻、游戏），仅提供放松指导。

**睡眠环境检查清单：** 定期提示用户检查卧室环境（温度、光线、噪音、床垫舒适度），帮助优化睡眠环境。

### 3.5 认知重构模块（Cognitive Restructuring）

提供认知层面的自助工具：

**睡眠信念检测：** 通过简短问卷定期评估用户的睡眠相关信念，如「我需要睡够8小时才能正常运作」、「如果我睡不好，明天肯定会一团糟」。识别潜在的认知扭曲。

**认知挑战工具：** 当检测到非理性信念时，提供苏格拉底式提问引导用户自我审视。界面设计为对话式，一步步引导用户发现思维漏洞。

### 3.6 放松训练模块（Relaxation Training）

提供多样化的放松技术选择：

**渐进式肌肉放松：** 提供分步骤的音频引导，包含身体各部位的收紧-放松指导。时长可选：10分钟（全身）、5分钟（精简版）。

**呼吸练习：** 4-7-8呼吸法、腹式呼吸等可视化练习。配合呼吸引导动画，帮助用户掌握节奏。

**正念冥想睡眠系列：** 针对失眠设计的正念冥想音频，从「身体扫描」到「思维观察」逐步深入。

### 3.7 可视化与分析模块（Analytics）

将睡眠数据转化为有意义的洞察：

**睡眠趋势图：** 展示过去7天、30天、90天的睡眠时长、入睡时间、醒来时间的趋势变化。使用平滑曲线而非剧烈波动，突出整体趋势。

**相关性分析：** 分析睡眠质量与日记记录因素（如咖啡摄入、运动、压力）的相关性，帮助用户发现个人化的睡眠影响因素。

**CBTI进展追踪：** 可视化展示用户在CBTI各模块的参与度和进展，如「已坚持睡眠日记12天」、「睡眠效率提升8%」。

**本地计算：** 所有趋势分析、相关性计算、进度统计均在本地完成，实时响应无需网络。

### 3.9 智能提醒模块（Notifications）

精心设计的提醒策略，避免造成压力：

**提醒类型：** 睡前提醒（可选择固定时间或基于睡眠窗口计算）、醒后提醒、用药提醒（针对配合药物治疗的用户）、复诊提醒（提醒用户记录数据以便复诊时与医生讨论）。

**智能频率调整：** 根据用户对提醒的响应情况动态调整频率。若用户持续忽略某类提醒，App会询问是否需要调整或关闭该提醒。

**勿扰模式：** 支持设置「睡眠窗口勿扰」，此期间不推送任何非紧急通知。

---

## 四、技术选型方案

### 4.1 整体技术栈

基于「先做iOS」的策略，推荐以下技术栈：

 ** 使用SwiftUI构建iOS原生应用。SwiftUI提供现代化的声明式UI开发体验，与Apple生态深度集成。

### 4.2 前端技术栈

**UI框架：** SwiftUI 4.0或更高版本。声明式UI范式与本应用的简洁设计理念契合，代码可读性和维护性好。

**状态管理：** Combine框架 + 自定义ObservableObject。SwiftUI原生的响应式状态管理，无需引入第三方库。

**依赖注入：** SwiftUI Environment特性用于传递服务实例，保持视图层纯净。

**动画：** SwiftUI内置动画系统。对于复杂的引导动画，可考虑使用Lottie实现设计师提供的AE动画。

**本地化：** SwiftUI内置的String Localization机制，支持中文、英文等多语言。

### 4.3 后端与数据存储

**本地数据库：** SwiftData。作为iOS 17+原生推出的现代数据持久化框架，SwiftData与SwiftUI深度集成，提供了声明式的API来管理数据模型。本地存储用于快速读写和离线使用。

**云数据库：** Supabase PostgreSQL。所有用户数据同步到云端，支持多设备同步和换机迁移。

**数据同步策略：**

- **本地优先（Local-First）**：数据先存SwiftData（本地）
- **手动同步**：用户打开App时执行一次同步，将本地数据上报云端，并拉取云端最新数据

**数据加密：**

- 传输层：HTTPS + TLS 1.3
- 存储层：Supabase托管的PostgreSQL自动加密
- 敏感数据（如认证令牌）：iOS Keychain存储

**认证服务：** Supabase Auth，支持Apple/Google/邮箱登录

### 4.4 第三方SDK与API

**健康数据（v2）：** HealthKit框架。需申请「Health Share」权限获取睡眠、心率等数据。v1 版本暂不集成，专注用户手动记录。

**推送通知：** UserNotifications框架。结合本地通知和远程推送（若需要跨设备功能）。

**统计分析：** 自建分析模块或使用Firebase Analytics（需注意数据合规）。

### 4.5 系统架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                         客户端层 (iOS/SwiftUI)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ 数据采集 │  │ 数据展示 │  │ 本地存储 │  │  通知    │           │
│  │ (打卡)   │  │ (UI)     │  │SwiftData │  │ 提醒    │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│         │                    │         │                          │
│         │    本地读写        │         │                          │
│         └───────────────────┼─────────┘                          │
│                             │                                     │
│                      App 启动时同步                                 │
│                             │                                     │
│                             ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                     Supabase 云服务                          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐          │   │
│  │  │PostgreSQL│  │   Auth   │  │  用户体系        │          │   │
│  │  │  数据库   │  │   认证   │  │  (多设备同步)    │          │   │
│  │  └──────────┘  └──────────┘  └──────────────────┘          │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘

**本地计算：** CBTI 核心算法（睡眠限制、效率计算、窗口调整）全部在本地执行，响应更快，无网络依赖。

**云端职责：** 仅用于用户认证和数据持久化（多设备数据同步、换机迁移）。

### 4.6 项目架构模式

推荐采用**MVVM + Clean Architecture**的分层架构：

```

┌─────────────────────────────────────────────────┐
│                  View Layer                      │
│            (SwiftUI Views + ViewModel)           │
├─────────────────────────────────────────────────┤
│                Domain Layer                      │
│         (Use Cases + Business Logic)             │
├─────────────────────────────────────────────────┤
│                Data Layer                        │
│      (Repositories + Data Sources + Models)      │
├─────────────────────────────────────────────────┤
│               Framework Layer                    │
│      (Keychain, UserNotifications)               │
└─────────────────────────────────────────────────┘

```

**View层：** 负责UI渲染，响应用户交互，调用ViewModel。不包含业务逻辑。

**Domain层：** 包含Use Case（用例），定义业务规则和算法逻辑。这一层应该是纯Swift代码，不依赖任何框架。

**Data层：** 负责数据获取（本地DB、网络API、第三方SDK）和数据映射。实现Domain层定义的Repository接口。

**Framework层：** 与外部框架和系统API的交互封装，隔离第三方依赖。

### 4.7 技术栈汇总

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| iOS 前端 | SwiftUI + SwiftData | 声明式UI + 本地数据存储 |
| 云数据库 | Supabase PostgreSQL | 用户数据云端存储，支持多设备同步 |
| 认证 | Supabase Auth | Apple/邮箱登录 |
| 图表 | Swift Charts | iOS原生图表库 |
| 可选 (v2) | HealthKit | 健康数据集成，自动同步睡眠数据 |

---

## 五、UI/UX视觉规范设计

### 5.1 设计原则

**原则一：温和无压。** 界面不应传递焦虑感，避免使用红色等警示色强调问题。数据展示采用趋势而非单点数值，弱化「好/坏」的二元评判。

**原则二：极简克制。** 每个屏幕聚焦一个核心任务，减少视觉干扰。信息密度适中，留白充足，给用户「呼吸的空间」。

**原则三：自然隐喻。** 使用自然元素（如月光、海浪、山峦）作为视觉隐喻，传递宁静、恢复的感觉，而非冰冷的科技感。

**原则四：渐进引导。** 功能复杂但界面不复杂。通过渐进式披露（Progressive Disclosure）策略，在用户需要时才展示高级功能。

### 5.2 色彩系统

**主色调：** 选用低饱和度的晚霞紫色系，呼应「夜晚睡眠」主题，同时避免过于刺眼的深色。

**CSS自定义变量：**

```css
:root {
  /* 主色系 - 晚霞紫 */
  --color-primary: #7C6A6A;
  --color-primary-light: #A39595;
  --color-primary-dark: #4D4040;

  /* 背景与表面 */
  --color-background: #FDFBF7;
  --color-surface: #FFFFFF;
  --color-surface-alt: #F5F0E8;

  /* 语义色 */
  --color-success: #7A9E7E;
  --color-success-light: #E8F0E6;
  --color-warning: #D4A574;
  --color-error: #C17B7B;

  /* 文字颜色 */
  --color-text-primary: #3D3535;
  --color-text-secondary: #6B5F5F;
  --color-text-tertiary: #9E9E9E;

  /* 边框与分割线 */
  --color-border: #E0E0E0;
  --color-divider: #F0E8E8;

  /* 睡眠窗口渐变 */
  --sleep-window-gradient: linear-gradient(135deg, #5C6BC0 0%, #7E57C2 100%);

  /* 深色模式 */
  --color-dark-bg: #1A1A1A;
  --color-dark-surface: #2D2D2D;
  --color-dark-text: #E8E4E4;
}
```

**主色调应用：**

- 主色 #7C6A6A（晚霞紫）用于主要按钮和强调元素
- 主色浅 #A39595 用于次要元素和悬停状态
- 主色深 #4D4040 用于禁用状态和深色文字

**语义色：**

- 良好状态 #7A9E7E（自然绿）配合浅色背景 #E8F0E6
- 警示状态 #D4A574（琥珀色）温和提醒
- 注意状态 #C17B7B（柔和红）仅用于需要关注的提示，不用于警示用户

**渐变应用：** 睡眠窗口等可视化元素可使用柔和的渐变色，如从深蓝到淡紫的夜空渐变 `var(--sleep-window-gradient)`。

### 5.3 字体系统

**中文字体：** 优先使用系统字体（PingFang SC）。如需定制，考虑思源黑体（Noto Sans CJK）的轻盈字重。

**英文/数字：** SF Pro Display或SF Pro Text，与iOS系统风格统一。

**字重与层级：**

```
标题：SF Pro Display Semibold, 28pt
副标题：SF Pro Display Medium, 20pt
正文：SF Pro Text Regular, 17pt
辅助文字：SF Pro Text Regular, 13pt
标签文字：SF Pro Text Medium, 11pt
```

### 5.4 组件设计规范

**按钮：**

```
圆角矩形，圆角半径8-12pt
高度44pt（符合iOS无障碍标准）
主按钮：填充主色，文字白色
次按钮：边框主色，文字主色
文字按钮：无背景，仅文字颜色主色
```

**卡片：**

```
白色背景（深色模式为深灰）
圆角半径16pt
轻微阴影（elevation 1-2dp）
卡片内边距16pt
```

**列表：**

```
行高56pt（带图标的行）
分割线颜色#E0E0E0（浅色模式）
无行间空白，视觉紧凑但有呼吸感
```

**输入框：**

```
圆角12pt
边框颜色#E0E0E0
激活时边框变为主色
占位文字颜色#9E9E9E
```

### 5.5 核心页面布局

**引导页（Onboarding）：** 全屏卡片式滑动，每页展示一个核心概念。使用大幅插画（建议与合作插画师定制）配合简短文案。「开始使用」按钮位于页面底部固定位置。

**首页/仪表盘：** 顶部展示当前睡眠窗口可视化（时间轴）。中部展示今日睡眠概览（昨晚睡眠评分、当前睡眠窗口状态）。底部展示CBTI任务卡片流（今日待完成事项：睡眠日记、放松练习等）。

**睡眠日记页：** 日期选择器（日历视图）。选中日期展示睡眠时间线（入睡、醒来、夜间觉醒）。下方展示日记详情入口。FAB（浮动操作按钮）用于快速添加记录。

**分析页：** 顶部Tab切换（趋势、相关性、洞察）。图表展示区占页面2/3高度。下半部分展示关键指标卡片和文字解读。

**我的/设置页：** 用户基本信息头像、昵称。睡眠目标设置。CBTI进度总览。数据管理（导出、清除）。App设置（通知、主题、关于）。

### 5.6 交互动效规范

**页面转场：** 使用SwiftUI的`.opacity` + `.scale`组合实现温和的页面切换，避免生硬的滑动或推出效果。

**微交互动效：** 按钮点击使用轻微缩放反馈（scale 0.98）。开关控件使用平滑的填充动画。

**加载状态：** 使用骨架屏（Skeleton Loading）而非旋转加载器，减少用户等待的焦虑感。

**成功反馈：** 完成某项CBTI任务后，使用柔和的动画加简短鼓励文案（如「今天做得很好！」），避免过于夸张的庆祝效果。

---

## 六、数据架构设计

### 6.1 数据模型定义

SwiftData使用@Model宏定义持久化模型，支持自动Codable、SwiftUI集成和自动线程管理：

```swift
import SwiftData

@Model
final class SleepDiaryEntry {
    var date: Date
    var bedtimePlanned: Date?      // 计划上床时间
    var bedtimeActual: Date?       // 实际上床时间
    var sleepOnsetTime: Date?      // 入睡时间
    var wakeTime: Date?            // 醒来时间
    var riseTime: Date?            // 起床时间
    var nightAwakenings: Int       // 夜间醒来次数
    var totalAwakeDuration: Int    // 夜间清醒总时长（分钟）
    var sleepQualityRating: Int    // 睡眠质量评分 1-10
    var energyLevelRating: Int     // 醒后精力评分 1-10
    var stressLevel: Int           // 当日压力水平 1-10
    var caffeineIntake: Bool       // 是否摄入咖啡因
    var alcoholIntake: Bool        // 是否饮酒
    var exerciseToday: Bool        // 是否运动
    var screenTimeBeforeBed: Int   // 睡前屏幕使用时长（分钟）
    var moodBeforeBed: Int         // 睡前情绪 1-10
    var notes: String?             // 自由备注
    var source: DataSource         // 数据来源（v1: manual, v2: 可穿戴设备）
    var createdAt: Date            // 记录创建时间

    init(
        date: Date = Date(),
        bedtimePlanned: Date? = nil,
        sleepQualityRating: Int = 5
    ) {
        self.date = date
        self.bedtimePlanned = bedtimePlanned
        self.sleepQualityRating = sleepQualityRating
        self.createdAt = Date()
    }
}

enum DataSource: String, Codable, ModelAttribute {
    case manual
    // v2: 可穿戴设备数据源 (healthKit, fitbit, garmin, withings)
}

@Model
final class SleepRestrictionConfig {
    var fixedWakeTime: Date        // 固定起床时间
    var currentSleepWindowMinutes: Int  // 当前睡眠窗口（分钟）
    var baselineSleepEfficiency: Double  // 基线睡眠效率
    var currentSleepEfficiency: Double   // 当前睡眠效率
    var adjustmentHistory: [SleepWindowAdjustment]  // 调整历史

    init(fixedWakeTime: Date, windowMinutes: Int = 360) {
        self.fixedWakeTime = fixedWakeTime
        self.currentSleepWindowMinutes = windowMinutes
        self.baselineSleepEfficiency = 0.85
        self.currentSleepEfficiency = 0.85
    }
}

@Model
final class SleepWindowAdjustment {
    var date: Date
    var oldWindowMinutes: Int
    var newWindowMinutes: Int
    var reason: AdjustmentReason

    init(date: Date = Date(), oldMinutes: Int, newMinutes: Int, reason: AdjustmentReason) {
        self.date = date
        self.oldWindowMinutes = oldMinutes
        self.newWindowMinutes = newMinutes
        self.reason = reason
    }
}

enum AdjustmentReason: String, Codable, ModelAttribute {
    case efficiencyImproved      // 效率提升
    case efficiencyDeclined      // 效率下降
    case userRequested           // 用户主动调整
    case physicianRecommendation // 医生建议
}

@Model
final class CBTIProgress {
    var totalDays: Int
    var diaryCompletionRate: Double
    var currentSleepEfficiency: Double
    var averageSleepQuality: Double
    var streakDays: Int
    var completedModules: [String]

    init() {
        self.totalDays = 0
        self.diaryCompletionRate = 0
        self.currentSleepEfficiency = 0.85
        self.averageSleepQuality = 5
        self.streakDays = 0
        self.completedModules = []
    }
}
```

### 6.2 本地存储策略

**数据存储选择：** SwiftData作为主数据库。SwiftData基于SQLite构建，但提供了现代化的声明式API，与SwiftUI深度集成，无需编写SQL或配置Core Data的复杂堆栈。

**存储位置：** 使用SwiftData默认存储路径（应用沙盒Library/Application Support目录）。敏感数据（如用户认证令牌）存储于Keychain。

**数据加密：** iOS系统级加密保护数据库文件。可额外使用SQLCipher实现应用级加密（按需）。

**数据版本管理：** SwiftData自动处理模型变更（Schema Evolution），无需手动编写迁移脚本。通过模型版本注解支持向后兼容。

**缓存策略：** 图表数据可预计算并缓存，减少重复计算。网络请求结果使用适当的缓存策略（Cache-Control）。

**SwiftData优势示例：**

```swift
// 查询示例 - 极其简洁
@Query(
    filter: #Predicate<SleepDiaryEntry> { entry in
        entry.date >= startDate && entry.date <= endDate
    },
    sort: \.date,
    order: .reverse
) private var recentEntries: [SleepDiaryEntry]
```

### 6.3 数据备份与恢复

**本地备份：** 自动备份最近30天的数据到iCloud Drive或本地文件。备份文件加密存储。

**导出功能：** 支持导出数据为CSV或JSON格式，便于用户与医生分享或迁移到其他平台。

**隐私控制：** 明确告知用户数据存储位置和备份策略。提供删除账户和数据的功能。

---

## 七、系统架构与技术实现细节

### 7.1 模块依赖关系

```
SleepApp/
├── iOS/
│   ├── App/
│   │   └── CBTISleepApp.swift
│   ├── Models/
│   ├── Views/
│   ├── ViewModels/
│   ├── Services/
│   └── Utilities/
├── supabase/
│   ├── functions/
│   │   └── cbti-engine/
│   └── config.toml
└── docs/
    └── PRD.md
```

### 7.2 服务层设计

**SleepRestrictionAlgorithm服务：** 实现睡眠限制核心算法。

```swift
protocol SleepRestrictionAlgorithmProtocol {
    func calculateBaselineEfficiency(from entries: [SleepDiaryEntry]) -> Double
    func determineInitialSleepWindow(from efficiency: Double, averageSleepMinutes: Int) -> Int
    func shouldAdjustWindow(currentEfficiency: Double, consecutiveDays: Int) -> SleepWindowAdjustment?
    func validateWindowBounds(windowMinutes: Int, wakeTime: Date) -> ClosedInterval<Date>
}

final class SleepRestrictionAlgorithm: SleepRestrictionAlgorithmProtocol {
    private let minSleepWindow = 300  // 最小5小时
    private let maxSleepWindow = 540  // 最大9小时
    private let efficiencyThresholds = (low: 0.80, high: 0.90)
    
    func calculateBaselineEfficiency(from entries: [SleepDiaryEntry]) -> Double {
        // 过滤有效记录，计算加权平均睡眠效率
        let validEntries = entries.filter { $0.sleepOnsetTime != nil && $0.riseTime != nil }
        guard !validEntries.isEmpty else { return 0 }
        
        let totalTimeInBed = validEntries.reduce(0) { result, entry in
            let timeInBed = entry.riseTime!.timeIntervalSince(entry.bedtimeActual!)
            return result + timeInBed
        }
        
        let totalSleepTime = validEntries.reduce(0) { result, entry in
            let sleepDuration = entry.riseTime!.timeIntervalSince(entry.sleepOnsetTime!)
            let awakeDuration = TimeInterval(entry.totalAwakeDuration * 60)
            return result + (sleepDuration - awakeDuration)
        }
        
        return totalSleepTime / totalTimeInBed
    }
    
    func determineInitialSleepWindow(from efficiency: Double, averageSleepMinutes: Int) -> Int {
        let baseWindow = averageSleepMinutes + 30  // 缓冲30分钟
        return min(max(baseWindow, minSleepWindow), maxSleepWindow)
    }
    
    func shouldAdjustWindow(currentEfficiency: Double, consecutiveDays: Int) -> SleepWindowAdjustment? {
        guard consecutiveDays >= 14 else { return nil }  // 每两周评估
        
        if currentEfficiency >= efficiencyThresholds.high {
            return SleepWindowAdjustment(
                // 增加窗口15-30分钟
            )
        } else if currentEfficiency < efficiencyThresholds.low {
            return SleepWindowAdjustment(
                // 缩短窗口15-30分钟
            )
        }
        return nil
    }
}
```

**SleepDiaryService服务：** 管理睡眠日记的CRUD操作和分析。

```swift
protocol SleepDiaryServiceProtocol {
    func addEntry(_ entry: SleepDiaryEntry) async throws
    func updateEntry(_ entry: SleepDiaryEntry) async throws
    func deleteEntry(id: UUID) async throws
    func getEntries(from: Date, to: Date) async throws -> [SleepDiaryEntry]
    func getLatestEntry() async throws -> SleepDiaryEntry?
    func calculateWeeklyStatistics() async throws -> WeeklyStatistics
}

final class SleepDiaryService: SleepDiaryServiceProtocol {
    private let repository: SleepDiaryRepositoryProtocol
    
    init(repository: SleepDiaryRepositoryProtocol) {
        self.repository = repository
    }
    
    func calculateWeeklyStatistics() async throws -> WeeklyStatistics {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        let entries = try await getEntries(from: weekAgo, to: today)
        
        return WeeklyStatistics(
            averageSleepQuality: entries.map(\.sleepQualityRating).average,
            averageSleepDuration: entries.map { entry in
                guard let sleepStart = entry.sleepOnsetTime,
                      let riseTime = entry.riseTime else { return 0 }
                return riseTime.timeIntervalSince(sleepStart) / 3600
            }.average,
            averageTimeToSleep: entries.map(\.timeToSleepMinutes).average,
            sleepEfficiency: entries.map(\.sleepEfficiency).average
        )
    }
}
```

### 7.3 状态管理设计

使用`@StateObject` + `ObservableObject`的组合管理应用状态：

```swift
// 全局状态
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTab: Tab
    
    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    
    init() {
        self.hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }
}

// 页面级状态
class SleepDiaryViewModel: ObservableObject {
    @Published var entries: [SleepDiaryEntry] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let diaryService: SleepDiaryServiceProtocol
    
    @MainActor
    func loadEntries() async {
        isLoading = true
        do {
            entries = try await diaryService.getEntries(
                from: Date().startOfWeek,
                to: Date()
            )
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
```

### 7.4 依赖注入配置

使用SwiftUI Environment实现依赖注入。SwiftData无需Repository模式，@Model可直接在视图中使用@Query查询：

```swift
@main
struct SleepAppApp: App {
    @StateObject private var appState = AppState()
    @State private var modelContext: ModelContext?

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task {
                    // SwiftData 自动管理 ModelContext
                    do {
                        let schema = Schema([
                            SleepDiaryEntry.self,
                            SleepRestrictionConfig.self,
                            CBTIProgress.self
                        ])
                        let modelConfiguration = ModelConfiguration(
                            schema: schema,
                            isStoredInMemoryOnly: false
                        )
                        modelContext = ModelContainer(for: schema, configurations: [modelConfiguration]).mainContext
                    }
                }
        }
    }
}

// 简化服务层 - SwiftData 原生集成
@MainActor
final class SleepDiaryService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveEntry(_ entry: SleepDiaryEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func fetchEntries(from startDate: Date, to endDate: Date) throws -> [SleepDiaryEntry] {
        let predicate = #Predicate<SleepDiaryEntry> { entry in
            entry.date >= startDate && entry.date <= endDate
        }
        let descriptor = FetchDescriptor<SleepDiaryEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
```

### 7.5 数据表结构设计

**用户配置表 (user_profiles)：**

| 字段 | 类型 | 描述 |
|------|------|------|
| id | UUID | 用户ID |
| target_wake_time | Time | 目标起床时间 |
| sleep_window_minutes | Integer | 当前睡眠窗口（分钟） |
| treatment_phase | Enum | assessment/treatment/maintenance |
| treatment_start_date | Date | 治疗开始日期 |
| onboarding_completed | Boolean | 引导是否完成 |
| treatment_cycle_weeks | Integer | 治疗周期（可配置） |

**睡眠记录表 (sleep_records)：**

| 字段 | 类型 | 描述 |
|------|------|------|
| id | UUID | 记录ID |
| user_id | UUID | 用户ID |
| date | Date | 记录日期 |
| planned_bed_time | Time | 计划入睡时间 |
| planned_wake_time | Time | 计划起床时间 |
| actual_bed_time | Time | 实际上床时间 |
| actual_sleep_time | Time | 实际入睡时间 |
| actual_wake_time | Time | 实际起床时间 |
| sleep_quality | Integer | 睡眠质量 (1-10) |
| energy_level | Integer | 醒后精力 (1-10) |
| night_wakes | Integer | 夜醒次数 |
| night_wake_minutes | Integer | 夜醒总时长 |
| caffeine_intake | Boolean | 咖啡因摄入 |
| alcohol_intake | Boolean | 酒精摄入 |
| exercise_today | Boolean | 今日运动 |
| stress_level | Integer | 压力水平 (1-5) |
| sleep_restriction_followed | Boolean | 是否遵守睡眠限制 |

**刺激控制执行记录表 (stimulus_actions)：**

| 字段 | 类型 | 描述 |
|------|------|------|
| id | UUID | 记录ID |
| user_id | UUID | 用户ID |
| sleep_record_id | UUID | 关联睡眠记录 |
| type | Enum | bedtime_prep/sleep_attempt/midnight_wake/final_wake |
| timestamp | Time | 时间戳 |
| details | Text | 详情描述 |

### 7.8 测试策略

**单元测试：** 覆盖核心算法（睡眠限制效率计算、日记分析逻辑）。目标覆盖率：核心模块>80%。

**集成测试：** 测试服务层与数据层的交互。测试数据同步流程。

**UI测试：** 使用XCUITest测试关键用户流程（完成睡眠日记、设置睡眠窗口）。

**可用性测试：** 上线前进行目标用户的可用性测试，收集反馈迭代优化。

---

## 八、项目实施路线图

### 第一阶段：基础框架搭建

此阶段目标是建立项目基础设施和核心数据层。首先配置开发环境，包括Xcode项目初始化、代码规范配置、CI/CD流程设置。随后实现数据持久层，完成SwiftData模型定义、基础CRUD操作、@Query查询配置。阶段产出为可运行的空壳App，具备数据存储能力。

### 第二阶段：核心功能开发

此阶段聚焦CBTI核心模块的实现。首要是完成睡眠日记功能，包括睡前/醒后打卡流程、日历视图展示、数据编辑功能。随后实现睡眠限制模块，集成睡眠效率计算算法、睡眠窗口可视化、窗口调整建议。同步开发刺激控制模块，实现睡前提醒、入睡困难应对指导。阶段产出为具备基础CBTI干预能力的App。

### 第三阶段：引导系统

此阶段提升产品的完整性和用户体验。开发放松训练模块，集成音频播放、训练进度追踪。实现数据分析与可视化模块，包括睡眠趋势图、相关性分析报告。优化UI细节，完善交互动效，进行可用性测试和优化。阶段产出为功能完整、体验流畅的App。

### 第四阶段：云同步与优化

此阶段确保产品质量达到发布标准。执行全面测试，包括功能测试、性能测试、兼容性测试（iOS 15+）。进行隐私合规审查，确保符合App Store健康类App审核要求。准备应用商店素材，包括截图、描述、隐私政策文档。提交审核并准备上线后的运营方案。

### 第五阶段：发布准备与迭代

- App Store 提交
- 隐私政策、使用条款
- 用户反馈渠道
- 首次迭代计划

---

## 九、关键成功指标

### 9.1 产品指标

**用户留存：** 次日留存率目标40%，7日留存率目标25%，30日留存率目标15%。CBTI疗法需要持续执行才能见效，留存率是用户真正受益的关键指标。

**功能使用率：** 睡眠日记完成率目标60%（过去7天至少完成4天记录）。CBTI任务参与率目标50%。

**睡眠改善：** 睡眠效率提升——连续使用30天的用户，平均睡眠效率提升10%以上。

### 9.2 技术指标

**应用性能：** 冷启动时间<2秒，页面滑动帧率>58fps，应用崩溃率<0.1%。

**数据准确性：** 手动记录的数据完整性和一致性。

**隐私合规：** 通过App Store审核，无数据泄露事件。

---

## 十、风险与应对

### 10.1 产品风险

**用户依从性低：** CBTI需要用户持续参与，可能因短期内效果不明显而放弃。应对策略：设计良好的进度反馈机制，用小里程碑鼓励用户；内容上强调「睡眠改善是渐进过程」的认知教育。

**效果难以归因：** 睡眠改善受多种因素影响，难以证明App的独立贡献。应对策略：设计对照实验研究（如果有条件）；清晰传达「App是辅助工具，需要用户主动参与」。

### 10.2 技术风险

**iOS版本兼容性：** SwiftData仅支持iOS 17+。应对策略：明确最低支持版本为iOS 17，不做向后兼容以确保使用最新API。

---

## 附录A：CBTI核心概念速览

| 概念 | 原理 | 应用 |
|------|------|------|
| 睡眠限制 | 减少在床时间来提高睡眠效率 | 计算并执行个性化的睡眠窗口 |
| 刺激控制 | 重建床与睡眠的正向关联 | 睡前放松仪式、醒后立即起床 |
| 睡眠卫生 | 优化睡眠环境和行为 | 避免咖啡因、控制室温、规律运动 |
| 认知重构 | 挑战关于睡眠的扭曲信念 | 识别并调整灾难化思维 |
| 放松训练 | 降低睡前生理唤醒 | PMR、呼吸练习、正念冥想 |

---

## 附录B：推荐参考资料

**临床指南：** American Academy of Sleep Medicine - Clinical Practice Guidelines for Cognitive Behavioral Therapy for Insomnia。

**患者教育材料：** UpToDate - Patient education: Insomnia in adults (Beyond the Basics)。

**学术文献：** Morin, C.M. et al. (2022) - Psychological and behavioral treatment of insomnia。

---

## 附录C：术语表 / Glossary

| 中文术语 | 英文术语 | 定义 |
|---------|----------|------|
| 失眠认知行为疗法 | CBTI (Cognitive Behavioral Therapy for Insomnia) | 一种被临床验证的失眠治疗方法，通过改变睡眠行为和认知来改善失眠 |
| 睡眠限制 | Sleep Restriction | CBTI核心技术，通过限制在床时间来提高睡眠效率 |
| 刺激控制 | Stimulus Control | 建立床与睡眠正向关联的行为干预 |
| 睡眠效率 | Sleep Efficiency | 实际睡眠时间与在床时间的比值 |
| 睡眠窗口 | Sleep Window | 计划躺在床上的时间范围 |
| 睡眠日记 | Sleep Diary | 记录每日睡眠相关数据的工具 |
| 睡眠卫生 | Sleep Hygiene | 影响睡眠的环境和行为因素 |
| 认知重构 | Cognitive Restructuring | 识别和挑战非理性睡眠信念的心理技术 |
| 放松训练 | Relaxation Training | 帮助降低睡前生理唤醒的训练方法 |
| 渐进式肌肉放松 | PMR (Progressive Muscle Relaxation) | 依次收紧和放松全身肌肉群的放松技术 |
| 入睡潜伏期 | Sleep Latency | 从上床到入睡的时间 |
| 睡眠效率阈值 | Sleep Efficiency Threshold | 判断睡眠质量好坏的效率标准值 |
| 治疗阶段 | Treatment Phase | CBTI治疗的评估期/治疗期/巩固期 |

---

*本文档为顶层设计规划，具体实现细节将在后续技术规格文档中补充。*
