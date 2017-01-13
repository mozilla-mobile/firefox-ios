/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import OnyxClient

private let OnyxStagingConfiguration = OnyxClientConfiguration(serverURL: "https://onyx_tiles.stage.mozaws.net".asURL!, version: 3)
private let OnyxProductionConfiguration = OnyxClientConfiguration(serverURL: "https://tiles.services.mozilla.com".asURL!, version: 3)

struct OnyxTelemetry {
    static fileprivate let configuration: OnyxClientConfiguration = {
        switch AppConstants.BuildChannel {
            case .Nightly:  return OnyxProductionConfiguration
            case .Beta:     return OnyxProductionConfiguration
            case .Release:  return OnyxProductionConfiguration
            default:        return OnyxProductionConfiguration
        }
    }()

    static var sharedClient = OnyxClient(configuration: configuration)
}
