//
//  NSDate+SentryExtras.h
//  Sentry
//
//  Created by Daniel Griesser on 19/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (SentryExtras)

+ (NSDate *)sentry_fromIso8601String:(NSString *)string;

- (NSString *)sentry_toIso8601String;

@end

NS_ASSUME_NONNULL_END
