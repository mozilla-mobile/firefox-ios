//
//  EarlGreyTests.swift
//  EarlGreyTests
//
//  Created by mozilla on 12/29/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//
@testable import Client
import XCTest
import EarlGrey
import GCDWebServers

class EarlGreyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let webServer = GCDWebServer()
        
        webServer.addDefaultHandlerForMethod("GET", requestClass: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse(HTML:"<html><body><p>Hello World</p></body></html>")
            
        })
        
        webServer.startWithPort(0, bonjourName: "GCD Web Server")
        print("Visit \(webServer.serverURL) in your web browser")
       
        EarlGrey().selectElementWithMatcher(grey_accessibilityID("IntroViewController.startBrowsingButton")).assertWithMatcher(grey_sufficientlyVisible())
        
    }
    
    
}
