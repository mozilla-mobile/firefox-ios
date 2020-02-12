//
//  Constants.swift
//  XCUITests
//
//  Created by horatiu purec on 10/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

let serverPort = Int.random(in: 1025..<65000)

public struct Constants {
    public static let defaultWaitTime: Double = 2
    public static let smallWaitTime: Double = 5
    
    // Constants for BookmarkingTests
    static let url_1 = "test-example.html"
    static let url_2 = ["url": "test-mozilla-org.html",
                        "bookmarkLabel": "Internet for people, not profit — Mozilla"]
    static let urlLabelExample_3 = "Example Domain"
    static let url_3 = "localhost:\(serverPort)/test-fixture/test-example.html"
    static let urlLabelExample_4 = "Example Login Page 2"
    static let url_4 = "test-password-2.html"
}
