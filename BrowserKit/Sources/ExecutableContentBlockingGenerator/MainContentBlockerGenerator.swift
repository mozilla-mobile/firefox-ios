// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import ContentBlockingGenerator

@main
public struct MainContentBlockerGenerator {
    static let generator = ContentBlockerGenerator.factory()

    // Static main needs to be used for executable, providing an instance so we can
    // call it from a terminal
    public static func main() {
        generator.generateLists()
    }
}
