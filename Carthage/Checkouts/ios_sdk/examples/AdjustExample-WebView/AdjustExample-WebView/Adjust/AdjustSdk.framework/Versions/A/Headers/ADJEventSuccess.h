//
//  ADJEventSuccess.h
//  adjust
//
//  Created by Pedro Filipe on 17/02/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJEventSuccess : NSObject

// message from the server.
@property (nonatomic, copy) NSString * message;

// timeStamp from the server.
@property (nonatomic, copy) NSString * timeStamp;

// adid of the device.
@property (nonatomic, copy) NSString * adid;

// event token of the tracked event.
@property (nonatomic, copy) NSString * eventToken;

// the server response in json format
@property (nonatomic, strong) NSDictionary *jsonResponse;

+ (ADJEventSuccess *)eventSuccessResponseData;
- (id)init;

@end
