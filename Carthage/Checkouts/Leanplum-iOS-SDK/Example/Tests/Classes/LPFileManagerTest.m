//
//  LPFileManagerTest.m
//  Leanplum
//
//  Created by Ben Marten on 7/8/16.
//  Copyright (c) 2016 Leanplum. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.


#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import "LPFileManager.h"
#import "LeanplumHelper.h"
#import "LeanplumRequest+Categories.h"
#import "LPNetworkEngine+Category.h"
#import "Leanplum+Extensions.h"
#import "LPConstants.h"

/**
 * Tests file manager public methods.
 */
@interface LPFileManagerTest : XCTestCase

@end

@implementation LPFileManagerTest

+ (void)setUp
{
    [super setUp];
    // Called only once to setup method swizzling.
    [LeanplumHelper setup_method_swizzling];
}

- (void)tearDown {
    [super tearDown];
    // Clean up after every test.
    [LeanplumHelper clean_up];
    [OHHTTPStubs removeAllStubs];
}

/**
 * Tests whether file relative to app bundle is found.
 */
- (void)test_file_relative_to_app_bundle
{
    NSString *file = [LPFileManager fileRelativeToAppBundle:@"Info.plist"];
    XCTAssertNotNil(file);
}

/**
 * Tests whether file relative to documents directory is found.
 */
- (void)test_file_relative_to_documents
{
    NSString *file = [LPFileManager fileRelativeToDocuments:@"Mario.png"
                                   createMissingDirectories:YES];
    XCTAssertNotNil(file);
}

/**
 * Tests whether file relative to lp bundle directory is found.
 */
- (void)test_file_relative_to_lp_bundle
{
    NSString *file = [LPFileManager fileRelativeToLPBundle:@"Info.plist"];
    XCTAssertNotNil(file);
}

/**
 * Tests whether file exists or not.
 */
- (void)test_file_exists
{
    XCTAssertTrue([LPFileManager fileExists:@"Info.plist"]);
    XCTAssertFalse([LPFileManager fileExists:@"random_file.png"]);
}

/**
 * Test if resource is found.
 */
- (void)test_resource_path
{
    // Creates a sample file in cache directory for test.
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                   NSUserDomainMask, YES)[0];
    NSString *folderPath = [cacheDirectory stringByAppendingPathComponent:@"Leanplum_Resources"];
    NSData *test_data = [@"sample data" dataUsingEncoding:NSUTF8StringEncoding];
    [test_data writeToFile:[folderPath stringByAppendingPathComponent:@"sample.file"]
                                                           atomically:YES];

    NSString *path = [Leanplum pathForResource:@"sample" ofType:@"file"];
    XCTAssertNotNil(path);

    // Check for invalid file.
    NSString *non_existant = [Leanplum pathForResource:@"exists" ofType:@"none"];
    XCTAssertNil(non_existant);
}

/**
 * Tests whether file should be downloaded.
 */
- (void)test_should_download_file
{
    BOOL download = [LPFileManager shouldDownloadFile:@"Back.png" defaultValue:@"Mario.png"];
    XCTAssertTrue(download);

    BOOL dont_download = [LPFileManager shouldDownloadFile:@"Mario.png" defaultValue:@"Mario.png"];
    XCTAssertFalse(dont_download);

    BOOL file_exists = [LPFileManager shouldDownloadFile:@"test.png" defaultValue:@"Back.png"];
    XCTAssertTrue(file_exists);
}

/**
 * Tests file downloading.
 */
