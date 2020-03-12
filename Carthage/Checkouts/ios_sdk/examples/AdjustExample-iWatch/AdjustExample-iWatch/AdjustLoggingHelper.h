//
//  AdjustLoggingHelper.h
//  AdjustExample-iWatch
//
//  Created by Uglješa Erceg on 29/04/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AdjustLoggingHelper : NSObject

+ (id)sharedInstance;

- (void)logText:(NSString *)text;

@end
