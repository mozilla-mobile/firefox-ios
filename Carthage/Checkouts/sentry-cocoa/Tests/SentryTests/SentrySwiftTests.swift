//
//  SentrySwiftTests.swift
//  Sentry
//
//  Created by Daniel Griesser on 31/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

@testable import Sentry
import XCTest

class SentrySwiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        let fileManager = try! SentryFileManager(dsn: SentryDsn(string: "https://username:password@app.getsentry.com/12345"))
        fileManager.deleteAllStoredEvents()
        fileManager.deleteAllStoredBreadcrumbs()
        fileManager.deleteAllFolders()
        Client.shared = try? Client(dsn: "https://username:password@app.getsentry.com/12345")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWrongDsn() {
        XCTAssertThrowsError(try Client(dsn: "http://sentry.io"))
    }
    
    func testCorrectDsn() {
        let client = try? Client(dsn: "https://username:password@app.getsentry.com/12345")
        XCTAssertNotNil(client)
    }
    
    func testOptions() {
        let client = try? Client(options: ["dsn": "https://username:password@app.getsentry.com/12345"])
        XCTAssertNotNil(client)
    }
    
    func testDisabled() {
        let client = try? Client(options: ["dsn": "https://username:password@app.getsentry.com/12345", "enabled": false])
        XCTAssertNotNil(client)
        
        client!.beforeSendRequest = { request in
            XCTAssertTrue(false)
        }
        
        let event2 = Event(level: .debug)
        event2.extra = ["a": "b"]
        client!.send(event: event2)
    }
    
    func testEnabled() {
        let client = try? Client(options: ["dsn": "https://username:password@app.getsentry.com/12345", "enabled": true])
        XCTAssertNotNil(client)
        
        client!.beforeSendRequest = { request in
            XCTAssertTrue(true)
        }
        
        let event2 = Event(level: .debug)
        event2.extra = ["a": "b"]
        client!.send(event: event2) { (error) in
            XCTAssertNil(error)
        }
    }
    
    func testFunctionCalls() {
        let event = Event(level: .debug)
        event.message = "Test Message"
        event.environment = "staging"
        event.extra = ["ios": true]
        XCTAssertNotNil(event.serialize())
        Client.shared?.send(event: event)
        let event2 = Event(level: .debug)
        event2.extra = ["a": "b"]
        XCTAssertNotNil(event2.serialize())
        
        Client.shared?.beforeSerializeEvent = { event in
            event.extra = ["b": "c"]
        }
        
        Client.shared?.send(event: event2) { (error) in
            XCTAssertNil(error)
        }
        
        Client.logLevel = .debug
        Client.shared?.clearContext()
        Client.shared?.breadcrumbs.maxBreadcrumbs = 100
        Client.shared?.breadcrumbs.add(Breadcrumb(level: .info, category: "test"))
        XCTAssertEqual(Client.shared?.breadcrumbs.count(), 1)
        Client.shared?.enableAutomaticBreadcrumbTracking()
        let user = User()
        user.userId = "1234"
        user.email = "hello@sentry.io"
        user.extra = ["is_admin": true]
        Client.shared?.user = user
        
        Client.shared?.tags = ["iphone": "true"]
        
        Client.shared?.clearContext()
        
        Client.shared?.snapshotStacktrace {
            let event = Event(level: .debug)
            event.message = "Test Message"
            Client.shared?.send(event: event)
        }
        Client.shared?.beforeSendRequest = { request in
            request.addValue("my-token", forHTTPHeaderField: "Authorization")
        }
    }
    
}
