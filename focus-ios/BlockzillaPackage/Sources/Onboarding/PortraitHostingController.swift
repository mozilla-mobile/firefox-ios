// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

public class PortraitHostingController<Content>: UIHostingController<Content> where Content : View {

    public override var shouldAutorotate: Bool { return false }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
}
