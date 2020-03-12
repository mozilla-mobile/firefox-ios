//
//  SentryDsn.h
//  Sentry
//
//  Created by Daniel Griesser on 03/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryDsn : NSObject

@property(nonatomic, strong) NSURL *url;

- (_Nullable instancetype)initWithString:(NSString *)dsnString didFailWithError:(NSError *_Nullable *_Nullable)error;

- (NSString *)getHash;

@end

NS_ASSUME_NONNULL_END
