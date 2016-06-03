//
//  ADJAttributionHandlerMock.h
//  adjust
//
//  Created by Pedro Filipe on 10/12/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJAttributionHandler.h"

@interface ADJAttributionHandlerMock : NSObject<ADJAttributionHandler>

@property (atomic,strong) ADJActivityPackage * attributionPackage;

@end
