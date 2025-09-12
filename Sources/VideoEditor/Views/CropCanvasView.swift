import UIKit
import AVFoundation
import Observation

/// 画布裁剪视图，负责显示视频预览和裁剪框
@MainActor
final class CropCanvasView: UIView {
    
    // MARK: - Properties
    
    /// 当前编辑的视频片段
    private var currentClip: Clip? {
        didSet {
            updateVideoLayer()
            updateCropRect()
        }
    }
    
    /// 当前选择的裁剪比例
    var selectedRatio: CropRatio = .original {
        didSet {
            updateCropRectForRatio()
        }
    }
    
    /// 裁剪框是否可见
    var isCropRectVisible: Bool = true {
        didSet {
            cropRectLayer.isHidden = !isCropRectVisible
            cornerHandles.forEach { $0.isHidden = !isCropRectVisible }
        }
    }
    
    // MARK: - UI Components
    
    /// 视频播放层
    @ObservationIgnored
    private let videoLayer = AVPlayerLayer()
    
    /// 裁剪框层
    @ObservationIgnored
    private let cropRectLayer = CAShapeLayer()
    
    /// 遮罩层（裁剪框外的半透明区域）
    @ObservationIgnored
    private let maskLayer = CAShapeLayer()
    
    /// 比例参考线层
    @ObservationIgnored
    private var ratioLayers: [CAShapeLayer] = []
    
    /// 裁剪框角落控制点
    @ObservationIgnored
    private var cornerHandles: [UIView] = []
    
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
    
    // MARK: - Callbacks
    
    var onCropRectChanged: ((CGRect) -> Void)?
    var onTransformChanged: ((CGAffineTransform) -> Void)?
    
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
        backgroundColor = UIColor.black
        
