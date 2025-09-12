#!/bin/bash

# 视频编辑器应用运行脚本

echo "🎬 VideoEditor App - 运行脚本"
echo "================================"

# 检查Xcode是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误: 未找到Xcode，请先安装Xcode"
    exit 1
fi

# 检查iOS模拟器
if ! command -v xcrun simctl list &> /dev/null; then
    echo "❌ 错误: iOS模拟器不可用"
    exit 1
fi

echo "✅ 环境检查通过"
echo ""

# 显示可用的模拟器
echo "📱 可用的iOS模拟器："
xcrun simctl list devices available | grep "iPhone\|iPad" | head -5

echo ""
echo "🚀 启动应用..."

# 尝试在iOS模拟器中运行
cd VideoEditorApp.xcodeproj/..

# 构建项目
echo "🔨 构建项目..."
xcodebuild -project VideoEditorApp.xcodeproj -scheme VideoEditorApp -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo ""
    echo "📖 使用说明："
    echo "1. 在Xcode中打开 VideoEditorApp.xcodeproj"
    echo "2. 选择iOS模拟器 (iPhone 15 推荐)"
    echo "3. 点击运行按钮 (⌘+R)"
    echo ""
    echo "🎯 功能特性："
    echo "• 时间轴视频剪辑"
    echo "• 画面裁剪和缩放"
    echo "• 实时预览"
    echo "• 高质量导出"
    echo ""
    echo "💡 提示：首次运行需要授权访问相册"
else
    echo "❌ 构建失败，请检查错误信息"
    echo ""
    echo "🔧 故障排除："
    echo "1. 确保iOS 17.0+ SDK可用"
    echo "2. 检查Xcode版本 (需要15.0+)"
    echo "3. 清理构建缓存: Product -> Clean Build Folder"
    exit 1
fi
