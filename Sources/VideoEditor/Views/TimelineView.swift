import UIKit
import AVFoundation
import Observation

/// 时间轴视图，负责显示和编辑视频片段的时间范围
@MainActor
final class TimelineView: UIView {
    
    // MARK: - Properties
    
    /// 视频片段数组
    @ObservationIgnored
    private var clips: [Clip] = []
    
    /// 当前播放位置（秒）
    var currentTime: TimeInterval = 0 {
        didSet {
            updatePlayhead()
        }
    }
    
    /// 时间轴的总时长（秒）
    var totalDuration: TimeInterval = 60 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 时间轴缩放比例
    var zoomScale: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 每秒对应的像素数
    var pixelsPerSecond: CGFloat {
        return bounds.width / totalDuration * zoomScale
    }
    
    // MARK: - UI Components
    
    /// 轨道背景层
    @ObservationIgnored
    private let trackLayer = CAShapeLayer()
    
    /// 播放头指示器
    @ObservationIgnored
    private let playheadLayer = CAShapeLayer()
    
    /// 片段视图容器
    @ObservationIgnored
    private var clipViews: [ClipView] = []
    
    // MARK: - Gesture Recognizers
    
    @ObservationIgnored
    private lazy var panGesture = UIPanGestureRecognizer(
        target: self,
        action: #selector(handlePan(_:))
    )
    
    @ObservationIgnored
    private lazy var pinchGesture = UIPinchGestureRecognizer(
        target: self,
        action: #selector(handlePinch(_:))
    )
    
    @ObservationIgnored
    private lazy var tapGesture = UITapGestureRecognizer(
        target: self,
        action: #selector(handleTap(_:))
    )
    
    // MARK: - Callbacks
    
    var onTimeChanged: ((TimeInterval) -> Void)?
    var onClipSelected: ((Clip) -> Void)?
    var onClipsUpdated: (([Clip]) -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.systemBackground
        
        setupLayers()
        setupGestures()
    }
    
    private func setupLayers() {
        // 轨道背景层
        trackLayer.fillColor = UIColor.systemGray6.cgColor
        trackLayer.strokeColor = UIColor.systemGray4.cgColor
        trackLayer.lineWidth = 1.0
        layer.addSublayer(trackLayer)
        
        // 播放头层
        playheadLayer.strokeColor = UIColor.systemRed.cgColor
        playheadLayer.lineWidth = 2.0
        layer.addSublayer(playheadLayer)
    }
    
    private func setupGestures() {
        panGesture.delegate = self
        pinchGesture.delegate = self
        tapGesture.delegate = self
        
        addGestureRecognizer(panGesture)
        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        updateTrackLayer()
        updatePlayhead()
        updateClipViews()
    }
    
    private func updateTrackLayer() {
        let trackHeight: CGFloat = 60
        let trackRect = CGRect(
            x: 0,
            y: (bounds.height - trackHeight) / 2,
            width: bounds.width,
            height: trackHeight
        )
        
        trackLayer.path = UIBezierPath(roundedRect: trackRect, cornerRadius: 8).cgPath
        trackLayer.frame = bounds
    }
    
    private func updatePlayhead() {
        let x = currentTime * pixelsPerSecond
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: 0))
        path.addLine(to: CGPoint(x: x, y: bounds.height))
        
        playheadLayer.path = path.cgPath
        playheadLayer.frame = bounds
    }
    
    // MARK: - Clip Management
    
    func setClips(_ clips: [Clip]) {
        self.clips = clips
        updateClipViews()
    }
    
    private func updateClipViews() {
        // 移除旧的片段视图
        clipViews.forEach { $0.removeFromSuperview() }
        clipViews.removeAll()
        
        // 创建新的片段视图
        for clip in clips {
            let clipView = ClipView(clip: clip)
            clipView.onTapped = { [weak self] in
                self?.selectClip(clip)
            }
            
            addSubview(clipView)
            clipViews.append(clipView)
            
            // 设置片段视图的位置和大小
            layoutClipView(clipView, for: clip)
        }
    }
    
    private func layoutClipView(_ clipView: ClipView, for clip: Clip) {
        let startX = clip.startTime.seconds * pixelsPerSecond
        let width = clip.timeRange.duration.seconds * pixelsPerSecond
        let height: CGFloat = 50
        let y = (bounds.height - height) / 2
        
        clipView.frame = CGRect(x: startX, y: y, width: width, height: height)
    }
    
    private func selectClip(_ clip: Clip) {
        // 取消所有片段的选中状态
        clips.forEach { $0.isSelected = false }
        
        // 选中当前片段
        clip.isSelected = true
        
        // 更新视图
        updateClipViews()
        
        // 通知回调
        onClipSelected?(clip)
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            // 检查是否点击在播放头上
            let playheadX = currentTime * pixelsPerSecond
            if abs(location.x - playheadX) < 20 {
                // 开始拖拽播放头
                break
            }
            
        case .changed:
            // 更新播放头位置
            let newTime = max(0, min(totalDuration, location.x / pixelsPerSecond))
            currentTime = newTime
            onTimeChanged?(newTime)
            
        case .ended, .cancelled:
            break
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            break
            
        case .changed:
            let newScale = max(0.5, min(5.0, zoomScale * gesture.scale))
            zoomScale = newScale
            gesture.scale = 1.0
            
        case .ended, .cancelled:
            break
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // 检查是否点击在某个片段上
        for clipView in clipViews {
            if clipView.frame.contains(location) {
                if let clip = clips.first(where: { $0.id == clipView.clip.id }) {
                    selectClip(clip)
                }
                return
            }
        }
        
        // 如果没有点击在片段上，则移动播放头
        let newTime = max(0, min(totalDuration, location.x / pixelsPerSecond))
        currentTime = newTime
        onTimeChanged?(newTime)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TimelineView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer is UIPinchGestureRecognizer || 
               otherGestureRecognizer is UIPinchGestureRecognizer
    }
}

// MARK: - ClipView

@MainActor
private final class ClipView: UIView {
    let clip: Clip
    var onTapped: (() -> Void)?
    
    private let titleLabel = UILabel()
    
    init(clip: Clip) {
        self.clip = clip
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = clip.isSelected ? UIColor.systemBlue : UIColor.systemGray3
        layer.cornerRadius = 4
        layer.borderWidth = clip.isSelected ? 2 : 0
        layer.borderColor = UIColor.systemBlue.cgColor
        
        titleLabel.text = "视频片段"
        titleLabel.textColor = UIColor.label
        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textAlignment = .center
        
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
        onTapped?()
    }
}
