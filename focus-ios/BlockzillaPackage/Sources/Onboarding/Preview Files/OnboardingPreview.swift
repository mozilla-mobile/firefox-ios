/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct OnboardingPreview: View {
    var body: some View {
        ViewControllerContainerView(
            controller:
                OnboardingViewController(
                    config: .demo,
                    dismissOnboardingScreen: {})
        )
    }
}

struct OnboardingPreview_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPreview()
    }
}

struct ViewControllerContainerView<Controller: UIViewController>: UIViewControllerRepresentable {
    let controller: Controller

    init(controller: Controller) {
        self.controller = controller
    }

    func makeUIViewController(context: Context) -> Controller {
        return controller
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {

    }
}

fileprivate extension OnboardingText {
    static let demo = OnboardingText.init(
        onboardingTitle: "Welcome to Firefox",
        onboardingSubtitle: "Take your private browsing to the next level.",
        instructions:
            [
                .init(title: "More than just incognito", subtitle: "Focus is a dedicated privacy browser with tracking protection and content blocking.", image: .privateMode),
                .init(title: "More than just incognito", subtitle: "Focus is a dedicated privacy browser with tracking protection and content blocking.", image: .privateMode),
                .init(title: "More than just incognito", subtitle: "Focus is a dedicated privacy browser with tracking protection and content blocking.", image: .privateMode),
                .init(title: "More than just incognito", subtitle: "Focus is a dedicated privacy browser with tracking protection and content blocking.", image: .privateMode)
            ],
        onboardingButtonTitle: "start"
    )
}
