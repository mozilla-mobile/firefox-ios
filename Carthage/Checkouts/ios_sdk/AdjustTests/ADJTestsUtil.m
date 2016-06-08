//
//  ADJTestsUtil.m
//  Adjust
//
//  Created by Pedro Filipe on 12/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <XCTest/XCTestAssertionsImpl.h>
#import "ADJTestsUtil.h"
#import "ADJPackageBuilder.h"
#import "ADJAdjustFactory.h"

@interface ADJTestsUtil()

@property (nonatomic, strong) ADJLoggerMock* loggerMock;

@end

@implementation ADJTestsUtil

- (id)initWithLoggerMock:(ADJLoggerMock *)loggerMock {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = loggerMock;

    return self;
}

+ (NSString *)getFilename:(NSString *)filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filepath = [path stringByAppendingPathComponent:filename];
    return filepath;
}

+ (BOOL)deleteFile:(NSString *)filename logger:(ADJLoggerMock *)loggerMock {
    NSString *filepath = [ADJTestsUtil getFilename:filename];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL exists = [fileManager fileExistsAtPath:filepath];
    if (!exists) {
        [loggerMock test:@"file %@ does not exist at path %@", filename, filepath];
        return  YES;
    }
    BOOL deleted = [fileManager removeItemAtPath:filepath error:&error];

    if (!deleted) {
        [loggerMock test:@"unable to delete file %@ at path %@", filename, filepath];
    }

    if (error) {
        [loggerMock test:@"error (%@) deleting file %@", [error localizedDescription], filename];
    }

    return deleted;
}

+ (ADJActivityPackage *)getUnknowPackage:(NSString*)suffix
{
    ADJActivityPackage *activityPackage = [[ADJActivityPackage alloc] init];
    activityPackage.suffix = suffix;
    return activityPackage;
}

+ (ADJActivityPackage *)getClickPackage:(NSString*)suffix
{
    ADJActivityPackage *activityPackage = [[ADJActivityPackage alloc] init];
    activityPackage.activityKind = ADJActivityKindClick;
    activityPackage.suffix = suffix;
    return activityPackage;
}

@end
