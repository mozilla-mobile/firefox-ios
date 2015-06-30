//
//  FxA.h
//  FxA
//
//  Created by Richard Newman on 2014-09-22.
//  Copyright (c) 2014 Mozilla. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for FxA.
FOUNDATION_EXPORT double FxAVersionNumber;

//! Project version string for FxA.
FOUNDATION_EXPORT const unsigned char FxAVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <FxA/PublicHeader.h>

#include <FxA/DSAKeyPair.h>
#include <FxA/RSAKeyPair.h>
#include <FxA/JSONWebTokenUtils.h>
#include <FxA/MockMyIDTokenFactory.h>
#include <FxA/NSData+Base16.h>
#include <FxA/NSData+Base32.h>
#include <FxA/NSData+SHA.h>
#include <FxA/NSData+Utils.h>
#include <FxA/NSData+KeyDerivation.h>

// These are all the ones the compiler complains are missing.
// Some are commented out because they rely on openssl/bn.h, which we can't find
// when we try the import. *shrug*
#include "ASNUtils.h"
#include "CHUtils.h"
//#include "CHMath.h"
//#include "CHNumber.h"
//#include "CHNumber_Private.h"
//#include "CHMutableNumber.h"
