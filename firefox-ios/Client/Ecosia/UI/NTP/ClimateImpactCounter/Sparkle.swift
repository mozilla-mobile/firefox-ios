// swiftlint:disable:next disable file_header
// Source: https://gist.github.com/UnderscoreDavidSmith/60ca0c6727d0c76c9b0012a27dfe1008
// Modified to get bigger sparkles

import SwiftUI

struct TwinkleView: View {

    private func position(in proxy: GeometryProxy, sparkle: Sparkle) -> CGPoint {
        let radius = min(proxy.size.width, proxy.size.height) / 2.0
        let drawnRadius = (radius - 5) * sparkle.position.x
        let angle = Double.pi * 2.0 * sparkle.position.y

        let x = proxy.size.width * 0.5 + drawnRadius * cos(angle)
        let y = proxy.size.height * 0.5 + drawnRadius * sin(angle)

        return CGPoint(x: x, y: y)
    }

    private func scaleFor(date: Date, sparkle: Sparkle) -> CGFloat {
        var offset = date.timeIntervalSince(sparkle.startDate)
        offset = max(offset, 0)
        offset = min(offset, SparkleMagic.sparkleDuration)
        let halfDuration = SparkleMagic.sparkleDuration * 0.5
        let value: CGFloat
        if offset < halfDuration {
            value = offset / halfDuration
        } else {
            value = 1.0 - ((offset - halfDuration) / halfDuration)
        }
        return value == 0 ? 0.1 : value
    }

    var active: Bool // Made active a var so it can change even from UIKit
    @StateObject var magic = SparkleMagic()

    var body: some View {
        if active {
            GeometryReader { geo in
                ZStack {
                    TimelineView(.animation) { context in
                        // swiftlint:disable:next redundant_discardable_let
                        let _ = magic.update(date: context.date)
                        ForEach(magic.sparkles) { sparkle in
                            SparkleShape()
                                .fill(Color.white)
                                .frame(width: 15, height: 15)
                                .scaleEffect(scaleFor(date: context.date, sparkle: sparkle))
                                .position(self.position(in: geo, sparkle: sparkle))
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = 1.0
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX - radius, y: rect.midY - radius))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX - radius, y: rect.midY + radius))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + radius, y: rect.midY + radius))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + radius, y: rect.midY - radius))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

class Sparkle: Identifiable {
    let id = UUID()
    let position: CGPoint
    let startDate: Date
    init(position: CGPoint, startDate: Date) {
        self.position = position
        self.startDate = startDate
    }
}

class SparkleMagic: ObservableObject {
    static let sparkleDuration: Double = 2.0
    var sparkles: [Sparkle]

    init() {
        let anchor = Date()
        var result: [Sparkle] = []
        for _ in 0..<20 {
            result.append(Sparkle(position: CGPoint(x: CGFloat.random(in: 0...1),
                                                    y: CGFloat.random(in: 0...1)),
                                  startDate: anchor.addingTimeInterval(Double.random(in: 0...(SparkleMagic.sparkleDuration)))))
        }
        self.sparkles = result
    }

    func update(date: Date) {
        let anchor = Date()
        var result: [Sparkle] = []
        for sparkle in sparkles {
            if anchor.timeIntervalSince(sparkle.startDate) > SparkleMagic.sparkleDuration {
                result.append(Sparkle(position: CGPoint(x: CGFloat.random(in: 0...1),
                                                        y: CGFloat.random(in: 0...1)),
                                      startDate: anchor.addingTimeInterval(Double.random(in: 0...(SparkleMagic.sparkleDuration)))))
            } else {
                result.append(sparkle)
            }
        }
        self.sparkles = result
    }
}
