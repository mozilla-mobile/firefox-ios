// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class LegacyTabPeekPreviewActionBuilder {
    private var actions = [UIPreviewActionItem]()

    var count: Int {
        return actions.count
    }

    func addBookmark(handler: @escaping (UIPreviewAction, UIViewController) -> Void) {
        actions.append(UIPreviewAction(
            title: .TabPeekAddToBookmarks,
            style: .default,
            handler: handler
        ))
    }

    func addSendToDeviceTitle(handler: @escaping (UIPreviewAction, UIViewController) -> Void) {
        actions.append(UIPreviewAction(
            title: .LegacyAppMenu.TouchActions.SendToDeviceTitle,
            style: .default,
            handler: handler
        ))
    }

    func addCopyUrl(handler: @escaping (UIPreviewAction, UIViewController) -> Void) {
        actions.append(UIPreviewAction(
            title: .TabPeekCopyUrl,
            style: .default,
            handler: handler
        ))
    }

    func addCloseTab(handler: @escaping (UIPreviewAction, UIViewController) -> Void) {
        actions.append(UIPreviewAction(
            title: .TabPeekCloseTab,
            style: .destructive,
            handler: handler
        ))
    }

    func build() -> [UIPreviewActionItem] {
        return actions
    }
}
