/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "FXCrashDetector.h"

static NSString * const FXCrashDetectorPList = @"FXCrashLog.plist";
static NSString * const FXCrashExceptionKey = @"FXDefaultsCrashExceptionKey";
static NSString * const FXCrashSignalKey = @"FXDefaultsCrashSignalKey";

@interface FXCrashDetectorFileBasedData : NSObject <FXCrashDetectorData>
@property (nonatomic, strong) NSMutableDictionary *plistFile;
@property (nonatomic, copy) NSString *plistFilePath;
@end

@implementation FXCrashDetectorFileBasedData

- (id)init
{
    if (self = [super init]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        self.plistFilePath = [documentsPath stringByAppendingPathComponent:FXCrashDetectorPList];
        if (![fileManager fileExistsAtPath:self.plistFilePath]) {
            self.plistFile = [NSMutableDictionary dictionary];
        } else {
            self.plistFile = [NSMutableDictionary dictionaryWithContentsOfFile:self.plistFilePath];
        }
    }
    return self;
}

- (void)setExceptionForPreviousCrash:(NSException *)exception
{
    NSData *exceptionData = [NSKeyedArchiver archivedDataWithRootObject:exception];
    self.plistFile[FXCrashExceptionKey] = exceptionData;
    [self.plistFile writeToFile:self.plistFilePath atomically:YES];
}

- (void)setSignalForPreviousCrash:(int)signal
{
    self.plistFile[FXCrashSignalKey] = @(signal);
    [self.plistFile writeToFile:self.plistFilePath atomically:YES];
}

- (void)clearPreviousCrash
{
    [self.plistFile removeObjectForKey:FXCrashSignalKey];
    [self.plistFile removeObjectForKey:FXCrashExceptionKey];
    [self.plistFile writeToFile:self.plistFilePath atomically:YES];
}

- (BOOL)containsCrash
{
    return self.plistFile[FXCrashExceptionKey] != nil || self.plistFile[FXCrashSignalKey] != nil;
}

@end

@implementation FXCrashDetector

static id<FXCrashDetectorData> _crashData;
static FXCrashDetector *_detector;

+ (id)sharedDetector
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _crashData = [[FXCrashDetectorFileBasedData alloc] init];
        _detector = [[FXCrashDetector alloc] init];
    });

    return _detector;
}

- (id<FXCrashDetectorData>)crashData
{
    return _crashData;
}

- (BOOL)hasCrashed
{
    return [self.crashData containsCrash];
}

- (void)listenForCrashes
{
    NSSetUncaughtExceptionHandler(&HandleException);
    signal(SIGABRT, HandleSignal);
    signal(SIGILL, HandleSignal);
    signal(SIGBUS, HandleSignal);
    signal(SIGSEGV, HandleSignal);
    signal(SIGFPE, HandleSignal);
    signal(SIGPIPE, HandleSignal);
}

#pragma mark - Private Handlers

void HandleException(NSException *exception)
{
    [_crashData setExceptionForPreviousCrash:exception];
}

void HandleSignal(int signal)
{
    [_crashData setSignalForPreviousCrash:signal];
}

@end
