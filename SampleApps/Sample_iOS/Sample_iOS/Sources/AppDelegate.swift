import FoundationExtension
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? {
        get {
            _window
        }
        set {
            _window = newValue ?? UIWindow(frame: UIScreen.main.bounds)
        }
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _window.rootViewController = ViewController()
        _window.makeKeyAndVisible()
        return true
    }

    @objc
    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    // MARK: Private

    private lazy var _window: UIWindow = UIWindow(frame: UIScreen.main.bounds)
}

