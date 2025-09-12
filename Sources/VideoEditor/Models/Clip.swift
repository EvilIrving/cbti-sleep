import AVFoundation
import CoreGraphics

/// 视频片段数据模型
/// 包含视频资源、时间范围、裁剪框和变换信息
@Observable
public final class Clip: Identifiable, Sendable {
    public let id = UUID()
    public let asset: AVAsset
    
    /// 用户在时间轴上切割后的时间范围
    public var timeRange: CMTimeRange
    
    /// 归一化裁剪框 (0~1)，表示裁剪框在画面中的位置
    public var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    
    /// 缩放/平移变换矩阵
    public var transform: CGAffineTransform = .identity
    
    /// 视频片段在时间轴上的开始位置
    public var startTime: CMTime = .zero
    
    /// 是否被选中
    public var isSelected: Bool = false
    
    public init(asset: AVAsset, timeRange: CMTimeRange? = nil) {
        self.asset = asset
        self.timeRange = timeRange ?? CMTimeRange(
            start: .zero,
            duration: asset.duration
        )
    }
    
    /// 获取视频的自然尺寸
    public var naturalSize: CGSize {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return .zero
        }
        return videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    }
    
    /// 获取视频的帧率
    public var frameRate: Float {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return 30.0
        }
        return videoTrack.nominalFrameRate
    }
}

/// 支持的裁剪比例
public enum CropRatio: String, CaseIterable, Sendable {
    case original = "原始"
    case square = "1:1"
    case portrait = "9:16"
    case landscape = "16:9"
    case cinema = "21:9"
    
    public var ratio: CGFloat {
        switch self {
        case .original:
            return 0 // 特殊值，表示使用原始比例
        case .square:
            return 1.0
        case .portrait:
            return 9.0 / 16.0
        case .landscape:
            return 16.0 / 9.0
        case .cinema:
            return 21.0 / 9.0
        }
    }
    
    /// 根据给定的容器尺寸计算裁剪框
    public func calculateRect(in containerSize: CGSize) -> CGRect {
        guard ratio > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        
        let containerRatio = containerSize.width / containerSize.height
        
        if ratio > containerRatio {
            // 宽度受限
            let width = containerSize.width
            let height = width / ratio
            let y = (containerSize.height - height) / 2
            return CGRect(x: 0, y: y, width: width, height: height)
        } else {
            // 高度受限
            let height = containerSize.height
            let width = height * ratio
            let x = (containerSize.width - width) / 2
            return CGRect(x: x, y: 0, width: width, height: height)
        }
    }
}
