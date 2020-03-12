//
//  ADJLogger.m
//  Adjust
//
//  Created by Christian Wellenbrock on 2012-11-15.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//

#import "ADJLogger.h"

static NSString * const kLogTag = @"Adjust";

@interface ADJLogger()

@property (nonatomic, assign) ADJLogLevel loglevel;
@property (nonatomic, assign) BOOL logLevelLocked;
@property (nonatomic, assign) BOOL isProductionEnvironment;

@end

#pragma mark -
@implementation ADJLogger

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    //default values
    _loglevel = ADJLogLevelInfo;
    self.logLevelLocked = NO;
    self.isProductionEnvironment = NO;

    return self;
}

- (void)setLogLevel:(ADJLogLevel)logLevel
isProductionEnvironment:(BOOL)isProductionEnvironment
{
    if (self.logLevelLocked) {
        return;
    }
    _loglevel = logLevel;
    self.isProductionEnvironment = isProductionEnvironment;
}

- (void)lockLogLevel {
    self.logLevelLocked = YES;
}

- (void)verbose:(NSString *)format, ... {
    if (self.isProductionEnvironment) return;
    if (self.loglevel > ADJLogLevelVerbose) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"v" format:format parameters:parameters];
}

- (void)debug:(NSString *)format, ... {
    if (self.isProductionEnvironment) return;
    if (self.loglevel > ADJLogLevelDebug) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"d" format:format parameters:parameters];
}

- (void)info:(NSString *)format, ... {
    if (self.isProductionEnvironment) return;
    if (self.loglevel > ADJLogLevelInfo) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"i" format:format parameters:parameters];
}

- (void)warn:(NSString *)format, ... {
    if (self.isProductionEnvironment) return;
    if (self.loglevel > ADJLogLevelWarn) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"w" format:format parameters:parameters];
}
- (void)warnInProduction:(nonnull NSString *)format, ... {
    if (self.loglevel > ADJLogLevelWarn) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"w" format:format parameters:parameters];
}

- (void)error:(NSString *)format, ... {
    if (self.isProductionEnvironment) return;
    if (self.loglevel > ADJLogLevelError) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"e" format:format parameters:parameters];
}

- (void)assert:(NSString *)format, ... {
    if (self.isProductionEnvironment) return;
    if (self.loglevel > ADJLogLevelAssert) return;
    va_list parameters; va_start(parameters, format);
    [self logLevel:@"a" format:format parameters:parameters];
}

// private implementation
- (void)logLevel:(NSString *)logLevel format:(NSString *)format parameters:(va_list)parameters {
    NSString *string = [[NSString alloc] initWithFormat:format arguments:parameters];
    va_end(parameters);

    NSArray *lines = [string componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        NSLog(@"\t[%@]%@: %@", kLogTag, logLevel, line);
    }
}

+ (ADJLogLevel)logLevelFromString:(NSString *)logLevelString {
    if ([logLevelString isEqualToString:@"verbose"])
        return ADJLogLevelVerbose;

    if ([logLevelString isEqualToString:@"debug"])
        return ADJLogLevelDebug;

    if ([logLevelString isEqualToString:@"info"])
        return ADJLogLevelInfo;

    if ([logLevelString isEqualToString:@"warn"])
        return ADJLogLevelWarn;

    if ([logLevelString isEqualToString:@"error"])
        return ADJLogLevelError;

    if ([logLevelString isEqualToString:@"assert"])
        return ADJLogLevelAssert;

    if ([logLevelString isEqualToString:@"suppress"])
        return ADJLogLevelSuppress;

    // default value if string does not match
    return ADJLogLevelInfo;
}

@end
