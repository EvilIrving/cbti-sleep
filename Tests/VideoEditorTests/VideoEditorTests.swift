import XCTest
import AVFoundation
@testable import VideoEditor

final class VideoEditorTests: XCTestCase {
    
    var videoEditor: VideoEditor!
    
    override func setUpWithError() throws {
        videoEditor = VideoEditor.shared
    }
    
    override func tearDownWithError() throws {
        videoEditor = nil
    }
    
    // MARK: - Basic Tests
    
    func testVideoEditorSharedInstance() throws {
        XCTAssertNotNil(VideoEditor.shared)
        XCTAssertTrue(VideoEditor.shared === VideoEditor.shared)
    }
    
    func testVideoEditingSupported() throws {
        let isSupported = VideoEditor.isVideoEditingSupported()
        XCTAssertTrue(isSupported, "视频编辑应该在测试环境中被支持")
    }
    
    func testSupportedFormats() throws {
        let videoFormats = VideoEditor.getSupportedVideoFormats()
        let audioFormats = VideoEditor.getSupportedAudioFormats()
        
        XCTAssertFalse(videoFormats.isEmpty, "应该支持至少一种视频格式")
        XCTAssertFalse(audioFormats.isEmpty, "应该支持至少一种音频格式")
        
        XCTAssertTrue(videoFormats.contains("mp4"), "应该支持MP4格式")
        XCTAssertTrue(audioFormats.contains("mp3"), "应该支持MP3格式")
    }
    
    func testVersionInfo() throws {
        let version = VideoEditor.version
        let buildInfo = VideoEditor.buildInfo
        let systemRequirements = VideoEditor.systemRequirements
        
        XCTAssertFalse(version.isEmpty, "版本信息不应为空")
        XCTAssertFalse(buildInfo.isEmpty, "构建信息不应为空")
        XCTAssertFalse(systemRequirements.isEmpty, "系统要求不应为空")
    }
    
    // MARK: - Configuration Tests
    
    func testConfiguration() throws {
        let configuration = VideoEditorConfiguration(
            maxVideoDuration: 300,
            enableHardwareAcceleration: true,
            defaultExportQuality: .highQuality
        )
        
        videoEditor.configure(with: configuration)
        
        XCTAssertEqual(VideoEditorConfiguration.current.maxVideoDuration, 300)
        XCTAssertTrue(VideoEditorConfiguration.current.enableHardwareAcceleration)
        XCTAssertEqual(VideoEditorConfiguration.current.defaultExportQuality, .highQuality)
    }
    
    // MARK: - Clip Tests
    
    func testClipCreation() throws {
        // 创建一个测试用的空资源
        let testURL = URL(fileURLWithPath: "/dev/null")
        let asset = AVURLAsset(url: testURL)
        
        let clip = Clip(asset: asset)
        
        XCTAssertNotNil(clip.id)
        XCTAssertEqual(clip.asset, asset)
        XCTAssertEqual(clip.cropRect, CGRect(x: 0, y: 0, width: 1, height: 1))
        XCTAssertEqual(clip.transform, .identity)
        XCTAssertFalse(clip.isSelected)
    }
    
    func testClipWithCustomTimeRange() throws {
        let testURL = URL(fileURLWithPath: "/dev/null")
        let asset = AVURLAsset(url: testURL)
        let timeRange = CMTimeRange(
            start: CMTime(seconds: 1, preferredTimescale: 600),
            duration: CMTime(seconds: 5, preferredTimescale: 600)
        )
        
        let clip = Clip(asset: asset, timeRange: timeRange)
        
        XCTAssertEqual(clip.timeRange, timeRange)
    }
    
    // MARK: - CropRatio Tests
    
