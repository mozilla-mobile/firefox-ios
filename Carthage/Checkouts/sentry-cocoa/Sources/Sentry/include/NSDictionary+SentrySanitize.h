//
//  NSDictionary+SentrySanitize.h
//  Sentry
//
//  Created by Daniel Griesser on 16/06/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (SentrySanitize)

- (NSDictionary *)sentry_sanitize;

@end
