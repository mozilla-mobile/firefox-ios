//
//  SentryException.m
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryException.h>
#import <Sentry/SentryThread.h>
#import <Sentry/SentryMechanism.h>
#import <Sentry/SentryStacktrace.h>

#else
#import "SentryException.h"
#import "SentryThread.h"
#import "SentryMechanism.h"
#import "SentryStacktrace.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryException

- (instancetype)initWithValue:(NSString *)value type:(NSString *)type {
    self = [super init];
    if (self) {
        self.value = value;
        self.type = type;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serialize {
    NSMutableDictionary *serializedData = [NSMutableDictionary new];

    [serializedData setValue:self.value forKey:@"value"];
    [serializedData setValue:self.type forKey:@"type"];
    [serializedData setValue:[self.mechanism serialize] forKey:@"mechanism"];
    [serializedData setValue:self.module forKey:@"module"];
    [serializedData setValue:self.thread.threadId forKey:@"thread_id"];
    [serializedData setValue:[self.thread.stacktrace serialize] forKey:@"stacktrace"];

    return serializedData;
}

@end

NS_ASSUME_NONNULL_END
