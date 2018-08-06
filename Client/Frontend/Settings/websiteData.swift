//
//  websiteData.swift
//  Client
//
//  Created by Meera Rachamallu on 8/2/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import Foundation
import WebKit

struct siteData {
    let dataOfSite: WKWebsiteDataRecord
    let nameOfSite: String

    init(dataOfSite: WKWebsiteDataRecord, nameOfSite: String){
        self.dataOfSite = dataOfSite
        self.nameOfSite = nameOfSite
    }
}
