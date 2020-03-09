import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let window = UIWindow(frame: UIScreen.main.bounds)
        (UIApplication.shared.delegate as! AppDelegate).window = window
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()

        return true
    }

}

