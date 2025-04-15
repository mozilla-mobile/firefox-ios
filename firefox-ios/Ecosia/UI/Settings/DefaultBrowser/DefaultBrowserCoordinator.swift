// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Lottie
import Common

public struct DefaultBrowserCoordinator {
    let navigationController: UINavigationController
    let style: InstructionStepsViewStyle

    public init(navigationController: UINavigationController,
                style: InstructionStepsViewStyle) {
        self.navigationController = navigationController
        self.style = style
    }

    public func showDetailView(from analyticsLabel: Analytics.Label.DefaultBrowser) {
        let steps = [
            InstructionStep(text: .defaultBrowserCardDetailInstructionStep1),
            InstructionStep(text: .defaultBrowserCardDetailInstructionStep2),
            InstructionStep(text: .defaultBrowserCardDetailInstructionStep3)
        ]

        let lottieViewYOffset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 40 : 18

        let view = InstructionStepsView(
            title: .defaultBrowserCardDetailTitle,
            steps: steps,
            buttonTitle: .defaultBrowserCardDetailButton,
            onButtonTap: {
                Analytics.shared.defaultBrowserSettingsOpenNativeSettingsVia(analyticsLabel)
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL, options: [:])
                }
            },
            style: style
        ) {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    LottieView {
                        try await DotLottieFile.named("default_browser_setup_animation", bundle: .ecosia)
                    }
                    .configuration(LottieConfiguration(renderingEngine: .mainThread))
                    .looping()
                    .offset(y: lottieViewYOffset)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geometry.size.width)
                    .clipped()
                }
            }
        }
        .onAppear {
            Analytics.shared.defaultBrowserSettingsShowsDetailViewVia(analyticsLabel)
        }
        .onDisappear {
            Analytics.shared.defaultBrowserSettingsDismissDetailViewVia(analyticsLabel)
        }

        let hostingController = UIHostingController(rootView: view)
        hostingController.title = .localized(.defaultBrowserSettingTitle)
        hostingController.navigationItem.largeTitleDisplayMode = .never
        let doneHandler = DetailViewDoneHandler {
            self.navigationController.dismiss(animated: true)
        }
        objc_setAssociatedObject(hostingController, "detailViewDoneHandler", doneHandler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        hostingController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: .localized(.done),
            style: .done,
            target: doneHandler,
            action: #selector(DetailViewDoneHandler.handleDone)
        )
        navigationController.pushViewController(hostingController, animated: true)
    }
}

extension DefaultBrowserCoordinator {

    public static func makeDefaultCoordinatorAndShowDetailViewFrom(_ navigationController: UINavigationController?,
                                                                   analyticsLabel: Analytics.Label.DefaultBrowser,
                                                                   topViewContentBackground: Color,
                                                                   with theme: Theme) {

        guard let navigationController = navigationController else { return }

        let style = InstructionStepsViewStyle(
            backgroundPrimaryColor: Color(theme.colors.ecosia.backgroundSecondary),
            topContentBackgroundColor: topViewContentBackground,
            stepsBackgroundColor: Color(theme.colors.ecosia.backgroundPrimary),
            textPrimaryColor: Color(theme.colors.ecosia.textPrimary),
            textSecondaryColor: Color(theme.colors.ecosia.textSecondary),
            buttonBackgroundColor: Color(theme.colors.ecosia.buttonBackgroundPrimary),
            buttonTextColor: Color(theme.colors.ecosia.textInversePrimary),
            stepRowStyle: StepRowStyle(
                stepNumberColor: Color(theme.colors.ecosia.textPrimary),
                stepNumberBackgroundColor: Color(theme.colors.ecosia.backgroundSecondary),
                stepTextColor: Color(theme.colors.ecosia.textPrimary)
            )
        )

        let coordinator = DefaultBrowserCoordinator(navigationController: navigationController,
                                                    style: style)
        coordinator.showDetailView(from: analyticsLabel)
    }
}

final class DetailViewDoneHandler: NSObject {
    let onDone: () -> Void
    init(onDone: @escaping () -> Void) {
        self.onDone = onDone
    }

    @objc func handleDone() {
        onDone()
    }
}
