//
//  URLRequest.h
//  AdjustExample-iOS
//
//  Created by Uglješa Erceg on 02/12/15.
//  Copyright © 2015 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface URLRequest : NSObject

+ (void)forgetDeviceWithAppToken:(NSString *)appToken
                            idfv:(NSString *)idfv
                 responseHandler:(void (^)(NSString *response))responseHandler;

@end
