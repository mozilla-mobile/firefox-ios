//
//  WKEngineViewTests.swift
//  BrowserKit
//
//  Created by Daniel Dervishi on 2025-02-24.
//

import XCTest
@testable import WebEngine

@available(iOS 16.0, *)
final class WKEngineViewTests: XCTestCase {
    private var engineSession: WKEngineSession!
    
    override func setUp() {
        super.setUp()
        engineSession = WKEngineSession(userScriptManager: MockWKUserScriptManager(),
                                        configurationProvider: MockWKEngineConfigurationProvider(),
                                        webViewProvider: MockWKWebViewProvider(),
                                        contentScriptManager: MockWKContentScriptManager(),
                                        metadataFetcher: MockMetadataFetcherHelper())
    }
    
    override func tearDown() {
        engineSession = nil
        super.tearDown()
    }
    
    func testRenderSetsIsActiveTrue() {
        let subject = createSubject()
        
        subject.render(session: engineSession)
        
        XCTAssertTrue(engineSession.isActive)
    }
    
    func testRemoveSetsIsActiveFalse(){
        let subject = createSubject()
        let newEngineSession = WKEngineSession(userScriptManager: MockWKUserScriptManager(),
                                               configurationProvider: MockWKEngineConfigurationProvider(),
                                               webViewProvider: MockWKWebViewProvider(),
                                               contentScriptManager: MockWKContentScriptManager(),
                                               metadataFetcher: MockMetadataFetcherHelper())!
        
        subject.render(session: engineSession)
        subject.render(session: newEngineSession)
        
        XCTAssertFalse(engineSession.isActive)
        XCTAssertTrue(newEngineSession.isActive)
    }
    
    
    func createSubject() -> WKEngineView {
        let subject = WKEngineView(frame: CGRect.zero)
        return subject
    }
}
