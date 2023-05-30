// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Are a declarative way of describing a state change. Actions don’t contain any code,
/// they are consumed by the store and forwarded to reducers. Are used to express intended state changes. 
public protocol Action {}
