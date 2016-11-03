//
//  AdjustLoggingHelper.m
//  AdjustExample-iWatch
//
//  Created by Uglješa Erceg on 29/04/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import "AdjustLoggingHelper.h"

@implementation AdjustLoggingHelper

+ (id)sharedInstance {
    static AdjustLoggingHelper *sharedLogger = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedLogger = [[self alloc] init];
    });

    return sharedLogger;
}

- (void)logText:(NSString *)text {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [documentPaths objectAtIndex:0];
    NSString *logPath = [[NSString alloc] initWithFormat:@"%@",[documentsDir stringByAppendingPathComponent:@"AdjustLog.txt"]];
    NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:logPath];

    if (fileHandler == nil) {
        [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
        fileHandler = [NSFileHandle fileHandleForWritingAtPath:logPath];
    }

    NSDateFormatter *formatter;
    NSString        *dateString;

    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MM-yyyy HH:mm"];

    dateString = [NSString stringWithFormat:@"\n[%@] ", [formatter stringFromDate:[NSDate date]]];

    [fileHandler seekToEndOfFile];
    [fileHandler writeData:[dateString dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandler closeFile];
}

@end
