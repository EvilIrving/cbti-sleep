import UIKit
import AVFoundation
import Observation
import PhotosUI

/// 主视频编辑器控制器
@MainActor
final class EditorViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 视频片段数组
    @ObservationIgnored
    private var clips: [Clip] = [] {
        didSet {
            timelineView.setClips(clips)
            updateComposition()
        }
    }
    
    /// 当前选中的片段
    @ObservationIgnored
    private var selectedClip: Clip? {
        didSet {
            cropCanvasView.setClip(selectedClip)
            updateUI()
        }
    }
    
    /// AVPlayer 实例
    @ObservationIgnored
    private let player = AVPlayer()
    
    /// 视频合成对象
    @ObservationIgnored
    private var composition: AVMutableComposition?
    
    /// 视频合成指令
    @ObservationIgnored
    private var videoComposition: AVMutableVideoComposition?
    
    /// 播放状态
    @ObservationIgnored
    private var isPlaying = false {
        didSet {
            updatePlayButton()
        }
    }
    
    // MARK: - UI Components
    
    /// 画布裁剪视图
    @ObservationIgnored
    private let cropCanvasView = CropCanvasView()
    
    /// 时间轴视图
    @ObservationIgnored
    private let timelineView = TimelineView()
    
    /// 控制面板
    @ObservationIgnored
    private let controlPanel = UIView()
    
    /// 播放/暂停按钮
    @ObservationIgnored
    private let playButton = UIButton(type: .system)
    
    /// 导入按钮
    @ObservationIgnored
    private let importButton = UIButton(type: .system)
    
    /// 导出按钮
    @ObservationIgnored
    private let exportButton = UIButton(type: .system)
    
    /// 比例选择器
    @ObservationIgnored
    private let ratioSegmentedControl = UISegmentedControl(
        items: CropRatio.allCases.map { $0.rawValue }
    )
    
    /// 时间显示标签
    @ObservationIgnored
    private let timeLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupCallbacks()
        setupPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 开始播放器时间观察
        startTimeObservation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 停止播放器时间观察
        stopTimeObservation()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view.backgroundColor = UIColor.systemBackground
        title = "视频编辑器"
        
        // 添加子视图
        view.addSubview(cropCanvasView)
        view.addSubview(timelineView)
        view.addSubview(controlPanel)
        
        // 设置控制面板
        setupControlPanel()
    }
    
    private func setupControlPanel() {
        controlPanel.backgroundColor = UIColor.systemGray6
        controlPanel.layer.cornerRadius = 12
        
        // 播放按钮
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        // 导入按钮
        importButton.setTitle("导入视频", for: .normal)
        importButton.addTarget(self, action: #selector(importButtonTapped), for: .touchUpInside)
        
        // 导出按钮
        exportButton.setTitle("导出", for: .normal)
        exportButton.addTarget(self, action: #selector(exportButtonTapped), for: .touchUpInside)
        exportButton.isEnabled = false
        
        // 比例选择器
        ratioSegmentedControl.selectedSegmentIndex = 0
        ratioSegmentedControl.addTarget(
            self,
            action: #selector(ratioChanged),
            for: .valueChanged
        )
        
        // 时间标签
        timeLabel.text = "00:00 / 00:00"
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        timeLabel.textAlignment = .center
        
        // 添加到控制面板
        [playButton, importButton, exportButton, ratioSegmentedControl, timeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            controlPanel.addSubview($0)
        }
    }
    
    private func setupConstraints() {
        cropCanvasView.translatesAutoresizingMaskIntoConstraints = false
        timelineView.translatesAutoresizingMaskIntoConstraints = false
        controlPanel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 画布视图
            cropCanvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cropCanvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cropCanvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cropCanvasView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            // 控制面板
            controlPanel.topAnchor.constraint(equalTo: cropCanvasView.bottomAnchor, constant: 8),
            controlPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            controlPanel.heightAnchor.constraint(equalToConstant: 120),
            
            // 时间轴视图
            timelineView.topAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: 8),
            timelineView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timelineView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 控制面板内的约束
            playButton.centerYAnchor.constraint(equalTo: controlPanel.centerYAnchor),
            playButton.leadingAnchor.constraint(equalTo: controlPanel.leadingAnchor, constant: 16),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            timeLabel.centerYAnchor.constraint(equalTo: controlPanel.centerYAnchor),
            timeLabel.centerXAnchor.constraint(equalTo: controlPanel.centerXAnchor),
            
            importButton.topAnchor.constraint(equalTo: controlPanel.topAnchor, constant: 16),
            importButton.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -16),
            
            exportButton.bottomAnchor.constraint(equalTo: controlPanel.bottomAnchor, constant: -16),
            exportButton.trailingAnchor.constraint(equalTo: controlPanel.trailingAnchor, constant: -16),
            
            ratioSegmentedControl.topAnchor.constraint(equalTo: controlPanel.topAnchor, constant: 16),
            ratioSegmentedControl.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 16),
            ratioSegmentedControl.trailingAnchor.constraint(equalTo: importButton.leadingAnchor, constant: -16)
        ])
    }
    
    private func setupCallbacks() {
        // 时间轴回调
        timelineView.onTimeChanged = { [weak self] time in
            self?.seekToTime(time)
        }
        
        timelineView.onClipSelected = { [weak self] clip in
            self?.selectedClip = clip
        }
        
        // 画布回调
        cropCanvasView.onCropRectChanged = { [weak self] cropRect in
            self?.updateVideoComposition()
        }
        
        cropCanvasView.onTransformChanged = { [weak self] transform in
            self?.updateVideoComposition()
        }
    }
    
    private func setupPlayer() {
        cropCanvasView.setPlayer(player)
        
        // 添加播放结束通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    // MARK: - Player Time Observation
    
    @ObservationIgnored
    private var timeObserver: Any?
    
    private func startTimeObservation() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.updateTimeDisplay(time)
        }
    }
    
    private func stopTimeObservation() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func updateTimeDisplay(_ time: CMTime) {
        let currentTime = time.seconds
        let totalDuration = player.currentItem?.duration.seconds ?? 0
        
        timelineView.currentTime = currentTime
        
        let currentTimeString = formatTime(currentTime)
        let totalTimeString = formatTime(totalDuration)
        timeLabel.text = "\(currentTimeString) / \(totalTimeString)"
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Actions
    
    @objc private func playButtonTapped() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    @objc private func importButtonTapped() {
        presentVideoImporter()
    }
    
    @objc private func exportButtonTapped() {
        exportVideo()
    }
    
    @objc private func ratioChanged() {
        let selectedIndex = ratioSegmentedControl.selectedSegmentIndex
        guard selectedIndex < CropRatio.allCases.count else { return }
        
        let ratio = CropRatio.allCases[selectedIndex]
        cropCanvasView.selectedRatio = ratio
    }
    
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        
        // 重置播放位置
        player.seek(to: .zero)
    }
    
    // MARK: - Video Import
    
    /// 对外：打开导入器
    public func startImport() {
        presentVideoImporter()
    }

    /// 对外：直接用指定 URL 打开视频
    public func openVideo(at url: URL) {
        importVideo(from: url)
    }

    private func presentVideoImporter() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        present(picker, animated: true)
    }
    
    private func importVideo(from url: URL) {
        let asset = AVURLAsset(url: url)
        let clip = Clip(asset: asset)
        
        clips.append(clip)
        selectedClip = clip
        exportButton.isEnabled = true
        
        // 更新时间轴总时长
        let totalDuration = clips.reduce(0) { $0 + $1.timeRange.duration.seconds }
        timelineView.totalDuration = max(60, totalDuration)
    }
    
    // MARK: - Video Composition
    
    private func updateComposition() {
        guard !clips.isEmpty else {
            player.replaceCurrentItem(with: nil)
            return
        }
        
        rebuildComposition()
    }
    
    private func rebuildComposition() {
        // 创建新的合成
        let newComposition = AVMutableComposition()
        
        // 添加视频轨道
        guard let videoTrack = newComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            print("无法创建视频轨道")
            return
        }
        
        // 添加音频轨道
        let audioTrack = newComposition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        
        var currentTime = CMTime.zero
        
        for clip in clips {
            // 插入视频
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
            
            // 插入音频
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
        
        composition = newComposition
        
        // 创建播放项
        let playerItem = AVPlayerItem(asset: newComposition)
        player.replaceCurrentItem(with: playerItem)
        
        // 更新视频合成
        updateVideoComposition()
    }
    
    private func updateVideoComposition() {
        guard let composition = composition,
              let selectedClip = selectedClip else { return }
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        videoComposition.renderSize = CGSize(width: 1920, height: 1080) // 默认输出分辨率
        
        // 创建合成指令
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        
        // 创建图层指令
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(
            assetTrack: composition.tracks(withMediaType: .video).first!
        )
        
        // 应用变换和裁剪
        layerInstruction.setTransform(selectedClip.transform, at: .zero)
        layerInstruction.setCropRectangle(selectedClip.cropRect, at: .zero)
        
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        self.videoComposition = videoComposition
        
        // 更新播放器
        if let playerItem = player.currentItem {
            playerItem.videoComposition = videoComposition
        }
    }
    
    // MARK: - Video Export
    
    private func exportVideo() {
        guard let composition = composition else {
            showAlert(title: "错误", message: "没有可导出的视频内容")
            return
        }
        
        // 创建导出会话
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            showAlert(title: "错误", message: "无法创建导出会话")
            return
        }
        
        // 设置导出参数
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mp4
        
        // 创建输出文件URL
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let outputURL = documentsPath.appendingPathComponent("exported_video_\(Date().timeIntervalSince1970).mp4")
        exportSession.outputURL = outputURL
        
        // 显示进度
        let alert = UIAlertController(title: "导出中", message: "正在导出视频...", preferredStyle: .alert)
        present(alert, animated: true)
        
        // 开始导出
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    self?.handleExportResult(exportSession, outputURL: outputURL)
                }
            }
        }
    }
    
    private func handleExportResult(_ session: AVAssetExportSession, outputURL: URL) {
        switch session.status {
        case .completed:
            showAlert(title: "成功", message: "视频导出成功！\n路径: \(outputURL.path)")
            
        case .failed:
            let error = session.error?.localizedDescription ?? "未知错误"
            showAlert(title: "导出失败", message: error)
            
        case .cancelled:
            showAlert(title: "已取消", message: "导出已取消")
            
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func seekToTime(_ time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
    }
    
    private func updatePlayButton() {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private func updateUI() {
        // 更新UI状态
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension EditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.showAlert(title: "导入失败", message: error.localizedDescription)
                }
                return
            }
            
            guard let url = url else { return }
            
            // 复制文件到应用沙盒
            let documentsPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!
            let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                DispatchQueue.main.async {
                    self?.importVideo(from: destinationURL)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showAlert(title: "导入失败", message: error.localizedDescription)
                }
            }
        }
    }
}
