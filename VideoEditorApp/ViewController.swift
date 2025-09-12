import UIKit

class ViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let startButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 标题设置
        titleLabel.text = "视频编辑器"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 按钮设置
        startButton.setTitle("选择视频开始", for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 12
        startButton.layer.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        startButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        startButton.layer.shadowRadius = 8
        startButton.layer.shadowOpacity = 1
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        
        // 添加到视图
        view.addSubview(titleLabel)
        view.addSubview(startButton)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func startButtonTapped() {
        let sheet = UIAlertController(title: "选择导入方式", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "从相册选择视频", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let editorVC = EditorViewController()
            let nav = UINavigationController(rootViewController: editorVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true) {
                editorVC.startImport()
            }
        }))
        sheet.addAction(UIAlertAction(title: "从文件选择视频", style: .default, handler: { [weak self] _ in
            self?.presentDocumentPicker()
        }))
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    private func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .mpeg4Movie], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let editorVC = EditorViewController()
        let nav = UINavigationController(rootViewController: editorVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true) {
            editorVC.openVideo(at: url)
        }
    }
}
