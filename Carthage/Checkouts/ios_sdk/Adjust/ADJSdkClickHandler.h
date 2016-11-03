//
//  ADJSdkClickHandler.h
//  Adjust
//
//  Created by Pedro Filipe on 21/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJActivityPackage.h"

@protocol ADJSdkClickHandler

- (id)initWithStartsSending:(BOOL)startsSending;

- (void)pauseSending;
- (void)resumeSending;
- (void)sendSdkClick:(ADJActivityPackage *)sdkClickPackage;
- (void)teardown;

@end

@interface ADJSdkClickHandler : NSObject <ADJSdkClickHandler>

+ (id<ADJSdkClickHandler>)handlerWithStartsSending:(BOOL)startsSending;

@end
