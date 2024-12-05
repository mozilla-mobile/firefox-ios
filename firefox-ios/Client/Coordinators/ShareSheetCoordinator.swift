// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

class ShareSheetCoordinator: BaseCoordinator,
                             DevicePickerViewControllerDelegate,
                             InstructionsViewDelegate,
                             JSPromptAlertControllerDelegate {
    // MARK: - Properties

    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private let profile: Profile
    private let alertContainer: UIView
    private weak var parentCoordinator: ParentCoordinatorDelegate?
    private var windowUUID: WindowUUID { return tabManager.windowUUID }

    // MARK: - Initializers

    init(
        alertContainer: UIView,
        router: Router,
        profile: Profile,
        parentCoordinator: ParentCoordinatorDelegate? = nil,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        tabManager: TabManager
    ) {
        self.alertContainer = alertContainer
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - Methods

    /// Presents the share sheet from the source view
    func start(
        shareType: ShareType,
        shareMessage: ShareMessage?,
        sourceView: UIView,
        sourceRect: CGRect? = nil,
        popoverArrowDirection: UIPopoverArrowDirection = .up
    ) {
        let controller = ShareManager.createActivityViewController(
            shareType: shareType,
            shareMessage: shareMessage,
            completionHandler: { [weak self] completed, activityType in
                guard let self else { return }

                self.handleShareSheetCompletion(
                    activityType: activityType,
                    shareType: shareType,
                    relatedTab: self.tabManager.selectedTab
                )
            }
        )

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect ?? sourceView.bounds
            popoverPresentationController.permittedArrowDirections = popoverArrowDirection
        }

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)

        if let presentedViewController = router.navigationController.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.router.present(controller)
            }
        } else {
            router.present(controller)
        }
    }

    private func handleShareSheetCompletion(
        activityType: UIActivity.ActivityType?,
        shareType: ShareType,
        relatedTab: Tab?
    ) {
        // NOTE: didFinish will be called on each of these code paths to properly dismiss the share sheet.
        switch activityType {
        case CustomActivityAction.sendToDevice.actionType:
            // Can only reach here for non-file shares
            showSendToDevice(url: shareType.wrappedURL, relatedTab: relatedTab)

        default:
            // FIXME: FXIOS-10334 It's mysterious that we are calling this in the share coordinator. It may not be necessary,
            // but this JS alert code is very brittle right now so let's not touch it until FXIOS-10334 is underway.
            dequeueNotShownJSAlert()
        }
    }

    func dismiss() {
        parentCoordinator?.didFinish(from: self)
    }

    private func showSendToDevice(url: URL, relatedTab: Tab?) {
        let shareItem: ShareItem
        if let relatedTab, let url = relatedTab.canonicalURL?.displayURL {
            shareItem = ShareItem(url: url.absoluteString, title: relatedTab.title)
        } else {
            shareItem = ShareItem(url: url.absoluteString, title: nil)
        }

        let themeColors = themeManager.getCurrentTheme(for: windowUUID).colors
        let colors = SendToDeviceHelper.Colors(defaultBackground: themeColors.layer1,
                                               textColor: themeColors.textPrimary,
                                               iconColor: themeColors.iconDisabled)

        let sendToDeviceHelper = SendToDeviceHelper(
            shareItem: shareItem,
            profile: profile,
            colors: colors,
            delegate: self
        )
        let viewController = sendToDeviceHelper.initialViewController()

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sendToDevice)
        router.present(viewController)
    }

    private func dequeueNotShownJSAlert() {
        guard let alertInfo = tabManager.selectedTab?.dequeueJavascriptAlertPrompt() else {
            parentCoordinator?.didFinish(from: self)
            return
        }

        // Will call `dequeueNotShownJSAlert` again when finished via JSPromptAlertControllerDelegate delegate method
        let alertController = alertInfo.alertController()
        alertController.delegate = self
        router.present(alertController)
    }

    // MARK: DevicePickerViewControllerDelegate

    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        router.dismiss()
        parentCoordinator?.didFinish(from: self)
    }

    func devicePickerViewController(
        _ devicePickerViewController: DevicePickerViewController,
        didPickDevices devices: [RemoteDevice]
    ) {
        guard let shareItem = devicePickerViewController.shareItem else {
            router.dismiss()
            parentCoordinator?.didFinish(from: self)
            return
        }

        guard shareItem.isShareable else {
            let alert = UIAlertController(
                title: .SendToErrorTitle,
                message: .SendToErrorMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: .SendToErrorOKButton,
                style: .default
            ) { [weak self] _ in
                self?.router.dismiss()
            })
            router.present(alert, animated: true) { [weak self] in
                guard let self = self else { return }
                self.parentCoordinator?.didFinish(from: self)
            }
            return
        }

        profile.sendItem(shareItem, toDevices: devices).uponQueue(.main) { [weak self] _ in
            guard let self = self else { return }
            self.router.dismiss()
            self.parentCoordinator?.didFinish(from: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SimpleToast().showAlertWithText(.LegacyAppMenu.AppMenuTabSentConfirmMessage,
                                                bottomContainer: self.alertContainer,
                                                theme: self.themeManager.getCurrentTheme(for: self.windowUUID))
            }
        }
    }

    // MARK: - InstructionViewDelegate

    func dismissInstructionsView() {
        router.dismiss()
        parentCoordinator?.didFinish(from: self)
    }

    // MARK: - JSPromptAlertControllerDelegate

    func promptAlertControllerDidDismiss(_ alertController: JSPromptAlertController) {
        dequeueNotShownJSAlert()
    }
}
