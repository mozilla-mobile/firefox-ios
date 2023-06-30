// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

// TODO: unit tests, dequeue not shown js alert implemenatation
class ShareExtensionCoordinator: BaseCoordinator {
    // MARK: - Properties

    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private let profile: Profile
    private let alertContainer: UIView
    private weak var parentCoordinator: ParentCoordinatorDelegate?

    // MARK: - Initializers

    init(
        alertContainer: UIView,
        router: Router,
        profile: Profile,
        parentCoordinator: ParentCoordinatorDelegate? = nil,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        tabManager: TabManager = AppContainer.shared.resolve()
    ) {
        self.alertContainer = alertContainer
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - Methods

    /// Presents the Share extension from the source view
    func start(url: URL, sourceView: UIView, popoverArrowDirection: UIPopoverArrowDirection = .up) {
        let shareExtension = ShareExtensionHelper(url: url, tab: tabManager.selectedTab)
        let controller = shareExtension.createActivityViewController { [weak self] completed, activityType in
            guard let self = self else { return }
            self.handleShareExtensionCompletion(activityType: activityType)
        }
        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = popoverArrowDirection
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
        router.present(controller)
    }

    private func handleShareExtensionCompletion(activityType: UIActivity.ActivityType?) {
        switch activityType {
        case CustomActivityAction.sendToDevice.actionType:
            showSendToDevice()
        case CustomActivityAction.copyLink.actionType:
            SimpleToast().showAlertWithText(
                .AppMenu.AppMenuCopyURLConfirmMessage,
                bottomContainer: alertContainer,
                theme: themeManager.currentTheme)
            parentCoordinator?.didFinish(from: self)
        default:
            parentCoordinator?.didFinish(from: self)
        }
    }

    private func showSendToDevice() {
        guard let selectedTab = tabManager.selectedTab,
              let url = selectedTab.canonicalURL?.displayURL
        else { return }

        let themeColors = themeManager.currentTheme.colors
        let colors = SendToDeviceHelper.Colors(defaultBackground: themeColors.layer1,
                                               textColor: themeColors.textPrimary,
                                               iconColor: themeColors.iconPrimary)
        let shareItem = ShareItem(url: url.absoluteString,
                                  title: selectedTab.title)

        let helper = SendToDeviceHelper(
            shareItem: shareItem,
            profile: profile,
            colors: colors,
            delegate: self)
        let viewController = helper.initialViewController()

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sendToDevice)
        router.present(viewController)
    }

    private func dequeueNotShownJSAlert() {
    }
}

extension ShareExtensionCoordinator: DevicePickerViewControllerDelegate, InstructionsViewDelegate {
    func devicePickerViewControllerDidCancel(_ devicePickerViewController: DevicePickerViewController) {
        router.dismiss()
        parentCoordinator?.didFinish(from: self)
    }

    func devicePickerViewController(_ devicePickerViewController: DevicePickerViewController, didPickDevices devices: [RemoteDevice]) {
        guard let shareItem = devicePickerViewController.shareItem else { return }

        guard shareItem.isShareable else {
            let alert = UIAlertController(title: .SendToErrorTitle, message: .SendToErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .SendToErrorOKButton, style: .default) { [weak self] _ in self?.router.dismiss() })
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
                SimpleToast().showAlertWithText(.AppMenu.AppMenuTabSentConfirmMessage,
                                                bottomContainer: self.alertContainer,
                                                theme: self.themeManager.currentTheme)
            }
        }
    }

    func dismissInstructionsView() {
        router.dismiss()
        parentCoordinator?.didFinish(from: self)
    }
}
