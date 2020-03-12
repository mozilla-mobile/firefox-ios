//
//  TestLibraryBridge.h
//  AdjustWebBridgeTestApp
//
//  Created by Pedro Silva (@nonelse) on 6th August 2018.
//  Copyright © 2018 Adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATLTestLibrary.h"
#import "AdjustBridgeRegister.h"

static NSString * baseUrl = @"http://127.0.0.1:8080";
static NSString * gdprUrl = @"http://127.0.0.1:8080";
static NSString * controlUrl = @"ws://127.0.0.1:1987";

@interface TestLibraryBridge : NSObject<AdjustCommandDelegate>

- (id)initWithAdjustBridgeRegister:(AdjustBridgeRegister *)adjustBridgeRegister;

@end
