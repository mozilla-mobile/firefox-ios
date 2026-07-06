// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import Common
import SwiftUI
import UIKit

@MainActor
private func previewViewController(sections: [WebCompatReportViewModel.Section]) -> UIViewController {
    let viewModel = WebCompatReportViewModel(
        navigationTitle: "Report a Website Issue",
        closeButtonAccessibilityLabel: "Close",
        previewButtonTitle: "Preview",
        isPreviewEnabled: !sections.isEmpty,
        sections: sections
    )
    let sheet = WebCompatReportSheetViewController(viewModel: viewModel, theme: LightTheme())
    let navigationController = UINavigationController(rootViewController: sheet)
    navigationController.navigationBar.prefersLargeTitles = false
    return navigationController
}

@available(iOS 17.0, *)
#Preview("Empty shell") {
    previewViewController(sections: [])
}

@available(iOS 17.0, *)
#Preview("Placeholder sections") {
    previewViewController(sections: [
        .init(id: "url", rows: [.init(id: "url", title: "https://example.com")]),
        .init(id: "issue", rows: [.init(id: "issue", title: "Website issue")]),
        .init(id: "advanced", rows: [
            .init(id: "screenshot", title: "Include screenshot"),
            .init(id: "blocklist", title: "Include blocked list")
        ])
    ])
}
#endif
