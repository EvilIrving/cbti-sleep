import UIKit
import VideoEditor

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 配置视频编辑器
        let configuration = VideoEditorConfiguration(
            maxVideoDuration: 600, // 10分钟
            enableHardwareAcceleration: true,
            enableHDRSupport: true,
            defaultExportQuality: .highQuality,
            showDebugInfo: false,
            theme: .system
        )
        
        VideoEditor.shared.configure(with: configuration)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
