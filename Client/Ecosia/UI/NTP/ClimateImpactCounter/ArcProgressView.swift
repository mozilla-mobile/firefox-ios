// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

final class ArcTheme: ObservableObject {
    @Published var backgroundColor: Color = .clear
    @Published var progressColor: Color = .clear
}

struct RectangularArcShape: Shape {
    var progress: CGFloat // Progress value between 0 and 1

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Calculate the start and end angles for the arc
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 180 + Double(180 * progress))

        // Create an arc based on the rectangle's dimensions
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),  // Center at the bottom of the rect
                    radius: min(rect.width, rect.height) / 1.5,     // Use the smaller dimension for the radius
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)

        return path
    }
}

struct ArcProgressView: View {

    var progress: CGFloat
    var lineWidth: CGFloat = 10
    @ObservedObject var theme: ArcTheme

    var body: some View {
        SwiftUI.ProgressView(value: progress)
            .progressViewStyle(ArcProgressViewStyle(theme: theme,
                                                    lineWidth: lineWidth))
    }
}

private struct ArcProgressViewStyle: ProgressViewStyle {

    @ObservedObject var theme: ArcTheme
    var lineWidth: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // Static background arch
            RectangularArcShape(progress: 1)
                .stroke(theme.backgroundColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress arc
            RectangularArcShape(progress: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(theme.progressColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .animation(.easeInOut(duration: 0.5), value: configuration.fractionCompleted)
        }
    }
}

private struct ArcShape: Shape {
    var progress: CGFloat // Progress value between 0 and 1

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let radius = rect.width / 2
        let startAngle = Angle(degrees: 180)
        let endAngle = Angle(degrees: 180 + Double(180 * progress))

        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)

        return path
    }
}
