//
//  ATAAdjustDelegate.h
//  AdjustTestApp
//
//  Created by Pedro da Silva (@nonelse) on 26th October 2017.
//  Copyright © 2017 Аdjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Adjust.h"
#import "ATLTestLibrary.h"

@interface ATAAdjustDelegate : NSObject<AdjustDelegate>

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary andBasePath:(NSString *)basePath;

- (void)swizzleAttributionCallback:(BOOL)swizzleAttributionCallback
            eventSucceededCallback:(BOOL)swizzleEventSucceededCallback
               eventFailedCallback:(BOOL)swizzleEventFailedCallback
          sessionSucceededCallback:(BOOL)swizzleSessionSucceededCallback
             sessionFailedCallback:(BOOL)swizzleSessionFailedCallback;
@end
