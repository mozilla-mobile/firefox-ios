/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

struct TabGroup {
    var searchTermName: String
    var tabs: [Tab]
}

//class StopWatchTimer {
//    private var startTime: Date?
//    private var endTime: Date?
//    var isActive: Bool = false
//    var elpasedTime: TimeInterval? {
//        guard let endTime = endTime, let startTime = startTime else { return nil }
//        let diff = Date.difference(recent: endTime, previous: startTime)
//        return endTime.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate
//    }
//
//    func startTimer() {
//        startTime = Date()
//        isActive = true
//    }
//
//    func endTimer() {
//        endTime = Date()
//        isActive = false
//    }
//
//    func pauseTimer() {
//
//    }
//
//    func resumeTimer() {
//
//    }
//    func resetTimer() {
//        startTime = nil
//        endTime = nil
//    }
//
//}

class StopWatchTimer {
    private var timer: Timer?
    var isPaused = true
    var elpasedTime = 0
    
    func startOrResume() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementValue), userInfo: nil, repeats: true)
    }
    
    @objc func incrementValue() {
        elpasedTime += 1
    }
    
    func pauseOrStop() {
        timer?.invalidate()
    }
    
    func resetTimer() {
        elpasedTime = 0
        timer = nil
    }
    
}

class TabGroupsManager {
    
    static let shared = TabGroupsManager()
    
    private init(){}
    
    func getGroupedTabs(activeTabs: [Tab]) -> TabGroup {
        var tabGroup = TabGroup(searchTermName: "", tabs: [Tab]())
        
        return tabGroup
    }
}
