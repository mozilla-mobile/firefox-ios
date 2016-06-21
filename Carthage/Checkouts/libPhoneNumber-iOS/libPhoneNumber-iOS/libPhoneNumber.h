//
//  libPhoneNumber-iOS.h
//  libPhoneNumber-iOS
//
//  Created by Roy Marmelstein on 04/08/2015.
//  Copyright (c) 2015 ohtalk.me. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for libPhoneNumber-iOS.
FOUNDATION_EXPORT double libPhoneNumber_iOSVersionNumber;

//! Project version string for libPhoneNumber-iOS.
FOUNDATION_EXPORT const unsigned char libPhoneNumber_iOSVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <libPhoneNumber_iOS/PublicHeader.h>


#import "NBPhoneNumberDefines.h"

// Features
#import "NBPhoneNumberUtil.h"
#import "NBAsYouTypeFormatter.h"

// Metadata
#import "NBMetadataCore.h"
#import "NBMetadataCoreMapper.h"
#import "NBMetadataHelper.h"

// Model
#import "NBPhoneMetaData.h"
#import "NBNumberFormat.h"
#import "NBPhoneNumber.h"
#import "NBPhoneNumberDesc.h"
