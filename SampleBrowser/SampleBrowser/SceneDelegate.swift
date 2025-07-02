// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebEngine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tempVC = UIViewController()
        tempVC.view.backgroundColor = .systemBackground

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = tempVC
        window.makeKeyAndVisible()

        Task {
            let engineProvider = await EngineProviderManager.shared.getProvider()
            let windowUUID = UUID()
            let rootVC = RootViewController(engineProvider: engineProvider, windowUUID: windowUUID)

            await MainActor.run {
                window.rootViewController = Container(rootController: rootVC)

                let themeManager: ThemeManager = AppContainer.shared.resolve()
                themeManager.setWindow(window, for: windowUUID)
                themeManager.setSystemTheme(isOn: true)
            }
        }
    }
}

import SummarizeKit

class Container: UIViewController {
    let rootController: RootViewController
    let controller = SummarizeController()

    init(rootController: RootViewController) {
        self.rootController = rootController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        rootController.onSummarize = {
            self.summarizePage()
        }
        super.viewDidLoad()
        rootController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootController.view)
        rootController.view.pinToSuperview()
    }

    func summarizePage() {
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        addChild(controller)
        controller.view.pinToSuperview()
        controller.didMove(toParent: self)
        controller.view.layoutIfNeeded()

        controller.animateGradient()

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 0.3) {
                self.rootController.view.layer.cornerRadius = 55.0
                self.rootController.view.transform = CGAffineTransform(translationX: 0.0, y: 400.0)
            } completion: { _ in
                self.controller.animateTransition()
            }
        }
    }
}
