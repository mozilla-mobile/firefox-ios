//
//  SentryJavaScriptBridgeHelper.m
//  Sentry
//
//  Created by Daniel Griesser on 23.10.17.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryJavaScriptBridgeHelper.h>
#import <Sentry/SentryError.h>
#import <Sentry/SentryLog.h>
#import <Sentry/SentryEvent.h>
#import <Sentry/SentryFrame.h>
#import <Sentry/SentryException.h>
#import <Sentry/SentryThread.h>
#import <Sentry/SentryStacktrace.h>
#import <Sentry/SentryUser.h>
#import <Sentry/SentryBreadcrumb.h>

#else
#import "SentryJavaScriptBridgeHelper.h"
#import "SentryError.h"
#import "SentryLog.h"
#import "SentryEvent.h"
#import "SentryFrame.h"
#import "SentryException.h"
#import "SentryThread.h"
#import "SentryStacktrace.h"
#import "SentryUser.h"
#import "SentryBreadcrumb.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryJavaScriptBridgeHelper

+ (NSNumberFormatter *)numberFormatter {
    static dispatch_once_t onceToken;
    static NSNumberFormatter *formatter = nil;
    dispatch_once(&onceToken, ^{
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterNoStyle;
    });
    return formatter;
}

+ (NSRegularExpression *)frameRegex {
    static dispatch_once_t onceTokenRegex;
    static NSRegularExpression *regex = nil;
    dispatch_once(&onceTokenRegex, ^{
        //        NSString *pattern = @"at (.+?) \\((?:(.+?):([0-9]+?):([0-9]+?))\\)"; // Regex with debugger
        // Regex taken from
        // https://github.com/getsentry/raven-js/blob/66a5db5333c22f36819c95844a1583489c1d2661/vendor/TraceKit/tracekit.js#L372
        NSString *pattern = @"^\\s*(.*?)(?:\\((.*?)\\))?(?:^|@)((?:app|file|https?|blob|chrome|webpack|resource|\\[native).*?|[^@]*bundle)(?::(\\d+))?(?::(\\d+))?\\s*$"; // Regex without debugger
        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    });
    return regex;
}

+ (NSArray *)parseRavenFrames:(NSArray *)ravenFrames {
    NSNumberFormatter *formatter = [self.class numberFormatter];
    NSMutableArray *frames = [NSMutableArray array];
    for (NSDictionary *ravenFrame in ravenFrames) {
        NSMutableDictionary *frame = [[NSMutableDictionary alloc] initWithDictionary:@{@"methodName": ravenFrame[@"function"],
                                                                                       @"file": ravenFrame[@"filename"]}];
        if (ravenFrame[@"lineno"] != NSNull.null) {
            [frame addEntriesFromDictionary:@{@"column": [formatter numberFromString:[NSString stringWithFormat:@"%@", ravenFrame[@"colno"]]],
                                              @"lineNumber": [formatter numberFromString:[NSString stringWithFormat:@"%@", ravenFrame[@"lineno"]]]}];

        }
        [frames addObject:frame];
    }
    return frames;
}

