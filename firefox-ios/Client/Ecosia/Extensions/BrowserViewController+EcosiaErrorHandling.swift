// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI
import Common
import Ecosia

/// Container view to host SwiftUI error toast in UIKit BrowserViewController
@available(iOS 16.0, *)
class EcosiaErrorToastContainerView: UIView {
    private var hostingController: UIHostingController<AnyView>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(
        subtitle: String,
        windowUUID: WindowUUID,
        in viewController: UIViewController,
        onDismiss: @escaping () -> Void
    ) {
        let toastView = EcosiaErrorToast(
            subtitle: subtitle,
            windowUUID: windowUUID,
            onDismiss: { [weak self] in
                self?.removeFromSuperview()
                onDismiss()
            }
        )

        let hostingController = UIHostingController(rootView: AnyView(toastView))
        hostingController.view.backgroundColor = .clear
        self.hostingController = hostingController

        viewController.addChild(hostingController)
        addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        hostingController.didMove(toParent: viewController)
    }
}

@available(iOS 16.0, *)
extension BrowserViewController {

    /// Shows an error toast for auth flow failures
    /// - Parameters:
    ///   - isLogin: Whether this was a login (true) or logout (false) error
    func showAuthFlowErrorToast(isLogin: Bool, errorMessage: String? = nil) {
        // Remove any existing error toast
        view.subviews
            .compactMap { $0 as? EcosiaErrorToastContainerView }
            .forEach { $0.removeFromSuperview() }

        var subtitle = isLogin
            ? String.localized(.signInErrorMessage)
            : String.localized(.signOutErrorMessage)

        #if MOZ_CHANNEL_BETA
        if let errorMessage {
            subtitle += "Additional details: \(errorMessage)"
        }
        #endif

        let container = EcosiaErrorToastContainerView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomContentStackView.topAnchor)
        ])

        container.show(
            subtitle: subtitle,
            windowUUID: windowUUID,
            in: self,
            onDismiss: {}
        )
    }
}