    func testCropRatios() throws {
        XCTAssertEqual(CropRatio.square.ratio, 1.0)
        XCTAssertEqual(CropRatio.portrait.ratio, 9.0 / 16.0, accuracy: 0.001)
        XCTAssertEqual(CropRatio.landscape.ratio, 16.0 / 9.0, accuracy: 0.001)
        XCTAssertEqual(CropRatio.cinema.ratio, 21.0 / 9.0, accuracy: 0.001)
    }
    
    func testCropRatioCalculateRect() throws {
        let containerSize = CGSize(width: 400, height: 300)
        
        let squareRect = CropRatio.square.calculateRect(in: containerSize)
        XCTAssertEqual(squareRect.width, squareRect.height)
        
        let landscapeRect = CropRatio.landscape.calculateRect(in: containerSize)
        XCTAssertGreaterThan(landscapeRect.width, landscapeRect.height)
    }
    
    // MARK: - Export Preset Tests
    
    func testExportPresets() throws {
        let highQuality = VideoCompositionBuilder.ExportPreset.highQuality
        let mediumQuality = VideoCompositionBuilder.ExportPreset.mediumQuality
        let lowQuality = VideoCompositionBuilder.ExportPreset.lowQuality
        
        XCTAssertEqual(highQuality.renderSize, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(mediumQuality.renderSize, CGSize(width: 1280, height: 720))
        XCTAssertEqual(lowQuality.renderSize, CGSize(width: 854, height: 480))
        
        XCTAssertGreaterThan(highQuality.bitRate, mediumQuality.bitRate)
        XCTAssertGreaterThan(mediumQuality.bitRate, lowQuality.bitRate)
    }
    
    func testCustomExportPreset() throws {
        let customSize = CGSize(width: 1280, height: 720)
        let customBitRate: Float = 5_000_000
        let customPreset = VideoCompositionBuilder.ExportPreset.custom(customSize, customBitRate)
        
        XCTAssertEqual(customPreset.renderSize, customSize)
        XCTAssertEqual(customPreset.bitRate, customBitRate)
    }
    
    // MARK: - VideoCompositionBuilder Tests
    
    @MainActor
    func testVideoCompositionBuilder() throws {
        let builder = VideoCompositionBuilder()
        let testURL = URL(fileURLWithPath: "/dev/null")
        let asset = AVURLAsset(url: testURL)
        let clip = Clip(asset: asset)
        
        builder.setClips([clip])
        builder.setRenderSize(CGSize(width: 1920, height: 1080))
        
        // 由于测试环境限制，我们只测试方法调用不会崩溃
        let composition = builder.buildComposition()
        XCTAssertNotNil(composition)
    }
    
    // MARK: - VideoExporter Tests
    
    @MainActor
    func testVideoExporterOutputURL() throws {
        let outputURL = VideoExporter.generateOutputURL()
        
        XCTAssertTrue(outputURL.pathExtension == "mp4")
        XCTAssertTrue(outputURL.lastPathComponent.contains("exported_video_"))
    }
    
    @MainActor
    func testVideoExporterCustomExtension() throws {
        let outputURL = VideoExporter.generateOutputURL(withExtension: "mov")
        
        XCTAssertTrue(outputURL.pathExtension == "mov")
    }
    
    // MARK: - Performance Tests
    
    func testClipCreationPerformance() throws {
        let testURL = URL(fileURLWithPath: "/dev/null")
        let asset = AVURLAsset(url: testURL)
        
        measure {
            for _ in 0..<1000 {
                _ = Clip(asset: asset)
            }
        }
    }
    
    func testCropRatioCalculationPerformance() throws {
        let containerSize = CGSize(width: 1920, height: 1080)
        
        measure {
            for _ in 0..<10000 {
                _ = CropRatio.landscape.calculateRect(in: containerSize)
            }
        }
    }
}

// MARK: - Mock Classes for Testing

class MockAVAsset: AVAsset {
    override var duration: CMTime {
        return CMTime(seconds: 10, preferredTimescale: 600)
    }
    
    override func tracks(withMediaType mediaType: AVMediaType) -> [AVAssetTrack] {
        return []
    }
}
