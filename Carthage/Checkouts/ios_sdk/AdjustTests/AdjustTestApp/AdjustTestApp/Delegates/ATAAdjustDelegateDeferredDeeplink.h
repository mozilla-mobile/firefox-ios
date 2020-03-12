//
//  ATAAdjustDelegateDeferredDeeplink.h
//  AdjustTestApp
//
//  Created by Uglješa Erceg on 20.07.18.
//  Copyright © 2018 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Adjust.h"
#import "ATLTestLibrary.h"

@interface ATAAdjustDelegateDeferredDeeplink : NSObject<AdjustDelegate>

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary basePath:(NSString *)basePath andReturnValue:(BOOL)returnValue;

@end
