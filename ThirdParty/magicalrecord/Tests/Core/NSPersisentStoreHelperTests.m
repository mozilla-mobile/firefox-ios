//
//  NSPersisentStoreHelperTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface NSPersisentStoreHelperTests : XCTestCase

@end

@implementation NSPersisentStoreHelperTests

- (NSString *) applicationStorageDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
}

#if TARGET_OS_IPHONE

- (void) testDefaultStoreFolderForiOSDevicesIsTheApplicationSupportFolder
{
    NSString *applicationLibraryDirectory = [self applicationStorageDirectory];
    NSString *defaultStoreName = kMagicalRecordDefaultStoreFileName;
    
    NSURL *expectedStoreUrl = [NSURL fileURLWithPath:[applicationLibraryDirectory stringByAppendingPathComponent:defaultStoreName]];
    
    NSURL *defaultStoreUrl = [NSPersistentStore MR_defaultLocalStoreUrl];
    
    XCTAssertEqualObjects(defaultStoreUrl, expectedStoreUrl, @"Store URL should be %@, actually is %@", [expectedStoreUrl absoluteString], [defaultStoreUrl absoluteString]);
}

- (void) testCanFindAURLInTheLibraryForiOSForASpecifiedStoreName
{
    NSString *storeFileName = @"NotTheDefaultStoreName.storefile";
    NSString *applicationLibraryDirectory = [self applicationStorageDirectory];
    NSString *testStorePath = [applicationLibraryDirectory stringByAppendingPathComponent:storeFileName];
    
    BOOL fileWasCreated = [[NSFileManager defaultManager] createFileAtPath:testStorePath contents:[storeFileName dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    XCTAssertTrue(fileWasCreated, @"Expected file to have been created");

    NSURL *expectedFoundStoreUrl = [NSURL fileURLWithPath:testStorePath];
    NSURL *foundStoreUrl = [NSPersistentStore MR_urlForStoreName:storeFileName];
    
    XCTAssertEqualObjects(foundStoreUrl, expectedFoundStoreUrl, @"Found store URL should be %@, actually is %@", [expectedFoundStoreUrl absoluteString], [foundStoreUrl absoluteString]);

    [[NSFileManager defaultManager] removeItemAtPath:testStorePath error:nil];
}

- (void) testCanFindAURLInDocumentsFolderForiOSForASpecifiedStoreName
{
    NSString *storeFileName = @"NotTheDefaultStoreName.storefile";
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *testStorePath = [documentDirectory stringByAppendingPathComponent:storeFileName];
    
    BOOL fileWasCreated = [[NSFileManager defaultManager] createFileAtPath:testStorePath contents:[storeFileName dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    XCTAssertTrue(fileWasCreated, @"Expected file to have been created");

    NSURL *expectedFoundStoreUrl = [NSURL fileURLWithPath:testStorePath];
    NSURL *foundStoreUrl = [NSPersistentStore MR_urlForStoreName:storeFileName];
    
    XCTAssertEqualObjects(foundStoreUrl, expectedFoundStoreUrl, @"Found store URL should be %@, actually is %@", [expectedFoundStoreUrl absoluteString], [foundStoreUrl absoluteString]);

    [[NSFileManager defaultManager] removeItemAtPath:testStorePath error:nil];
}

#else

- (void) testDefaultStoreFolderForMacIsTheApplicationSupportDirectory
{
    NSString *applictionSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *defaultStoreName = kMagicalRecordDefaultStoreFileName;
    
    NSURL *expectedStoreUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", applictionSupportDirectory, defaultStoreName]];
    
    NSURL *defaultStoreUrl = [NSPersistentStore MR_defaultLocalStoreUrl];

    XCTAssertEqualObjects(defaultStoreUrl, expectedStoreUrl, @"Store URL should be %@, actually is %@", [expectedStoreUrl absoluteString], [defaultStoreUrl absoluteString]);
}


- (void) testCanFindAURLInTheApplicationSupportLibraryForMacForASpecifiedStoreName
{
    NSString *storeFileName = @"NotTheDefaultStoreName.storefile";
    NSString *applicationSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *testStorePath = [applicationSupportDirectory stringByAppendingPathComponent:storeFileName];
    
    BOOL fileWasCreated = [[NSFileManager defaultManager] createFileAtPath:testStorePath contents:[storeFileName dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

    XCTAssertTrue(fileWasCreated, @"Expected file to have been created");

    NSURL *expectedStoreUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", applicationSupportDirectory, storeFileName]];
    
    NSURL *foundStoreUrl = [NSPersistentStore MR_urlForStoreName:storeFileName];
    
    XCTAssertEqualObjects(foundStoreUrl, expectedStoreUrl, @"Found store URL should be %@, actually is %@", [expectedStoreUrl absoluteString], [foundStoreUrl absoluteString]);

    [[NSFileManager defaultManager] removeItemAtPath:testStorePath error:nil];
}

#endif

@end
