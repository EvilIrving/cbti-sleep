# Video Editor - Kotlin Android 版本

这是一个使用 Kotlin 和 Jetpack Compose 开发的视频编辑应用，功能与 Flutter 版本保持一致。

## 功能特性

### 🎬 核心功能
- **视频选择**: 从设备存储中选择视频文件
- **时间轴裁剪**: 通过滑动条精确选择视频片段
- **画布裁剪**: 可视化裁剪视频区域，支持多种比例
- **实时预览**: 编辑过程中实时预览效果
- **视频导出**: 高质量视频处理和导出

### 🛠 技术栈
- **Kotlin** - 主要编程语言
- **Jetpack Compose** - 现代化 UI 框架
- **MVVM + Repository 模式** - 架构模式
- **Coroutines + Flow** - 异步编程
- **FFmpeg Mobile** - 视频处理
- **ExoPlayer** - 视频播放
- **Hilt** - 依赖注入

### 🎨 UI 特性
- **暗色主题**: 专业视频编辑界面
- **渐变设计**: 美观的视觉效果
- **手势交互**: 直观的裁剪框拖拽
- **响应式布局**: 适配不同屏幕尺寸

## 项目结构

```
app/src/main/java/com/videoeditor/
├── MainActivity.kt                 # 主活动
├── VideoEditorApplication.kt       # 应用程序类
├── VideoEditorApp.kt              # 应用导航
├── ui/
│   ├── theme/                     # 主题配置
│   ├── components/                # 可复用组件
│   │   ├── VideoPlayer.kt         # 视频播放器
│   │   └── CropBoxOverlay.kt      # 裁剪框组件
│   └── screens/
│       ├── picker/                # 视频选择界面
│       └── editor/                # 视频编辑界面
├── data/
│   └── repository/                # 数据仓库
├── domain/
│   ├── model/                     # 数据模型
│   └── usecase/                   # 业务用例
└── di/                           # 依赖注入
```

## 构建要求

- **Android Studio**: Arctic Fox 或更高版本
- **Kotlin**: 1.9.10+
- **Gradle**: 8.4+
- **Android SDK**: API 24+ (Android 7.0)
- **目标 SDK**: API 34 (Android 14)

## 安装步骤

1. 克隆项目到本地
2. 使用 Android Studio 打开项目
3. 等待 Gradle 同步完成
4. 连接 Android 设备或启动模拟器
5. 运行应用

## 权限要求

- `READ_EXTERNAL_STORAGE` - 读取存储中的视频文件
- `READ_MEDIA_VIDEO` - Android 13+ 读取媒体文件
- `WRITE_EXTERNAL_STORAGE` - 保存编辑后的视频

## 主要依赖

- **Jetpack Compose**: 现代化 UI 工具包
- **ExoPlayer**: Google 的媒体播放器
- **FFmpeg Kit**: 视频处理库
- **Hilt**: 依赖注入框架
- **Navigation Compose**: 导航组件
- **Accompanist**: Compose 辅助库

## 与 Flutter 版本对比

| 功能 | Flutter 版本 | Kotlin 版本 | 状态 |
|------|-------------|-------------|------|
| 视频选择 | ✅ InstaAssetPicker | ✅ 系统文件选择器 | 完成 |
| 时间轴裁剪 | ✅ RangeSlider | ✅ RangeSlider | 完成 |
| 画布裁剪 | ✅ 自定义组件 | ✅ Compose Canvas | 完成 |
| 裁剪框交互 | ✅ 8方向拖拽 | ✅ 8方向拖拽 | 完成 |
| 视频播放 | ✅ video_player | ✅ ExoPlayer | 完成 |
| FFmpeg 处理 | ✅ ffmpeg_kit_flutter_new | ✅ FFmpeg Kit | 完成 |
| 预览功能 | ✅ 支持 | ✅ 支持 | 完成 |
| 导出功能 | ✅ 支持 | ✅ 支持 | 完成 |

## 开发说明

这个 Kotlin 版本完全重新实现了 Flutter 版本的所有功能，使用原生 Android 开发技术栈，提供了：

1. **更好的性能**: 原生应用性能优势
2. **更深度的集成**: 与 Android 系统更好的集成
3. **现代化架构**: 使用最新的 Android 开发最佳实践
4. **类型安全**: Kotlin 的类型安全特性
5. **声明式 UI**: Jetpack Compose 的声明式编程

## 许可证

本项目采用 MIT 许可证。详情请参阅 LICENSE 文件。
