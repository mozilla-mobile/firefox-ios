// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

typealias BenchmarkStep = (label: String?, time: Double)

/// Simple benchmarking utility for measuring runtime of code performed in sequential steps.
/// Note: this is a very basic tool and incurs a small amount of overhead for its own
/// processing. It can be used to measure multi-threaded code but you must ensure that your
/// step() calls are not made concurrently as there are no internal locks provided.
final class BenchmarkSteps {
    private var last: DispatchTime
    private var steps: [BenchmarkStep] = []

    init() {
        last = DispatchTime.now()
    }

    func step(_ label: String? = nil) {
        let time = DispatchTime.now()
        let interval = Double(time.uptimeNanoseconds - last.uptimeNanoseconds)
        let ms = interval / 1_000_000
        steps.append((label, ms))
        last = DispatchTime.now()
    }

    func finish() {
        print("[Benchmark Completed]")
        var total: Double = 0
        for step in steps {
            let label = step.label
            let msTime = step.time
            if let label, !label.isEmpty {
                print("\t[Step: '\(label)'] \(String(format: "%.04f", msTime)) ms")
            } else {
                print("\t[Step] \(String(format: "%.04f", msTime)) ms")
            }
            total += msTime
        }
        print("[End] Total: \(String(format: "%.04f", total)) ms")
    }
}
