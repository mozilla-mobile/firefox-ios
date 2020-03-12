//
//  SentryCrashReportStore_Tests.m
//
//  Created by Karl Stenerud on 2012-02-05.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "FileBasedTestCase.h"
#import "XCTestCase+SentryCrash.h"

#import "SentryCrashReportStore.h"

#include <inttypes.h>


#define REPORT_PREFIX @"CrashReport-SentryCrashTest"


@interface SentryCrashReportStore_Tests : FileBasedTestCase

@property(nonatomic,readwrite,retain) NSString* appName;
@property(nonatomic,readwrite,retain) NSString* reportStorePath;
@property(atomic,readwrite,assign) int64_t reportCounter;

@end

@implementation SentryCrashReportStore_Tests

@synthesize appName = _appName;
@synthesize reportStorePath = _reportStorePath;
@synthesize reportCounter = _reportCounter;

- (int64_t) getReportIDFromPath:(NSString*) path
{
    const char* filename = path.lastPathComponent.UTF8String;
    char scanFormat[100];
    snprintf(scanFormat, sizeof(scanFormat), "%s-report-%%" PRIx64 ".json", self.appName.UTF8String);

    int64_t reportID = 0;
    sscanf(filename, scanFormat, &reportID);
    return reportID;
}

- (void) setUp
{
    [super setUp];
    self.appName = @"myapp";
}

- (void) prepareReportStoreWithPathEnd:(NSString*) pathEnd
{
    self.reportStorePath = [self.tempPath stringByAppendingPathComponent:pathEnd];
    sentrycrashcrs_initialize(self.appName.UTF8String, self.reportStorePath.UTF8String);
}

- (NSArray*) getReportIDs
{
    int reportCount = sentrycrashcrs_getReportCount();
    int64_t rawReportIDs[reportCount];
    reportCount = sentrycrashcrs_getReportIDs(rawReportIDs, reportCount);
    NSMutableArray* reportIDs = [NSMutableArray new];
    for(int i = 0; i < reportCount; i++)
    {
        [reportIDs addObject:@(rawReportIDs[i])];
    }
    return reportIDs;
}

- (int64_t) writeCrashReportWithStringContents:(NSString*) contents
{
    NSData* crashData = [contents dataUsingEncoding:NSUTF8StringEncoding];
    char crashReportPath[SentryCrashCRS_MAX_PATH_LENGTH];
    sentrycrashcrs_getNextCrashReportPath(crashReportPath);
    [crashData writeToFile:[NSString stringWithUTF8String:crashReportPath] atomically:YES];
    return [self getReportIDFromPath:[NSString stringWithUTF8String:crashReportPath]];
}

- (int64_t) writeUserReportWithStringContents:(NSString*) contents
{
    NSData* data = [contents dataUsingEncoding:NSUTF8StringEncoding];
    return sentrycrashcrs_addUserReport(data.bytes, (int)data.length);
}

- (void) loadReportID:(int64_t) reportID
         reportString:(NSString* __autoreleasing *) reportString
{
    char* reportBytes = sentrycrashcrs_readReport(reportID);

    if(reportBytes == NULL)
    {
        reportString = nil;
    }
    else
    {
        *reportString = [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:reportBytes length:strlen(reportBytes)] encoding:NSUTF8StringEncoding];
    }
}

- (void) expectHasReportCount:(int) reportCount
{
    XCTAssertEqual(sentrycrashcrs_getReportCount(), reportCount);
}

- (void) expectReports:(NSArray*) reportIDs
            areStrings:(NSArray*) reportStrings
{
    for(NSUInteger i = 0; i < reportIDs.count; i++)
    {
        int64_t reportID = [reportIDs[i] longLongValue];
        NSString* reportString = reportStrings[i];
        NSString* loadedReportString;
        [self loadReportID:reportID reportString:&loadedReportString];
        XCTAssertEqualObjects(loadedReportString, reportString);
    }
}

