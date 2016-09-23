//
//  ADJResponseData.h
//  adjust
//
//  Created by Pedro Filipe on 07/12/15.
//  Copyright © 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJActivityPackage.h"
#import "ADJAttribution.h"
#import "ADJSessionSuccess.h"
#import "ADJSessionFailure.h"
#import "ADJEventSuccess.h"
#import "ADJEventFailure.h"

@interface ADJResponseData : NSObject <NSCopying>

@property (nonatomic, assign) ADJActivityKind activityKind;

@property (nonatomic, copy) NSString * message;

@property (nonatomic, copy) NSString * timeStamp;

@property (nonatomic, copy) NSString * adid;

@property (nonatomic, assign) BOOL success;

@property (nonatomic, assign) BOOL willRetry;

@property (nonatomic, strong) NSDictionary *jsonResponse;

@property (nonatomic, copy) ADJAttribution *attribution;

+ (ADJResponseData *)responseData;
- (id)init;

+ (id)buildResponseData:(ADJActivityPackage *)activityPackage;

@end

@interface ADJSessionResponseData : ADJResponseData

- (ADJSessionSuccess *)successResponseData;
- (ADJSessionFailure *)failureResponseData;

@end

@interface ADJEventResponseData : ADJResponseData

@property (nonatomic, copy) NSString * eventToken;

- (ADJEventSuccess *)successResponseData;
- (ADJEventFailure *)failureResponseData;

+ (ADJResponseData *)responseDataWithActivityPackage:(ADJActivityPackage *)activityPackage;
- (id)initWithActivityPackage:(ADJActivityPackage *)activityPackage;

@end

@interface ADJAttributionResponseData : ADJResponseData

@property (nonatomic, strong) NSURL * deeplink;

@end

@interface ADJClickResponseData : ADJResponseData

@end

@interface ADJUnknowResponseData : ADJResponseData

@end
