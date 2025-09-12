import AVFoundation
import UIKit

/// 视频导出器，负责处理视频导出相关功能
@MainActor
public final class VideoExporter: NSObject {
    
    // MARK: - Types
    
    enum ExportError: LocalizedError {
        case noComposition
        case exportSessionCreationFailed
        case exportFailed(Error)
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .noComposition:
                return "没有可导出的视频内容"
            case .exportSessionCreationFailed:
                return "无法创建导出会话"
            case .exportFailed(let error):
                return "导出失败: \(error.localizedDescription)"
            case .cancelled:
                return "导出已取消"
            }
        }
    }
    
    public struct ExportSettings {
        let preset: VideoCompositionBuilder.ExportPreset
        let outputFileType: AVFileType
        let outputURL: URL
        
        public init(
            preset: VideoCompositionBuilder.ExportPreset = .highQuality,
            outputFileType: AVFileType = .mp4,
            outputURL: URL
        ) {
            self.preset = preset
            self.outputFileType = outputFileType
            self.outputURL = outputURL
        }
    }
    
    // MARK: - Properties
    
    private var currentExportSession: AVAssetExportSession?
    
    // MARK: - Public Methods
    
    /// 导出视频
    public func exportVideo(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition?,
        settings: ExportSettings,
        progressHandler: ((Float) -> Void)? = nil
    ) async throws -> URL {
        
        // 创建导出会话
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw ExportError.exportSessionCreationFailed
        }
        
        currentExportSession = exportSession
        
        // 配置导出会话
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = settings.outputFileType
        exportSession.outputURL = settings.outputURL
        
        // 设置视频输出设置（保持原始质量）
        if let videoComposition = videoComposition {
            exportSession.videoComposition = videoComposition
        }
        
        // 删除已存在的文件
        if FileManager.default.fileExists(atPath: settings.outputURL.path) {
            try FileManager.default.removeItem(at: settings.outputURL)
        }
        
        // 开始导出
        return try await withCheckedThrowingContinuation { continuation in
            // 启动进度监控
            let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                let progress = exportSession.progress
                Task { @MainActor in
                    progressHandler?(progress)
                }
            }
            
            exportSession.exportAsynchronously {
                progressTimer.invalidate()
                
                Task { @MainActor in
                    switch exportSession.status {
                    case .completed:
                        continuation.resume(returning: settings.outputURL)
                        
                    case .failed:
                        let error = exportSession.error ?? ExportError.exportSessionCreationFailed
                        continuation.resume(throwing: ExportError.exportFailed(error))
                        
                    case .cancelled:
                        continuation.resume(throwing: ExportError.cancelled)
                        
                    default:
                        let error = exportSession.error ?? ExportError.exportSessionCreationFailed
                        continuation.resume(throwing: ExportError.exportFailed(error))
                    }
                    
                    self.currentExportSession = nil
                }
            }
        }
    }
    
    /// 取消导出
    public func cancelExport() {
        currentExportSession?.cancelExport()
        currentExportSession = nil
    }
    
    /// 生成默认的输出URL
    static func generateOutputURL(withExtension ext: String = "mp4") -> URL {
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "exported_video_\(timestamp).\(ext)"
        
        return documentsPath.appendingPathComponent(filename)
    }
    
    /// 获取视频文件信息
    static func getVideoInfo(from url: URL) async -> (duration: TimeInterval, size: CGSize, bitRate: Float)? {
        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration).seconds
            
            guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                return nil
            }
            
            let naturalSize = try await videoTrack.load(.naturalSize)
            let bitRate = try await videoTrack.load(.estimatedDataRate)
            
            return (duration: duration, size: naturalSize, bitRate: bitRate)
        } catch {
            print("获取视频信息失败: \(error)")
            return nil
        }
    }
    
    /// 生成视频缩略图
    static func generateThumbnail(
        from asset: AVAsset,
        at time: CMTime = .zero,
        size: CGSize = CGSize(width: 200, height: 200)
    ) async -> UIImage? {
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size
        
        do {
            let cgImage = try await generator.image(at: time).image
            return UIImage(cgImage: cgImage)
        } catch {
            print("生成缩略图失败: \(error)")
            return nil
        }
    }
    
    /// 检查导出预设兼容性
    static func checkExportCompatibility(
        for asset: AVAsset,
        preset: String = AVAssetExportPresetHighestQuality
    ) async -> Bool {
        
        let compatiblePresets = await AVAssetExportSession.exportPresets(compatibleWith: asset)
        return compatiblePresets.contains(preset)
    }
}

// MARK: - Convenience Extensions

extension VideoExporter {
    
    /// 简化的导出方法
    public func exportVideo(
        clips: [Clip],
        outputURL: URL? = nil,
        preset: VideoCompositionBuilder.ExportPreset = .highQuality,
        progressHandler: ((Float) -> Void)? = nil
    ) async throws -> URL {
        
        // 构建合成
        let builder = VideoCompositionBuilder()
        builder.setClips(clips)
        builder.applyPreset(preset)
        
        guard let composition = builder.buildComposition() else {
            throw ExportError.noComposition
        }
        
        let videoComposition = builder.buildVideoComposition(for: composition)
        
        // 生成输出URL
        let finalOutputURL = outputURL ?? Self.generateOutputURL()
        
        // 创建导出设置
        let settings = ExportSettings(
            preset: preset,
            outputURL: finalOutputURL
        )
        
        // 开始导出
        return try await exportVideo(
            composition: composition,
            videoComposition: videoComposition,
            settings: settings,
            progressHandler: progressHandler
        )
    }
}

// MARK: - Progress Tracking

extension VideoExporter {
    
    /// 导出进度信息
    struct ExportProgress {
        let progress: Float
        let estimatedTimeRemaining: TimeInterval?
        let currentPhase: String
        
        var percentage: Int {
            return Int(progress * 100)
        }
        
        var isCompleted: Bool {
            return progress >= 1.0
        }
    }
    
    /// 获取详细的导出进度信息
    func getDetailedProgress() -> ExportProgress? {
        guard let session = currentExportSession else { return nil }
        
        let progress = session.progress
        let phase: String
        
        switch session.status {
        case .waiting:
            phase = "等待中..."
        case .exporting:
            phase = "导出中..."
        case .completed:
            phase = "完成"
        case .failed:
            phase = "失败"
        case .cancelled:
            phase = "已取消"
        default:
            phase = "未知状态"
        }
        
        return ExportProgress(
            progress: progress,
            estimatedTimeRemaining: nil, // AVAssetExportSession 不提供预估时间
            currentPhase: phase
        )
    }
}
