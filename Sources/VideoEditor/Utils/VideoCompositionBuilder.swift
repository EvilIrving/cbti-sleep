import AVFoundation
import CoreGraphics

/// 视频合成构建器，负责创建和管理视频合成
@MainActor
public final class VideoCompositionBuilder {
    
    // MARK: - Properties
    
    private var clips: [Clip] = []
    private var renderSize: CGSize = CGSize(width: 1920, height: 1080)
    
    // MARK: - Public Methods
    
    /// 设置视频片段
    public func setClips(_ clips: [Clip]) {
        self.clips = clips
    }
    
    /// 设置输出分辨率
    public func setRenderSize(_ size: CGSize) {
        self.renderSize = size
    }
    
    /// 构建AVMutableComposition
    public func buildComposition() -> AVMutableComposition? {
        let composition = AVMutableComposition()
        
        // 添加视频轨道
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            return nil
        }
        
        // 添加音频轨道
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        var currentTime = CMTime.zero
        
        for clip in clips {
            // 插入视频片段
            if let sourceVideoTrack = clip.asset.tracks(withMediaType: .video).first {
                do {
                    try videoTrack.insertTimeRange(
                        clip.timeRange,
                        of: sourceVideoTrack,
                        at: currentTime
                    )
                } catch {
                    print("插入视频片段失败: \(error)")
                    continue
                }
            }
            
            // 插入音频片段
            if let sourceAudioTrack = clip.asset.tracks(withMediaType: .audio).first,
               let audioTrack = audioTrack {
                do {
                    try audioTrack.insertTimeRange(
                        clip.timeRange,
                        of: sourceAudioTrack,
                        at: currentTime
                    )
                } catch {
                    print("插入音频片段失败: \(error)")
                }
            }
            
            currentTime = CMTimeAdd(currentTime, clip.timeRange.duration)
        }
        
        return composition
    }
    
    /// 构建AVMutableVideoComposition
    public func buildVideoComposition(for composition: AVMutableComposition) -> AVMutableVideoComposition? {
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        videoComposition.renderSize = renderSize
        
        // 创建主指令
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []
        var currentTime = CMTime.zero
        
        // 为每个片段创建图层指令
        for (index, clip) in clips.enumerated() {
            guard let videoTrack = composition.tracks(withMediaType: .video).first else {
                continue
            }
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            
            // 应用变换
            let transform = calculateTransform(for: clip)
            layerInstruction.setTransform(transform, at: currentTime)
            
            // 应用裁剪
            if clip.cropRect != CGRect(x: 0, y: 0, width: 1, height: 1) {
                layerInstruction.setCropRectangle(clip.cropRect, at: currentTime)
            }
            
            // 设置不透明度（用于淡入淡出效果）
            layerInstruction.setOpacity(1.0, at: currentTime)
            
            layerInstructions.append(layerInstruction)
            currentTime = CMTimeAdd(currentTime, clip.timeRange.duration)
        }
        
        mainInstruction.layerInstructions = layerInstructions
        videoComposition.instructions = [mainInstruction]
        
        return videoComposition
    }
    
    // MARK: - Private Methods
    
    private func calculateTransform(for clip: Clip) -> CGAffineTransform {
        guard let videoTrack = clip.asset.tracks(withMediaType: .video).first else {
            return clip.transform
        }
        
        let naturalSize = videoTrack.naturalSize
        let preferredTransform = videoTrack.preferredTransform
        
        // 计算视频的实际显示尺寸
        let videoSize = naturalSize.applying(preferredTransform)
        let videoAspectRatio = abs(videoSize.width / videoSize.height)
        let renderAspectRatio = renderSize.width / renderSize.height
        
        // 计算缩放比例以适应输出分辨率
        var scaleX: CGFloat
        var scaleY: CGFloat
        
        if videoAspectRatio > renderAspectRatio {
            // 视频更宽，以高度为准
            scaleY = renderSize.height / abs(videoSize.height)
            scaleX = scaleY
        } else {
            // 视频更高，以宽度为准
            scaleX = renderSize.width / abs(videoSize.width)
            scaleY = scaleX
        }
        
        // 组合变换
        var transform = preferredTransform
        transform = transform.scaledBy(x: scaleX, y: scaleY)
        transform = transform.concatenating(clip.transform)
        
        // 居中显示
        let scaledVideoSize = CGSize(
            width: abs(videoSize.width) * scaleX,
            height: abs(videoSize.height) * scaleY
        )
        
        let offsetX = (renderSize.width - scaledVideoSize.width) / 2
        let offsetY = (renderSize.height - scaledVideoSize.height) / 2
        
        transform = transform.translatedBy(x: offsetX, y: offsetY)
        
        return transform
    }
}

// MARK: - Export Presets

extension VideoCompositionBuilder {
    
    /// 预设的导出配置
    public enum ExportPreset {
        case highQuality
        case mediumQuality
        case lowQuality
        case custom(CGSize, Float)
        
        public var renderSize: CGSize {
            switch self {
            case .highQuality:
                return CGSize(width: 1920, height: 1080)
            case .mediumQuality:
                return CGSize(width: 1280, height: 720)
            case .lowQuality:
                return CGSize(width: 854, height: 480)
            case .custom(let size, _):
                return size
            }
        }
        
        public var bitRate: Float {
            switch self {
            case .highQuality:
                return 8_000_000 // 8 Mbps
            case .mediumQuality:
                return 4_000_000 // 4 Mbps
            case .lowQuality:
                return 2_000_000 // 2 Mbps
            case .custom(_, let bitRate):
                return bitRate
            }
        }
    }
    
    /// 使用预设配置
    public func applyPreset(_ preset: ExportPreset) {
        setRenderSize(preset.renderSize)
    }
}
