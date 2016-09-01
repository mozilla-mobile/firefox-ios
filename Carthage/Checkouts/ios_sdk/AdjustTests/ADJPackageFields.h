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
// ADJConfig
@property (nonatomic, copy) NSString *appToken;
@property (nonatomic, copy) NSString *environment;
@property (nonatomic, copy) NSString *sdkPrefix;
@property (nonatomic, copy) NSString *hasDelegate;
@property (nonatomic, copy) NSString *defaultTracker;
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
// ADJActivityState
@property (nonatomic, copy) NSString* sessionCount;
@property (nonatomic, copy) NSString* subSessionCount;
@property (nonatomic, copy) NSString* eventCount;

+ (ADJPackageFields *)fields;
@end
