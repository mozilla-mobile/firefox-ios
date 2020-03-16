//
//  SentryCrashReportConverter.h
//  Sentry
//
//  Created by Daniel Griesser on 10/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SentryEvent;

NS_ASSUME_NONNULL_BEGIN

@interface SentryCrashReportConverter : NSObject

@property(nonatomic, strong) NSDictionary *userContext;

- (instancetype)initWithReport:(NSDictionary *)report;

- (SentryEvent *)convertReportToEvent;

@end

NS_ASSUME_NONNULL_END
