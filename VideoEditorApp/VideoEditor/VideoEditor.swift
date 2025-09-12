import UIKit
import AVFoundation

/// VideoEditor 主入口模块
/// 提供视频编辑器的公共接口
@MainActor
public final class VideoEditor {
    
    // MARK: - Shared Instance
    
    public static let shared = VideoEditor()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 创建视频编辑器视图控制器
    /// - Returns: 配置好的编辑器视图控制器
    public func createEditorViewController() -> UIViewController {
        let editorVC = EditorViewController()
        
        // 配置导航控制器
        let navigationController = UINavigationController(rootViewController: editorVC)
        navigationController.navigationBar.prefersLargeTitles = true
        
        return navigationController
    }
    
    /// 检查设备是否支持视频编辑
    /// - Returns: 是否支持视频编辑功能
    public static func isVideoEditingSupported() -> Bool {
        // 检查AVFoundation是否可用
        guard NSClassFromString("AVPlayer") != nil else {
            return false
        }
        
        // iOS 16+ 已弃用 exportPresets(compatibleWith:)
        // 这里改为检查标准高质量预设是否可用（等价快速判断）
        return AVAssetExportSession.allExportPresets().contains(AVAssetExportPresetHighestQuality)
    }
    
    /// 获取支持的视频格式
    /// - Returns: 支持的视频文件类型数组
    public static func getSupportedVideoFormats() -> [String] {
        return [
            "mp4", "mov", "m4v", "avi", "mkv",
            "wmv", "flv", "webm", "3gp", "ogv"
        ]
    }
    
    /// 获取支持的音频格式
    /// - Returns: 支持的音频文件类型数组
    public static func getSupportedAudioFormats() -> [String] {
        return [
            "mp3", "wav", "aac", "flac", "ogg",
            "wma", "m4a"
        ]
    }
    
    /// 配置视频编辑器的全局设置
    /// - Parameter configuration: 配置选项
    public func configure(with configuration: VideoEditorConfiguration) {
        VideoEditorConfiguration.current = configuration
    }
}

// MARK: - Configuration

/// 视频编辑器配置选项
public struct VideoEditorConfiguration {
    
    /// 当前配置实例
    static var current = VideoEditorConfiguration()
    
    /// 最大视频时长（秒）
    public var maxVideoDuration: TimeInterval = 300 // 5分钟
    
    /// 最大视频分辨率
    public var maxVideoResolution: CGSize = CGSize(width: 3840, height: 2160) // 4K
    
    /// 是否启用硬件加速
    public var enableHardwareAcceleration: Bool = true
    
    /// 是否启用HDR支持
    public var enableHDRSupport: Bool = true
    
    /// 默认导出质量
    public var defaultExportQuality: VideoCompositionBuilder.ExportPreset = .highQuality
    
    /// 是否显示调试信息
    public var showDebugInfo: Bool = false
    
    /// 主题配置
    public var theme: VideoEditorTheme = .system
    
    public init(
        maxVideoDuration: TimeInterval = 300,
        maxVideoResolution: CGSize = CGSize(width: 3840, height: 2160),
        enableHardwareAcceleration: Bool = true,
        enableHDRSupport: Bool = true,
        defaultExportQuality: VideoCompositionBuilder.ExportPreset = .highQuality,
        showDebugInfo: Bool = false,
        theme: VideoEditorTheme = .system
    ) {
        self.maxVideoDuration = maxVideoDuration
        self.maxVideoResolution = maxVideoResolution
        self.enableHardwareAcceleration = enableHardwareAcceleration
        self.enableHDRSupport = enableHDRSupport
        self.defaultExportQuality = defaultExportQuality
        self.showDebugInfo = showDebugInfo
        self.theme = theme
    }
}

// MARK: - Theme

/// 视频编辑器主题
public enum VideoEditorTheme {
    case system
    case light
    case dark
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - Convenience Extensions

extension VideoEditor {
    
    /// 快速创建并展示视频编辑器
    /// - Parameters:
    ///   - presentingViewController: 用于展示编辑器的视图控制器
    ///   - animated: 是否使用动画
    ///   - completion: 展示完成回调
    public func presentEditor(
        from presentingViewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let editorVC = createEditorViewController()
        presentingViewController.present(editorVC, animated: animated, completion: completion)
    }
    
    /// 快速导出视频
    /// - Parameters:
    ///   - clips: 要导出的视频片段
    ///   - outputURL: 输出文件URL（可选）
    ///   - quality: 导出质量
    ///   - progressHandler: 进度回调
    /// - Returns: 导出完成的文件URL
    public func exportVideo(
        clips: [Clip],
        to outputURL: URL? = nil,
        quality: VideoCompositionBuilder.ExportPreset = .highQuality,
        progressHandler: ((Float) -> Void)? = nil
    ) async throws -> URL {
        
        let exporter = VideoExporter()
        return try await exporter.exportVideo(
            clips: clips,
            outputURL: outputURL,
            preset: quality,
            progressHandler: progressHandler
        )
    }
}

// MARK: - Version Info

extension VideoEditor {
    
    /// 获取VideoEditor版本信息
    public static var version: String {
        return "1.0.0"
    }
    
    /// 获取构建信息
    public static var buildInfo: String {
        return "Build \(Date().timeIntervalSince1970)"
    }
    
    /// 获取系统要求信息
    public static var systemRequirements: String {
        return "iOS 17.0+, Swift 5.9+"
    }
}