- (void)test_file_download
{
    // Clear cache before downloading new file.
    NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                NSUserDomainMask, YES)[0]
                            stringByAppendingPathComponent:@"Leanplum_Resources"];
    NSError *error = nil;
    for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath
                                                                               error:&error]) {
        NSString *path = [folderPath stringByAppendingPathComponent:file];
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    }

    id<OHHTTPStubsDescriptor> startStub = [OHHTTPStubs stubRequestsPassingTest:
                                           ^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                   headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTAssertTrue([LeanplumHelper start_development_test]);

    // Remove stub after start is successful.
    [OHHTTPStubs removeStub:startStub];

    // Mock file download, return real file from file system.
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.host isEqualToString:API_HOST];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSData *data = [LeanplumHelper retrieve_data_from_file:@"test" ofType:@"pdf"];
        return [OHHTTPStubsResponse responseWithData:data statusCode:200 headers:nil];
    }];

    // Validate request.
    [LeanplumRequest validate_request:^BOOL(NSString *method, NSString *apiMethod,
                                        NSDictionary *params){
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"downloadFile");
        return YES;
    }];

    dispatch_semaphore_t semaphor = dispatch_semaphore_create(0);
    [LPNetworkEngine enableForceSynchronous];
    // Download file.
    [LPFileManager maybeDownloadFile:@"test_downloaded_file.pdf" defaultValue:@"Mario.png"
                          onComplete:^{
        dispatch_semaphore_signal(semaphor);
    }];
    [LPNetworkEngine disableForceSynchronous];

    long timedOut = dispatch_semaphore_wait(semaphor, [LeanplumHelper default_dispatch_time]);
    XCTAssertTrue(timedOut == 0);

    // Check if file is downloaded.
    XCTAssertTrue([LPFileManager fileExists:@"test_downloaded_file.pdf"]);
}

- (void)test_file_upload
{
    [OHHTTPStubs stubRequestsPassingTest:
     ^BOOL(NSURLRequest * _Nonnull request) {
         return [request.URL.host isEqualToString:API_HOST];
     } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
         NSString *response_file = OHPathForFile(@"simple_start_response.json", self.class);
         return [OHHTTPStubsResponse responseWithFileAtPath:response_file statusCode:200
                                                    headers:@{@"Content-Type":@"application/json"}];
     }];
    
    XCTAssertTrue([LeanplumHelper start_development_test]);
    
    // Creates a sample file in cache directory for test.
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                                                   NSUserDomainMask, YES)[0];
    NSString *folderPath = [cacheDirectory stringByAppendingPathComponent:@"Leanplum_Resources"];
    NSData *test_data = [@"sample data" dataUsingEncoding:NSUTF8StringEncoding];
    NSString* filePath = [folderPath stringByAppendingPathComponent:@"sample.file"];
    [test_data writeToFile:filePath
                atomically:YES];
    
    // Validate request.
    [LeanplumRequest validate_request:^(NSString *method, NSString *apiMethod,
                                        NSDictionary *params){
        // Check api method first.
        XCTAssertEqualObjects(apiMethod, @"uploadFile");
        XCTAssertNotNil([params objectForKey:@"data"]);
        return YES;
    }];
    
    [[LeanplumRequest post:LP_METHOD_UPLOAD_FILE
                    params:@{LP_PARAM_DATA: [LPJSON stringFromJSON:[NSMutableArray array]]}]
     sendFilesNow:@[filePath]];
}

- (void)test_nullability
{
    NSString *path = nil;
    id result = [LPFileManager documentsPathRelativeToFolder:path];
    XCTAssertNil(result);

    NSDictionary *dict = @{@"path":@"/"};
    result = [LPFileManager documentsPathRelativeToFolder:dict[@"path"]];
    XCTAssertNotNil(result);

    result = [LPFileManager documentsPathRelativeToFolder:dict[@"foo"]];
    XCTAssertNil(result);
}

- (void)test_addSkipBackupAttribute
{
    NSString *path = nil;
    XCTAssertFalse([LPFileManager addSkipBackupAttributeToItemAtPath:path]);

    // Creates a sample file in directory for test.
    NSString *cacheDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                   NSUserDomainMask, YES)[0];

    NSData *test_data = [@"sample data" dataUsingEncoding:NSUTF8StringEncoding];
    path = [cacheDirectory stringByAppendingPathComponent:@"sample.txt"];
    [test_data writeToFile:path atomically:YES];

    XCTAssertTrue([LPFileManager addSkipBackupAttributeToItemAtPath:path]);

    NSURL* url = [NSURL fileURLWithPath:path];
    NSNumber* excluded = [NSNumber new];
    [url getResourceValue:&excluded forKey:NSURLIsExcludedFromBackupKey error:nil];

    XCTAssertEqual([excluded boolValue], YES);
}

@end
