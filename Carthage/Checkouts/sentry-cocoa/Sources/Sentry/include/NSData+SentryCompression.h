//
//  NSData+SentryCompression.h
//  Sentry
//
//  Created by Daniel Griesser on 08/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (SentryCompression)

- (NSData *_Nullable)sentry_gzippedWithCompressionLevel:(NSInteger)compressionLevel
                                           error:(NSError *_Nullable *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