+ (NSArray *)parseJavaScriptStacktrace:(NSString *)stacktrace {
    NSNumberFormatter *formatter = [self.class numberFormatter];
    NSArray *lines = [stacktrace componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *frames = [NSMutableArray array];
    for (NSString *line in lines) {
        NSRange searchedRange = NSMakeRange(0, [line length]);
        NSArray *matches = [[self.class frameRegex] matchesInString:line options:0 range:searchedRange];
        for (NSTextCheckingResult *match in matches) {
            NSMutableDictionary *frame = [[NSMutableDictionary alloc] initWithDictionary:@{@"methodName": [line substringWithRange:[match rangeAtIndex:1]],
                                                                                           @"file": [line substringWithRange:[match rangeAtIndex:3]]}];
            if ([match rangeAtIndex:5].location != NSNotFound) {
                [frame addEntriesFromDictionary:@{@"column": [formatter numberFromString:[line substringWithRange:[match rangeAtIndex:5]]],
                                                  @"lineNumber": [formatter numberFromString:[line substringWithRange:[match rangeAtIndex:4]]]}];
            }
            [frames addObject:frame];
        }
    }
    return frames;
}

+ (SentryBreadcrumb *)createSentryBreadcrumbFromJavaScriptBreadcrumb:(NSDictionary *)jsonBreadcrumb {
    NSString *level = jsonBreadcrumb[@"level"];
    if (level == nil) {
        level = @"info";
    }
    SentryBreadcrumb *breadcrumb = [[SentryBreadcrumb alloc] initWithLevel:[self.class sentrySeverityFromLevel:level]
                                                             category:jsonBreadcrumb[@"category"]];
    breadcrumb.message = jsonBreadcrumb[@"message"];
    if ([jsonBreadcrumb[@"timestamp"] integerValue] > 0) {
        breadcrumb.timestamp = [NSDate dateWithTimeIntervalSince1970:[jsonBreadcrumb[@"timestamp"] integerValue]];
    } else {
        breadcrumb.timestamp = [NSDate date];
    }

    breadcrumb.type = jsonBreadcrumb[@"type"];
    breadcrumb.data = jsonBreadcrumb[@"data"];
    return breadcrumb;
}

+ (SentryEvent *)createSentryEventFromJavaScriptEvent:(NSDictionary *)jsonEvent {
    SentrySeverity level = [self.class sentrySeverityFromLevel:jsonEvent[@"level"]];
    SentryEvent *event = [[SentryEvent alloc] initWithLevel:level];
    if (jsonEvent[@"event_id"]) {
        event.eventId = jsonEvent[@"event_id"];
    }
    if (jsonEvent[@"message"]) {
        event.message = jsonEvent[@"message"];
    }
    if (jsonEvent[@"logger"]) {
        event.logger = jsonEvent[@"logger"];
    }
    if (jsonEvent[@"fingerprint"]) {
        event.fingerprint = jsonEvent[@"fingerprint"];
    }
    if (jsonEvent[@"environment"]) {
        event.environment = jsonEvent[@"environment"];
    }
    event.tags = [self.class sanitizeDictionary:jsonEvent[@"tags"]];
    if (jsonEvent[@"extra"]) {
        event.extra = jsonEvent[@"extra"];
    }
    event.user = [self.class createSentryUserFromJavaScriptUser:jsonEvent[@"user"]];
    if (jsonEvent[@"exception"] || (jsonEvent[@"stacktrace"] && jsonEvent[@"stacktrace"][@"frames"])) {
        NSArray *jsStacktrace = @[];
        NSString *exceptionType = @"";
        NSString *exceptionValue = @"";
        if (jsonEvent[@"exception"]) {
            NSDictionary *exception;
            if ([jsonEvent valueForKeyPath:@"exception.values"] && [jsonEvent valueForKeyPath:@"exception.values"][0] != NSNull.null) {
                exception = jsonEvent[@"exception"][@"values"][0];
            } else {
                exception = jsonEvent[@"exception"][0];
            }
            jsStacktrace = exception[@"stacktrace"][@"frames"];
            exceptionType = exception[@"type"];
            exceptionValue = exception[@"value"];
        } else if (jsonEvent[@"stacktrace"] && jsonEvent[@"stacktrace"][@"frames"]) {
            jsStacktrace = jsonEvent[@"stacktrace"][@"frames"];
            exceptionValue = jsonEvent[@"message"];
            if (jsonEvent[@"type"]) {
                exceptionType = jsonEvent[@"type"];
            }
        }
        NSMutableArray *frames = [NSMutableArray array];
        NSArray<SentryFrame *> *stacktrace = [self.class convertReactNativeStacktrace:
                                              [self.class parseRavenFrames:jsStacktrace]];
        for (NSInteger i = (stacktrace.count-1); i >= 0; i--) {
            [frames addObject:[stacktrace objectAtIndex:i]];
        }
        [self.class addExceptionToEvent:event type:exceptionType value:exceptionValue frames:frames];
    }
    return event;
}

+ (NSArray<SentryFrame *> *)convertReactNativeStacktrace:(NSArray *)stacktrace {
    NSMutableArray<SentryFrame *> *frames = [NSMutableArray new];
    for (NSDictionary *frame in stacktrace) {
        if (nil == frame[@"methodName"]) {
            continue;
        }
        NSString *simpleFilename = [[[frame[@"file"] lastPathComponent] componentsSeparatedByString:@"?"] firstObject];
        SentryFrame *sentryFrame = [[SentryFrame alloc] init];
        sentryFrame.fileName = [NSString stringWithFormat:@"app:///%@", simpleFilename];
        sentryFrame.function = frame[@"methodName"];
        if (nil != frame[@"lineNumber"]) {
            sentryFrame.lineNumber = frame[@"lineNumber"];
        }
        if (nil != frame[@"column"]) {
            sentryFrame.columnNumber = frame[@"column"];
        }
        sentryFrame.platform = @"javascript";
        [frames addObject:sentryFrame];
    }
    return [frames reverseObjectEnumerator].allObjects;
}

+ (void)addExceptionToEvent:(SentryEvent *)event type:(NSString *)type value:(NSString *)value frames:(NSArray *)frames {
    SentryException *sentryException = [[SentryException alloc] initWithValue:value type:type];
    SentryThread *thread = [[SentryThread alloc] initWithThreadId:@(99)];
    thread.crashed = @(YES);
    thread.stacktrace = [[SentryStacktrace alloc] initWithFrames:frames registers:@{}];
    sentryException.thread = thread;
    event.exceptions = @[sentryException];
}

+ (SentryUser *_Nullable)createSentryUserFromJavaScriptUser:(NSDictionary *)user {
    NSString *userId = nil;
    if (nil != user[@"userID"]) {
        userId = [NSString stringWithFormat:@"%@", user[@"userID"]];
    } else if (nil != user[@"userId"]) {
        userId = [NSString stringWithFormat:@"%@", user[@"userId"]];
    } else if (nil != user[@"id"]) {
        userId = [NSString stringWithFormat:@"%@", user[@"id"]];
    }
    SentryUser *sentryUser = [[SentryUser alloc] init];
    if (nil != userId) {
        sentryUser.userId = userId;
    }
    if (nil != user[@"email"]) {
        sentryUser.email = [NSString stringWithFormat:@"%@", user[@"email"]];
    }
    if (nil != user[@"username"]) {
        sentryUser.username = [NSString stringWithFormat:@"%@", user[@"username"]];
    }
    // If there is neither id email or username we return nil
    if (sentryUser.userId == nil && sentryUser.email == nil && sentryUser.username == nil) {
        return nil;
    }
    sentryUser.extra = user[@"extra"];
    return sentryUser;
}

+ (SentrySeverity)sentrySeverityFromLevel:(NSString *)level {
    if ([level isEqualToString:@"fatal"]) {
        return kSentrySeverityFatal;
    } else if ([level isEqualToString:@"warning"]) {
        return kSentrySeverityWarning;
    } else if ([level isEqualToString:@"info"] || [level isEqualToString:@"log"]) {
        return kSentrySeverityInfo;
    } else if ([level isEqualToString:@"debug"]) {
        return kSentrySeverityDebug;
    } else if ([level isEqualToString:@"error"]) {
        return kSentrySeverityError;
    }
    return kSentrySeverityError;
}

+ (SentryLogLevel)sentryLogLevelFromJavaScriptLevel:(int)level {
    switch (level) {
        case 1:
            return kSentryLogLevelError;
        case 2:
            return kSentryLogLevelDebug;
        case 3:
            return kSentryLogLevelVerbose;
        default:
            return kSentryLogLevelNone;
    }
}

+ (NSDictionary *)sanitizeDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *key in dictionary.allKeys) {
        [dict setObject:[NSString stringWithFormat:@"%@", [dictionary objectForKey:key]] forKey:key];
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

NS_ASSUME_NONNULL_END
