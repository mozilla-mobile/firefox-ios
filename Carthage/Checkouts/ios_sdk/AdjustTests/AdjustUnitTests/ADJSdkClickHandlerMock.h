//
//  ADJSdkClickHandlerMock.h
//  Adjust
//
//  Created by Pedro Filipe on 02/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJSdkClickHandler.h"

@interface ADJSdkClickHandlerMock : NSObject<ADJSdkClickHandler>

@property (nonatomic, strong) NSMutableArray *packageQueue;

@end
