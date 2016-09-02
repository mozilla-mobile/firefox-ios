//
//  ADJActivityHandlerMock.h
//  Adjust
//
//  Created by Pedro Filipe on 11/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJActivityHandler.h"
#import "ADJAttribution.h"

@interface ADJActivityHandlerMock : NSObject <ADJActivityHandler>

@property (nonatomic, strong) ADJAttribution *attributionUpdated;

- (void) setUpdatedAttribution:(BOOL)updated;

@end
