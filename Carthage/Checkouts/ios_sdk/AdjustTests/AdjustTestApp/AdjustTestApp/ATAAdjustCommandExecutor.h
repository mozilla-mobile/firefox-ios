//
//  ATAAdjustCommandExecutor.h
//  AdjustTestApp
//
//  Created by Pedro Silva (@nonelse) on 23rd August 2017.
//  Copyright © 2017-2018 Adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATLTestLibrary.h"

@interface ATAAdjustCommandExecutor : NSObject<AdjustCommandDelegate>

@property (nonatomic, strong) ATLTestLibrary *testLibrary;

@end
