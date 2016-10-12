//
//  ADJPackageFields.h
//  adjust
//
//  Created by Pedro Filipe on 15/05/15.
//  Copyright (c) 2015 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJAttribution.h"

@interface ADJPackageFields : NSObject

@property (nonatomic, copy) NSString *suffix;
// click
@property (nonatomic, strong) ADJAttribution * attribution;
@property (nonatomic, copy) NSString* deepLinkParameters;
@property (nonatomic, copy) NSString* purchaseTime;
@property (nonatomic, copy) NSString* iadTime;
@property (nonatomic, copy) NSString* iadDetails;
@property (nonatomic, copy) NSString* deepLink;
// ADJConfig
@property (nonatomic, copy) NSString *appToken;
@property (nonatomic, copy) NSString *environment;
@property (nonatomic, copy) NSString *sdkPrefix;
@property (nonatomic, assign) BOOL hasResponseDelegate;
@property (nonatomic, copy) NSString *defaultTracker;
@property (nonatomic, assign) BOOL eventBufferingEnabled;
// ADJDeviceInfo
@property (nonatomic, copy) NSString *clientSdk;
@property (nonatomic, copy) NSString *pushToken;
// ADJEvent
@property (nonatomic, copy) NSString* revenue;
@property (nonatomic, copy) NSString* callbackParameters;
@property (nonatomic, copy) NSString* partnerParameters;
@property (nonatomic, copy) NSString* transactionId;
@property (nonatomic, copy) NSString* currency;
@property (nonatomic, copy) NSString* receipt;
@property (nonatomic, copy) NSString* emptyReceipt;
@property (nonatomic, copy) NSDictionary* savedCallbackParameters;
@property (nonatomic, copy) NSDictionary* savedPartnerParameters;
// ADJActivityState
@property (nonatomic, copy) NSString* sessionCount;
@property (nonatomic, copy) NSString* subSessionCount;
@property (nonatomic, copy) NSString* eventCount;

+ (ADJPackageFields *)fields;
@end
