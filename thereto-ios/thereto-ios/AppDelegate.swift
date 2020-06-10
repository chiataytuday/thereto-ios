import UIKit
import Firebase
import FBSDKCoreKit
import AlamofireNetworkActivityLogger

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize firebase
        FirebaseApp.configure()
        
        // Initialize facebook
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //
        NetworkActivityLogger.shared.startLogging()
        NetworkActivityLogger.shared.level = .debug
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = UIColor.themeColor
        window?.rootViewController = SplashVC.instance()
        window?.makeKeyAndVisible()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = ApplicationDelegate.shared.application(app, open: url, options: options)
        
        return handled
    }
    
    func goToSignIn() {
        window?.rootViewController = SignInVC.instance()
        window?.makeKeyAndVisible()
    }
    
    func goToLetterbox() {
        window?.rootViewController = LetterBoxVC.instance()
        window?.makeKeyAndVisible()
    }
    
    func goToFriend() {
        window?.rootViewController = FriendListVC.instance()
        window?.makeKeyAndVisible()
    }
    
    func goToSetup() {
        window?.rootViewController = SetupVC.instance()
        window?.makeKeyAndVisible()
    }
    
    func goToMain() {
        window?.rootViewController = MainVC.instance()
        window?.makeKeyAndVisible()
    }
}
