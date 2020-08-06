//
//  WidgetKit.swift
//  WidgetKit
//
//  Created by McNoor's  on 8/11/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct FirefoxWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        SearchQuickLinksWigdet()
        SmallQuickLinkWidget()
    }
}
