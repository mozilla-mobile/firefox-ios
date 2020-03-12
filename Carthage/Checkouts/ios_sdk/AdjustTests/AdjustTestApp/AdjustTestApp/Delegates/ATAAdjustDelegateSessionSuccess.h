//
//  ATAAdjustDelegateSessionSuccess.h
//  AdjustTestApp
//
//  Created by Uglješa Erceg (uerceg) on 8th December 2017.
//  Copyright © 2017 Adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Adjust.h"
#import "ATLTestLibrary.h"

@interface ATAAdjustDelegateSessionSuccess : NSObject<AdjustDelegate>

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andBasePath:(NSString *)basePath;

@end
