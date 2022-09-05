// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import WidgetKit

struct SearchWidgetView: View {
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(UIConstants.strings.searchInApp)
                        .font(.headline)
                        .fontWeight(.medium)
                    Text(String.appNameForBundle)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)

                Spacer()

                Image.magnifyingGlass
                    .foregroundColor(.white)
                    .frame(height: .magnifyingGlassHeight)
            }
            Spacer()
            HStack {
                Spacer()
                Image.mozilla
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
                    .frame(height: .logoHeight)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: .quickAccessWidget,
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        )
    }
}

struct SearchWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        SearchWidgetView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

fileprivate extension CGFloat {
    static let logoHeight: CGFloat = 22
    static let magnifyingGlassHeight: CGFloat = 18
}

fileprivate extension Image {
    static let magnifyingGlass = Image(systemName: "magnifyingglass")
    static let mozilla = Image("icon_mozilla")
}

fileprivate extension Gradient {
    static let quickAccessWidget = Gradient(colors: [Color("GradientFirst"), Color("GradientSecond")])
}

fileprivate extension String {
    static var appNameForBundle: String {
        var isKlar: Bool { return (Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String).contains("Klar") }
        return isKlar ? "Klar" : "Focus"
    }
}
