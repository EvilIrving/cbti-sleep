import UIKit
import VideoEditor

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // 检查设备是否支持视频编辑
        if VideoEditor.isVideoEditingSupported() {
            // 创建主视图控制器
            let mainViewController = MainViewController()
            let navigationController = UINavigationController(rootViewController: mainViewController)
            
            window?.rootViewController = navigationController
        } else {
            // 显示不支持的设备提示
            let alertController = UIAlertController(
                title: "设备不支持",
                message: "当前设备不支持视频编辑功能",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "确定", style: .default))
            
            let rootViewController = UIViewController()
            rootViewController.view.backgroundColor = UIColor.systemBackground
            window?.rootViewController = rootViewController
            
            DispatchQueue.main.async {
                rootViewController.present(alertController, animated: true)
            }
        }
        
        window?.makeKeyAndVisible()
    }
}

// MARK: - Main View Controller

class MainViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let startEditingButton = UIButton(type: .system)
    private let infoStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
    }
    
    private func setupView() {
        view.backgroundColor = UIColor.systemBackground
        title = "视频编辑器示例"
        
        // 标题
        titleLabel.text = "VideoEditor"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.label
        
        // 副标题
        subtitleLabel.text = "基于Swift和AVFoundation的高性能视频编辑器"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.numberOfLines = 0
        
        // 开始编辑按钮
        startEditingButton.setTitle("开始编辑视频", for: .normal)
        startEditingButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        startEditingButton.backgroundColor = UIColor.systemBlue
        startEditingButton.setTitleColor(.white, for: .normal)
        startEditingButton.layer.cornerRadius = 12
        startEditingButton.addTarget(self, action: #selector(startEditingTapped), for: .touchUpInside)
        
        // 信息堆栈视图
        infoStackView.axis = .vertical
        infoStackView.spacing = 8
        infoStackView.alignment = .leading
        
        // 添加功能信息
        let features = [
            "✓ 时间轴剪辑与合成",
            "✓ 画布画面裁剪",
            "✓ 实时预览",
            "✓ 多种导出格式",
            "✓ 手势操作支持",
            "✓ HDR视频处理"
        ]
        
        for feature in features {
            let label = UILabel()
            label.text = feature
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.textColor = UIColor.label
            infoStackView.addArrangedSubview(label)
        }
        
        // 版本信息
        let versionLabel = UILabel()
        versionLabel.text = "版本: \(VideoEditor.version)"
        versionLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        versionLabel.textColor = UIColor.tertiaryLabel
        versionLabel.textAlignment = .center
        
        // 添加到视图
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(startEditingButton)
        view.addSubview(infoStackView)
        view.addSubview(versionLabel)
        
        // 设置约束
        [titleLabel, subtitleLabel, startEditingButton, infoStackView, versionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 标题
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            
            // 副标题
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // 开始编辑按钮
            startEditingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startEditingButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            startEditingButton.widthAnchor.constraint(equalToConstant: 200),
            startEditingButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 功能信息
            infoStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoStackView.topAnchor.constraint(equalTo: startEditingButton.bottomAnchor, constant: 60),
            
            // 版本信息
            view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func startEditingTapped() {
        // 创建并展示视频编辑器
        VideoEditor.shared.presentEditor(from: self)
    }
}
