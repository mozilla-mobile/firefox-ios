// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class BenchmarkSteps {
    private var last: DispatchTime
    private var steps: [(String?, UInt64)] = []

    init() {
        last = DispatchTime.now()
    }

    func step(_ label: String? = nil) {
        let time = DispatchTime.now()
        let interval = time.uptimeNanoseconds - last.uptimeNanoseconds
        let ms = interval / 1_000_000
        steps.append((label, ms))
        last = DispatchTime.now()
    }

    func finish() {
        print("[Benchmark Completed]")
        var total: UInt64 = 0
        for step in steps {
            let label = step.0
            let msTime = step.1
            if let label, !label.isEmpty {
                print("\t[Step: '\(label)'] \(msTime) ms")
            } else {
                print("\t[Step] \(msTime) ms")
            }
            total += msTime
        }
        print("[End]")
    }
}
