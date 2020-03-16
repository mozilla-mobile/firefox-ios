//
//  LPRequestTest.m
//  Leanplum-SDK_Tests
//
//  Created by Mayank Sanganeria on 9/26/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Leanplum/LPRequest.h>

@interface LPRequest(UnitTest)

@property (nonatomic, strong) NSString *httpMethod;

@end

@interface LPRequestTest : XCTestCase

@end

@implementation LPRequestTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPostShouldCreatePostRequest {
    NSString *apiMethod = @"apiMethod";
    NSDictionary *params = @{@"key": @"value"};
    LPRequest *postRequest = [LPRequest post:apiMethod params:params];

    XCTAssertEqual(postRequest.apiMethod, apiMethod);
    XCTAssertEqual(postRequest.params, params);
    XCTAssertTrue([postRequest.httpMethod isEqualToString:@"POST"]);
}

- (void)testGetShouldCreateGetRequest {
    NSString *apiMethod = @"apiMethod";
    NSDictionary *params = @{@"key": @"value"};
    LPRequest *getRequest = [LPRequest get:apiMethod params:params];

    XCTAssertEqual(getRequest.apiMethod, apiMethod);
    XCTAssertEqual(getRequest.params, params);
    XCTAssertTrue([getRequest.httpMethod isEqualToString:@"GET"]);
}

@end
