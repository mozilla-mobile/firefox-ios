// The MIT License (MIT)
//
// Copyright (c) 2015 Isuru Nanayakkara
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Foundation
import SystemConfiguration


let ReachabilityStatusChangedNotification = "ReachabilityStatusChangedNotification"

enum ReachabilityType: CustomStringConvertible {
    case wwan
    case wiFi

    var description: String {
        switch self {
        case .wwan: return "WWAN"
        case .wiFi: return "WiFi"
        }
    }
}

enum ReachabilityStatus: CustomStringConvertible  {
    case offline
    case online(ReachabilityType)
    case unknown

    var description: String {
        switch self {
        case .offline: return "Offline"
        case .online(let type): return "Online (\(type))"
        case .unknown: return "Unknown"
        }
    }
}

open class Reach {

    func connectionStatus() -> ReachabilityStatus {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, $0)
            }
        }) else {
            return .unknown
        }

        var flags : SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .unknown
        }

        return ReachabilityStatus(reachabilityFlags: flags)
    }


    func monitorReachabilityChanges() {
        let host = "google.com"
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let reachability = SCNetworkReachabilityCreateWithName(nil, host)!

        SCNetworkReachabilitySetCallback(reachability, { (_, flags, _) in
            let status = ReachabilityStatus(reachabilityFlags: flags)

            NotificationCenter.default.post(name: Notification.Name(rawValue: ReachabilityStatusChangedNotification),
                object: nil,
                userInfo: ["Status": status.description])

            }, &context)

        SCNetworkReachabilityScheduleWithRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
    }

}

extension ReachabilityStatus {
    fileprivate init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)

        if !connectionRequired && isReachable {
            if isWWAN {
                self = .online(.wwan)
            } else {
                self = .online(.wiFi)
            }
        } else {
            self =  .offline
        }
    }
}
