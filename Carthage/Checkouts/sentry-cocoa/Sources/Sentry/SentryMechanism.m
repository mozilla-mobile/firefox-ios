//
//  SentryMechanism.m
//  Sentry
//
//  Created by Daniel Griesser on 17.05.18.
//  Copyright © 2018 Sentry. All rights reserved.
//

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentryMechanism.h>

#else
#import "SentryMechanism.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation SentryMechanism

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        self.type = type;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)serialize {
    NSMutableDictionary *serializedData = @{@"type": self.type}.mutableCopy;
    
    [serializedData setValue:self.handled forKey:@"handled"];
    [serializedData setValue:self.desc forKey:@"description"];
    [serializedData setValue:self.meta forKey:@"meta"];
    [serializedData setValue:self.data forKey:@"data"];
    [serializedData setValue:self.helpLink forKey:@"help_link"];
    
    return serializedData;
}

@end

NS_ASSUME_NONNULL_END

