//
//  ADJSdkClickHandler.h
//  Adjust SDK
//
//  Created by Pedro Filipe (@nonelse) on 21st April 2016.
//  Copyright © 2016 Adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJActivityPackage.h"
#import "ADJActivityHandler.h"

@protocol ADJSdkClickHandler

- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                startsSending:(BOOL)startsSending;
- (void)pauseSending;
- (void)resumeSending;
- (void)sendSdkClick:(ADJActivityPackage *)sdkClickPackage;
- (void)teardown;

@end

@interface ADJSdkClickHandler : NSObject <ADJSdkClickHandler>

+ (id<ADJSdkClickHandler>)handlerWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                                       startsSending:(BOOL)startsSending;

@end
