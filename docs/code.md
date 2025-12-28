# Code Style Guide - iOS Unix Philosophy

## 1. 命名：短而精确

```swift
// ✓ Unix 风格
load, play, stop, isPlaying, delegate, vc, btn, lbl

// ✗ 冗长
loadWordsFromServer, handleSearchButtonTap, audioPlayerController
```

**原则**：上下文足够时用缩写，作用域越小名字越短

## 2. 函数：单一职责，15行内

```swift
// ✓ 一个函数做一件事
func play(_ word: Word) {
    player.stop()
    player.load(word.url)
    player.play()
}
```

**原则**：能拆则拆，能内联则内联

## 3. 状态：最小化

```swift
// ✓ 合并相关状态
@State private var playing: (id: String, accent: Accent)?

// ✗ 分散状态
@State private var playingWordId: String?
@State private var playingUkWordId: String?
```

**原则**：一个概念一个变量

## 4. 条件：提前返回

```swift
// ✓ Guard clause
func load(reset: Bool = false) {
    guard !isLoading || reset else { return }
    // 主逻辑...
}
```

**原则**：先排除异常，再走正常流程

## 5. 表达式：紧凑

```swift
// ✓ 一行搞定
words = reset ? data : words + data
player?.play()
```

**原则**：能用表达式就不用语句

## 6. 类型：按需标注

```swift
// ✓ 必要时标注
@State private var words: [Word] = []

// ✓ 可推断时省略
let count = words.count
```

## 7. 错误处理：静默或日志

```swift
// ✓ 简单处理
if let error = result.error { return print(error) }
player.play()
```

**原则**：失败就失败，别假装没事

## 8. 注释：无

```swift
// ✓ 代码即文档
func isPlaying(_ word: Word, _ accent: Accent) -> Bool {
    playing?.id == word.id && playing?.accent == accent
}
```

**原则**：好代码不需要注释

## 9. 代码量指标

| 指标 | 目标 |
|------|------|
| 函数体 | ≤ 20 行 |
| 文件 | ≤ 300 行 |
| 参数 | ≤ 3 个 |
| 嵌套 | ≤ 2 层 |
| @State/@Published | ≤ 10 个 |

## 10. iOS 特有规范

```swift
// ✓ View 放最后
final class PlayerView: UIView { ... }

// ✓ 协议命名
protocol PlayerDelegate: AnyObject { ... }

// ✓ 闭包参数在前
func onComplete(_ completion: @escaping () -> Void)

// ✓ UI 组件命名
@IBOutlet weak var playButton: UIButton!
@IBOutlet weak var titleLabel: UILabel!
```

## 哲学总结

> **Do one thing well. Make it composable. Keep it small.**
