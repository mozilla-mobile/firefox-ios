// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

struct SeedProgressView: View {

    // MARK: - UX Constants

    private enum UX {
        static let seedLineWidth: CGFloat = 3
        static let seedIconWidthHeight: CGFloat = 24
        static let seedIconBottomOffset: CGFloat = 8
    }

    // MARK: - Properties

    var progressValue: CGFloat
    @ObservedObject var theme: ArcTheme

    // MARK: - View

    var body: some View {
        ZStack(alignment: .top) {
            ArcProgressView(progress: progressValue,
                            lineWidth: UX.seedLineWidth,
                            theme: theme
            )
            .offset(y: -UX.seedLineWidth * 2)

            Image("seedIcon")
                .resizable()
                .frame(width: UX.seedIconWidthHeight, height: UX.seedIconWidthHeight)
                .offset(y: UX.seedIconBottomOffset)
        }
    }
}
