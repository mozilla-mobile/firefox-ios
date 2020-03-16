//
//  SentryNSUIntegerValue.h
//  Sentry
//
//  Created by Crazy凡 on 2019/3/21.
//  Copyright © 2019 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SentryNSUIntegerValue)
- (NSUInteger)unsignedLongLongValue;
@end

NS_ASSUME_NONNULL_END
