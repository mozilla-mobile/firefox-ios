// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

class TabMoreMenuViewModel: NSObject {
    typealias PresentableVC = UIViewController & UIPopoverPresentationControllerDelegate
    
    fileprivate let tabManager: TabManager
    fileprivate let viewController: TabMoreMenuViewController
    fileprivate let profile: Profile
    
    init(viewController: TabMoreMenuViewController, profile: Profile) {
        self.viewController = viewController
        self.tabManager = BrowserViewController.foregroundBVC().tabManager
        self.profile = profile
        super.init()
        tabManager.addDelegate(self)
    }
    
    func pin(_ tab: Tab) {
        guard let url = tab.url?.displayURL, let sql = self.profile.history as? SQLiteHistory else { return }

        sql.getSites(forURLs: [url.absoluteString]).bind { val -> Success in
            guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                return succeed()
            }
            return self.profile.history.addPinnedTopSite(site)
        }.uponQueue(.main) { result in
        }
    }
    
    func sendToDevice() {
        let bvc = BrowserViewController.foregroundBVC()
        if !self.profile.hasAccount() {
            let instructionsViewController = InstructionsViewController()
            instructionsViewController.delegate = bvc
            let navigationController = UINavigationController(rootViewController: instructionsViewController)
            navigationController.modalPresentationStyle = .formSheet
            bvc.present(navigationController, animated: true, completion: nil)
            return
        }

        let devicePickerViewController = DevicePickerViewController()
        devicePickerViewController.pickerDelegate = bvc
        devicePickerViewController.profile = self.profile
        devicePickerViewController.profileNeedsShutdown = false
        let navigationController = UINavigationController(rootViewController: devicePickerViewController)
        navigationController.modalPresentationStyle = .formSheet
        bvc.present(navigationController, animated: true, completion: nil)
    }
}

extension TabMoreMenuViewModel: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {
        
    }
    
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {

    }
    
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        
    }
    
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        
    }
    
    func tabManagerDidAddTabs(_ tabManager: TabManager) {
        
    }
    
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        
    }
}
