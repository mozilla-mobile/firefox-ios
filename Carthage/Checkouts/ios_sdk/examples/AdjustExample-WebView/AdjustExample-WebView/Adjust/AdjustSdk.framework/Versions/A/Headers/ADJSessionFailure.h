//
//  ADJFailureResponseData.h
//  adjust
//
//  Created by Pedro Filipe on 05/01/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJSessionFailure : NSObject <NSCopying>

// error message from the server or the sdk.
@property (nonatomic, copy) NSString * message;

// timeStamp from the server.
@property (nonatomic, copy) NSString * timeStamp;

// adid of the device.
@property (nonatomic, copy) NSString * adid;

// indicates if the package will be retried to be send later
@property (nonatomic, assign) BOOL willRetry;

// the server response in json format
@property (nonatomic, strong) NSDictionary *jsonResponse;

+ (ADJSessionFailure *)sessionFailureResponseData;
- (id)init;

@end
