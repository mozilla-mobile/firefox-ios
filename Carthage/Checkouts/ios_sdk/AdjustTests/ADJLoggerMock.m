//
//  ADJLoggerMock.m
//  Adjust
//
//  Created by Pedro Filipe on 10/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJLoggerMock.h"

static NSString * const kLogTag = @"AdjustTests";

@interface ADJLoggerMock()

@property (nonatomic, strong) NSMutableString *logBuffer;
@property (nonatomic, strong) NSDictionary *logMap;

@end

@implementation ADJLoggerMock

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    [self reset];

    return self;
}

- (void) reset {
    self.logBuffer = [[NSMutableString alloc] init];
    self.logMap = @{
                    @1 : [NSMutableArray array],
                    @2 : [NSMutableArray array],
                    @3 : [NSMutableArray array],
                    @4 : [NSMutableArray array],
                    @5 : [NSMutableArray array],
                    @6 : [NSMutableArray array],
                    @7 : [NSMutableArray array],
                    @8 : [NSMutableArray array],
                    };

    [self test:@"logger reset"];
}

- (NSString *)description {
    return self.logBuffer;
}

- (BOOL)deleteUntil:(NSInteger)logLevel beginsWith:(NSString *)beginsWith {
    NSMutableArray  *logArray = (NSMutableArray *)self.logMap[@(logLevel)];
    for (int i = 0; i < [logArray count]; i++) {
        NSString *logMessage = logArray[i];
        if ([logMessage hasPrefix:beginsWith]) {
            [logArray removeObjectsInRange:NSMakeRange(0, i + 1)];
            [self check:@"found %@", beginsWith];
            //NSLog(@"%@ found", beginsWith);
            return YES;
        }
    }
    [self check:@"%@ is not in: %@", beginsWith, [logArray componentsJoinedByString:@","]];
    //NSLog(@"%@ not in (%@)", beginsWith, [logArray componentsJoinedByString:@","]);
    return NO;
}

- (void)setLogLevel:(ADJLogLevel)logLevel {
    [self test:@"ADJLogger setLogLevel: %d", logLevel];
}

- (void)check:(NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelCheck logPrefix:@"c" format:format parameters:parameters];
}

- (void)test:(NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelTest logPrefix:@"t" format:format parameters:parameters];
}

- (void)verbose:(NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelVerbose logPrefix:@"v" format:format parameters:parameters];
}

- (void)debug:  (NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelDebug logPrefix:@"d" format:format parameters:parameters];
}

- (void)info:   (NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelInfo logPrefix:@"i" format:format parameters:parameters];
}

- (void)warn:   (NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelWarn logPrefix:@"w" format:format parameters:parameters];
}

- (void)error:  (NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelError logPrefix:@"e" format:format parameters:parameters];
}

- (void)assert: (NSString *)format, ... {
    va_list parameters; va_start(parameters, format);
    [self logLevel:ADJLogLevelAssert logPrefix:@"a" format:format parameters:parameters];
}

// private implementation
- (void)logLevel:(NSInteger)logLevel  logPrefix:(NSString *)logPrefix format:(NSString *)format parameters:(va_list)parameters {
    NSString *formatedMessage = [[NSString alloc] initWithFormat:format arguments:parameters];
    va_end(parameters);

    NSString *logMessage = [NSString stringWithFormat:@"\t[%@]%@: %@", kLogTag, logPrefix, formatedMessage];

    [self.logBuffer appendFormat:@"%@\n",logMessage];

    NSMutableArray *logArray = (NSMutableArray *)self.logMap[@(logLevel)];
    [logArray addObject:formatedMessage];

    NSArray *lines = [formatedMessage componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSLog(@"\t[%@]%@: %@", kLogTag, logPrefix, line);
    }
}

@end