- (void) testReportStorePathExists
{
    [self prepareReportStoreWithPathEnd:@"somereports/blah/2/x"];
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:self.reportStorePath]);
}

- (void) testCrashReportCount1
{
    [self prepareReportStoreWithPathEnd:@"testCrashReportCount1"];
    NSString* reportContents = @"Testing";
    [self writeCrashReportWithStringContents:reportContents];
    [self expectHasReportCount:1];
}


- (void) testStoresLoadsOneCrashReport
{
    [self prepareReportStoreWithPathEnd:@"testStoresLoadsOneCrashReport"];
    NSString* reportContents = @"Testing";
    int64_t reportID = [self writeCrashReportWithStringContents:reportContents];
    [self expectReports:@[@(reportID)] areStrings:@[reportContents]];
}

- (void) testStoresLoadsOneUserReport
{
    [self prepareReportStoreWithPathEnd:@"testStoresLoadsOneUserReport"];
    NSString* reportContents = @"Testing";
    int64_t reportID = [self writeUserReportWithStringContents:reportContents];
    [self expectReports:@[@(reportID)] areStrings:@[reportContents]];
}

- (void) testStoresLoadsMultipleReports
{
    [self prepareReportStoreWithPathEnd:@"testStoresLoadsMultipleReports"];
    NSMutableArray* reportIDs = [NSMutableArray new];
    NSArray* reportContents = @[@"report1", @"report2", @"report3", @"report4"];
    [reportIDs addObject:@([self writeCrashReportWithStringContents:reportContents[0]])];
    [reportIDs addObject:@([self writeUserReportWithStringContents:reportContents[1]])];
    [reportIDs addObject:@([self writeUserReportWithStringContents:reportContents[2]])];
    [reportIDs addObject:@([self writeCrashReportWithStringContents:reportContents[3]])];
    [self expectHasReportCount:4];
    [self expectReports:reportIDs areStrings:reportContents];
}

- (void) testDeleteAllReports
{
    [self prepareReportStoreWithPathEnd:@"testDeleteAllReports"];
    [self writeCrashReportWithStringContents:@"1"];
    [self writeUserReportWithStringContents:@"2"];
    [self writeUserReportWithStringContents:@"3"];
    [self writeCrashReportWithStringContents:@"4"];
    [self expectHasReportCount:4];
    sentrycrashcrs_deleteAllReports();
    [self expectHasReportCount:0];
}

- (void) testPruneReports
{
    int reportStorePrunesTo = 7;
    sentrycrashcrs_setMaxReportCount(reportStorePrunesTo);
    [self prepareReportStoreWithPathEnd:@"testDeleteAllReports"];
    int64_t prunedReportID = [self writeUserReportWithStringContents:@"u1"];
    [self writeCrashReportWithStringContents:@"c1"];
    [self writeUserReportWithStringContents:@"u2"];
    [self writeCrashReportWithStringContents:@"c2"];
    [self writeCrashReportWithStringContents:@"c3"];
    [self writeUserReportWithStringContents:@"u3"];
    [self writeCrashReportWithStringContents:@"c4"];
    [self writeCrashReportWithStringContents:@"c5"];
    [self expectHasReportCount:8];
    // Calls sentrycrashcrs_initialize() again, which prunes the reports.
    [self prepareReportStoreWithPathEnd:@"testDeleteAllReports"];
    [self expectHasReportCount:reportStorePrunesTo];
    NSArray* reportIDs = [self getReportIDs];
    XCTAssertFalse([reportIDs containsObject:@(prunedReportID)]);
}

- (void) testStoresLoadsWithUnicodeAppName
{
    self.appName = @"ЙогуртЙод";
    [self prepareReportStoreWithPathEnd:@"testStoresLoadsWithUnicodeAppName"];
    NSString* reportContents = @"Testing";
    int64_t reportID = [self writeCrashReportWithStringContents:reportContents];
    [self expectReports:@[@(reportID)] areStrings:@[reportContents]];
}

@end
