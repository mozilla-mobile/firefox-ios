//
//  ADJSuccessResponseData.h
//  adjust
//
//  Created by Pedro Filipe on 05/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJSessionSuccess : NSObject <NSCopying>

// message from the server.
@property (nonatomic, copy) NSString * message;

// timeStamp from the server.
@property (nonatomic, copy) NSString * timeStamp;

// adid of the device.
@property (nonatomic, copy) NSString * adid;

// the server response in json format
@property (nonatomic, strong) NSDictionary *jsonResponse;

+ (ADJSessionSuccess *)sessionSuccessResponseData;
- (id)init;

@end
