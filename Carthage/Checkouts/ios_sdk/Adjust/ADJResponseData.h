//
//  ADJResponseData.h
//  adjust
//
//  Created by Pedro Filipe on 07/12/15.
//  Copyright © 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ADJAttribution.h"
#import "ADJEventSuccess.h"
#import "ADJEventFailure.h"
#import "ADJSessionSuccess.h"
#import "ADJSessionFailure.h"
#import "ADJActivityPackage.h"

typedef NS_ENUM(int, ADJTrackingState) {
    ADJTrackingStateOptedOut = 1
};

@interface ADJResponseData : NSObject <NSCopying>

@property (nonatomic, assign) ADJActivityKind activityKind;

@property (nonatomic, copy) NSString *message;

@property (nonatomic, copy) NSString *timeStamp;

@property (nonatomic, copy) NSString *adid;

@property (nonatomic, assign) BOOL success;

@property (nonatomic, assign) BOOL willRetry;

@property (nonatomic, assign) ADJTrackingState trackingState;

@property (nonatomic, strong) NSDictionary *jsonResponse;

@property (nonatomic, copy) ADJAttribution *attribution;

- (id)init;

+ (ADJResponseData *)responseData;

+ (id)buildResponseData:(ADJActivityPackage *)activityPackage;

@end

@interface ADJSessionResponseData : ADJResponseData

- (ADJSessionSuccess *)successResponseData;

- (ADJSessionFailure *)failureResponseData;

@end

@interface ADJSdkClickResponseData : ADJResponseData
@end

@interface ADJEventResponseData : ADJResponseData

@property (nonatomic, copy) NSString *eventToken;

@property (nonatomic, copy) NSString *callbackId;

- (ADJEventSuccess *)successResponseData;

- (ADJEventFailure *)failureResponseData;

- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage;

+ (ADJResponseData *)responseDataWithActivityPackage:(ADJActivityPackage *)activityPackage;

@end

@interface ADJAttributionResponseData : ADJResponseData

@property (nonatomic, strong) NSURL *deeplink;

@end
