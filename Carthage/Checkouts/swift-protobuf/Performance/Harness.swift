// Performance/Harness.swift - Performance harness definition
//
// Copyright (c) 2014 - 2019 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// Defines the class that runs the performance tests.
///
// -----------------------------------------------------------------------------

import Foundation

private func padded(_ input: String, to width: Int) -> String {
  return input + String(repeating: " ", count: max(0, width - input.count))
}

/// It is expected that the generator will provide these in an extension.
protocol GeneratedHarnessMembers {
  /// The number of times to loop the body of the run() method.
  /// Increase this to get better precision.
  var runCount: Int { get }

  /// The main body of the performance harness.
  func run()
}

/// Harness used for performance tests.
///
/// The generator script will generate an extension to this class that adds a
/// run() method, which the main.swift file calls.
class Harness: GeneratedHarnessMembers {

  /// The number of times to execute the block passed to measure().
  var measurementCount = 10

  /// The number of times to call append() for repeated fields.
  let repeatedCount: Int32 = 10

  /// Ordered list of task names
  var taskNames = [String]()

  /// The times taken by subtasks during each measured attempt.
  var subtaskTimings = [String: [TimeInterval]]()

  /// Times for the subtasks in the current attempt.
  var currentSubtasks = [String: TimeInterval]()

  /// The file to which results should be written.
  let resultsFile: FileHandle?

  /// Creates a new harness that writes its statistics to the given file
  /// (as well as to stdout).
  init(resultsFile: FileHandle?) {
    self.resultsFile = resultsFile
  }

  /// Measures the time it takes to execute the given block. The block is
  /// executed five times and the mean/standard deviation are computed.
  func measure(block: () throws -> Void) {
    var timings = [TimeInterval]()
    subtaskTimings.removeAll()
    print("Running each check \(runCount) times, times in µs")

    var headingsDisplayed = false

    do {
      // Do each measurement multiple times and collect the means and standard
      // deviation to account for noise.
      for attempt in 1...measurementCount {
        currentSubtasks.removeAll()
        taskNames.removeAll()
        let start = Date()
        for _ in 0..<runCount {
          taskNames.removeAll()
          try block()
        }
        let end = Date()
        let diff = end.timeIntervalSince(start) * 1000
        timings.append(diff)

        if !headingsDisplayed {
            let names = taskNames
            print("   ", terminator: "")
            for (i, name) in names.enumerated() {
                if i % 2 == 0 {
                    print(padded(name, to: 18), terminator: "")
                }
            }
            print()
            print("   ", terminator: "")
            print(padded("", to: 9), terminator: "")
            for (i, name) in names.enumerated() {
                if i % 2 == 1 {
                    print(padded(name, to: 18), terminator: "")
                }
            }
            print()
            headingsDisplayed = true
        }

        print(String(format: "%3d", attempt), terminator: "")

        for name in taskNames {
          let time = currentSubtasks[name] ?? 0
          print(String(format: "%9.3f", name, time), terminator: "")
          subtaskTimings[name] = (subtaskTimings[name] ?? []) + [time]
        }
        print()
      }
    } catch let e {
      fatalError("Generated harness threw an error: \(e)")
    }

    for (name, times) in subtaskTimings {
      writeToLog("\"\(name)\": \(times),\n")
    }

    let (mean, stddev) = statistics(timings)
    let stats =
        String(format: "Relative stddev = %.1f%%\n", (stddev / mean) * 100.0)
    print(stats)
  }

  /// Measure an individual subtask whose timing will be printed separately
  /// from the main results.
  func measureSubtask<Result>(
    _ name: String,
    block: () throws -> Result
  ) rethrows -> Result {
      return try autoreleasepool { () -> Result in
          taskNames.append(name)
          let start = Date()
          let result = try block()
          let end = Date()
          let diff = end.timeIntervalSince(start) / Double(runCount) * 1000000.0
          currentSubtasks[name] = (currentSubtasks[name] ?? 0) + diff
          return result
      }
  }

  /// Compute the mean and standard deviation of the given time intervals.
  private func statistics(_ timings: [TimeInterval]) ->
    (mean: TimeInterval, stddev: TimeInterval) {
    var sum: TimeInterval = 0
    var sqsum: TimeInterval = 0
    for timing in timings {
      sum += timing
      sqsum += timing * timing
    }
    let n = TimeInterval(timings.count)
    let mean = sum / n
    let variance = sqsum / n - mean * mean
    return (mean: mean, stddev: sqrt(variance))
  }

  /// Writes a string to the data results file that will be parsed by the
  /// calling script to produce visualizations.
  private func writeToLog(_ string: String) {
    if let resultsFile = resultsFile {
      let utf8 = Data(string.utf8)
      resultsFile.write(utf8)
    }
  }
}
