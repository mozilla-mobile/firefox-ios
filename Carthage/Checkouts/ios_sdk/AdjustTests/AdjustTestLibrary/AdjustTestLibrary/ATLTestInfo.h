//
//  ATLTestInfo.h
//  AdjustTestLibrary
//
//  Created by Pedro on 01.11.17.
//  Copyright © 2017 adjust. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ATLTestLibrary.h"

@interface ATLTestInfo : NSObject

- (id)initWithTestLibrary:(ATLTestLibrary *)testLibrary;

- (void)teardown;

- (void)addInfoToSend:(NSString *)key
                value:(NSString *)value;

- (void)sendInfoToServer:(NSString *)currentBasePath;

@end
