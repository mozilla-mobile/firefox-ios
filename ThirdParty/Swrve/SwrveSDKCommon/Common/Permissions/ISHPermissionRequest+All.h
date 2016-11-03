//
//  ISHPermissionRequest+All.h
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 26.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "ISHPermissionRequest.h"

@interface ISHPermissionRequest (All)
/**
 *  @param category The category for which to create a permission request.
 *
 *  @return An instance of the appropriate ISHPermissionRequest subclass
 *  for the given category.
 */
+ (ISHPermissionRequest *)requestForCategory:(ISHPermissionCategory)category;
@end