        setupLayers()
        setupGestures()
        setupCornerHandles()
    }
    
    private func setupLayers() {
        // 视频播放层
        videoLayer.videoGravity = .resizeAspect
        videoLayer.frame = bounds
        layer.addSublayer(videoLayer)
        
        // 遮罩层
        maskLayer.fillColor = UIColor.black.withAlphaComponent(0.5).cgColor
        maskLayer.fillRule = .evenOdd
        layer.addSublayer(maskLayer)
        
        // 裁剪框层
        cropRectLayer.fillColor = UIColor.clear.cgColor
        cropRectLayer.strokeColor = UIColor.white.cgColor
        cropRectLayer.lineWidth = 2.0
        layer.addSublayer(cropRectLayer)
        
        // 创建比例参考线
        createRatioLayers()
    }
    
    private func createRatioLayers() {
        for ratio in CropRatio.allCases {
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = UIColor.white.withAlphaComponent(0.5).cgColor
            layer.lineWidth = 1.0
            layer.lineDashPattern = [4, 4]
            layer.isHidden = true
            
            self.layer.addSublayer(layer)
            ratioLayers.append(layer)
        }
    }
    
    private func setupCornerHandles() {
        for _ in 0..<4 {
            let handle = UIView()
            handle.backgroundColor = UIColor.white
            handle.layer.borderColor = UIColor.systemBlue.cgColor
            handle.layer.borderWidth = 2
            handle.layer.cornerRadius = 6
            handle.frame = CGRect(x: 0, y: 0, width: 12, height: 12)
            handle.isHidden = true
            
            addSubview(handle)
            cornerHandles.append(handle)
        }
    }
    
    private func setupGestures() {
        panGesture.delegate = self
        pinchGesture.delegate = self
        
        addGestureRecognizer(panGesture)
        addGestureRecognizer(pinchGesture)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoLayer.frame = bounds
        updateCropRect()
        updateMaskLayer()
        updateRatioLayers()
    }
    
    // MARK: - Public Methods
    
    func setClip(_ clip: Clip?) {
        currentClip = clip
    }
    
    func setPlayer(_ player: AVPlayer?) {
        videoLayer.player = player
    }
    
    func showRatioGuides(for ratio: CropRatio) {
        // 隐藏所有参考线
        ratioLayers.forEach { $0.isHidden = true }
        
        // 显示指定比例的参考线
        if let index = CropRatio.allCases.firstIndex(of: ratio) {
            ratioLayers[index].isHidden = false
        }
    }
    
    func hideRatioGuides() {
        ratioLayers.forEach { $0.isHidden = true }
    }
    
    // MARK: - Private Methods
    
    private func updateVideoLayer() {
        guard let clip = currentClip else { return }
        
        // 应用变换
        videoLayer.setAffineTransform(clip.transform)
    }
    
    private func updateCropRect() {
        guard let clip = currentClip else {
            cropRectLayer.path = nil
            return
        }
        
        let cropRect = denormalizedCropRect(clip.cropRect)
        let path = UIBezierPath(rect: cropRect)
        cropRectLayer.path = path.cgPath
        
        updateCornerHandles(for: cropRect)
    }
    
    private func updateCornerHandles(for rect: CGRect) {
        guard cornerHandles.count == 4 else { return }
        
        let positions = [
            CGPoint(x: rect.minX - 6, y: rect.minY - 6), // 左上
            CGPoint(x: rect.maxX - 6, y: rect.minY - 6), // 右上
            CGPoint(x: rect.maxX - 6, y: rect.maxY - 6), // 右下
            CGPoint(x: rect.minX - 6, y: rect.maxY - 6)  // 左下
        ]
        
        for (index, handle) in cornerHandles.enumerated() {
            handle.center = positions[index]
            handle.isHidden = !isCropRectVisible
        }
    }
    
    private func updateMaskLayer() {
        guard let clip = currentClip else {
            maskLayer.path = nil
            return
        }
        
        let cropRect = denormalizedCropRect(clip.cropRect)
        let maskPath = UIBezierPath(rect: bounds)
        let cropPath = UIBezierPath(rect: cropRect)
        maskPath.append(cropPath.reversing())
        
        maskLayer.path = maskPath.cgPath
    }
    
    private func updateRatioLayers() {
        for (index, ratio) in CropRatio.allCases.enumerated() {
            guard index < ratioLayers.count else { continue }
            
            let rect = ratio.calculateRect(in: bounds.size)
            let path = UIBezierPath(rect: rect)
            ratioLayers[index].path = path.cgPath
        }
    }
    
    private func updateCropRectForRatio() {
        guard let clip = currentClip else { return }
        
        let rect = selectedRatio.calculateRect(in: bounds.size)
        let normalizedRect = normalizedCropRect(rect)
        
        clip.cropRect = normalizedRect
        updateCropRect()
        updateMaskLayer()
        
        onCropRectChanged?(normalizedRect)
    }
    
    // MARK: - Coordinate Conversion
    
    private func normalizedCropRect(_ rect: CGRect) -> CGRect {
        return CGRect(
            x: rect.origin.x / bounds.width,
            y: rect.origin.y / bounds.height,
            width: rect.size.width / bounds.width,
            height: rect.size.height / bounds.height
        )
    }
    
    private func denormalizedCropRect(_ normalizedRect: CGRect) -> CGRect {
        return CGRect(
            x: normalizedRect.origin.x * bounds.width,
            y: normalizedRect.origin.y * bounds.height,
            width: normalizedRect.size.width * bounds.width,
            height: normalizedRect.size.height * bounds.height
        )
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let clip = currentClip else { return }
        
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            break
            
        case .changed:
            // 更新裁剪框位置
            var newCropRect = clip.cropRect
            newCropRect.origin.x += translation.x / bounds.width
            newCropRect.origin.y += translation.y / bounds.height
            
            // 限制边界
            newCropRect.origin.x = max(0, min(1 - newCropRect.width, newCropRect.origin.x))
            newCropRect.origin.y = max(0, min(1 - newCropRect.height, newCropRect.origin.y))
            
            clip.cropRect = newCropRect
            updateCropRect()
            updateMaskLayer()
            
            gesture.setTranslation(.zero, in: self)
            
        case .ended:
            onCropRectChanged?(clip.cropRect)
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let clip = currentClip else { return }
        
        switch gesture.state {
        case .began:
            break
            
        case .changed:
            let scale = gesture.scale
            
            // 更新变换矩阵
            clip.transform = clip.transform.scaledBy(x: scale, y: scale)
            updateVideoLayer()
            
            gesture.scale = 1.0
            
        case .ended:
            onTransformChanged?(clip.transform)
            
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension CropCanvasView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            // 只有在裁剪框内才允许拖拽
            let location = gestureRecognizer.location(in: self)
            guard let clip = currentClip else { return false }
            
            let cropRect = denormalizedCropRect(clip.cropRect)
            return cropRect.contains(location)
        }
        
        return true
    }
}
