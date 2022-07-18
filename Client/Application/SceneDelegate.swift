import Shared
import Storage
import AVFoundation
import XCGLogger
import MessageUI
import SDWebImage
import LocalAuthentication
import SyncTelemetry
import Sync
import CoreSpotlight
import UserNotifications
import Account


@available (iOS 13.0, *)
class SceneDelegate : UIResponder, UIWindowSceneDelegate
{
    var window : UIWindow?
    var profile : Profile!
    var browserViewController : BrowserViewController!
    var rootViewController: UIViewController!
    var tabManager : TabManager!
    
    private func setupRootViewController() {
        if !LegacyThemeManager.instance.systemThemeIsOn {
            window?.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
        }

        browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.edgesForExtendedLayout = []

        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        rootViewController = navigationController

        window!.rootViewController = rootViewController
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let profile = (UIApplication.shared.delegate as! AppDelegate).profile
        
        self.profile = profile
        let imageStore = DiskImageStore(files: profile.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)

        var uuid : String? = nil
        if let userInfo = session.userInfo {
            uuid = userInfo["sceneID"] as? String
        }
        
        window = UIWindow.init(windowScene: scene as! UIWindowScene)
        window?.windowScene = scene as? UIWindowScene
        window?.backgroundColor = UIColor.theme.browser.background
        var tab : Tab? = nil
        
        var isPrivate : Bool = false
        var url : URL? = nil
        if let userActivity = connectionOptions.userActivities.first {
            if let tabUUID = userActivity.userInfo?["id"] as? String {
            
                isPrivate = userActivity.userInfo?["isPrivate"] as? Bool ?? false
                for scene in UIApplication.shared.connectedScenes {
                    if let delegate = (scene as? UIWindowScene)?.delegate, let sceneDelegate = delegate as? SceneDelegate, sceneDelegate.tabManager != nil {
                        tab = sceneDelegate.tabManager.getTabForUUID(uuid: tabUUID)
                        if tab != nil {
                            break
                        }
                    }
                    
                }
            } else {
                url = userActivity.webpageURL
            }
        }
        self.tabManager = TabManager(profile: profile, imageStore: imageStore, uuid: uuid ?? UUID().uuidString)
        
//        tabManager.bvc = browserViewController
        if session.userInfo == nil {
            session.userInfo = [:]
        }
        session.userInfo?["sceneID"] = self.tabManager.sceneUUID!
      
        self.tabManager.isNewWindow = tab == nil && connectionOptions.urlContexts.isEmpty
        setupRootViewController()
        if let tab = tab {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                
                tab.browserViewController?.tabManager.removeTab(tab)
                tab.browserViewController = self.browserViewController
                self.tabManager.moveTab(tab, toIndex: 0, replaceTab: true)
                self.browserViewController.switchToPrivacyMode(isPrivate: isPrivate)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !connectionOptions.urlContexts.isEmpty {
                self.scene(scene, openURLContexts: connectionOptions.urlContexts)
            } else if let url = url {
                self.tabManager.addTabsForURLs([url], zombie: false)
            }
        }
        window?.makeKeyAndVisible()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = QuickActions.sharedInstance.handleShortCutItem(shortcutItem, withBrowserViewController: self.browserViewController)

        completionHandler(handledShortCutItem)
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
            
        guard let bvc = browserViewController else {
            return
        }
                if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
                    bvc.openBlankNewTab(focusLocationField: false)
                    return
                }

            // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
            // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
            if let url = userActivity.webpageURL {
                let query = url.getQuery()

                // Check for fxa sign-in code and launch the login screen directly
                if query["signin"] != nil {
                    // bvc.launchFxAFromDeeplinkURL(url) // Was using Adjust. Consider hooking up again when replacement system in-place.
                    return
                }

                // Per Adjust documenation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
                // it is recommended that links contain the `deep_link` query parameter. This link will also
                // be url encoded.
                if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                    bvc.switchToTabForURLOrOpen(url)
                    return
                }

                bvc.switchToTabForURLOrOpen(url)
                return
            }

            // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
            // open a new one.
            if userActivity.activityType == CSSearchableItemActionType {
                if let userInfo = userActivity.userInfo,
                    let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                    let url = URL(string: urlString) {
                    bvc.switchToTabForURLOrOpen(url)
                    return
                }
            }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let context = URLContexts.first {
            let url = context.url
            guard let routerpath = NavigationPath(url: url) else { return }

            if let _ = profile.prefs.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) {
                profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)
                var object = TelemetryWrapper.EventObject.url
                if case .text = routerpath {
                    object = .searchText
                }
                TelemetryWrapper.recordEvent(category: .appExtensionAction, method: .applicationOpenUrl, object: object)
            }

            DispatchQueue.main.async {
                NavigationPath.handle(nav: routerpath, with: self.browserViewController)
            }
            return
        }
    }
    

    
    func sceneDidBecomeActive(_ scene: UIScene) {
        
        browserViewController.firefoxHomeViewController?.reloadAll()
    }
    
}
