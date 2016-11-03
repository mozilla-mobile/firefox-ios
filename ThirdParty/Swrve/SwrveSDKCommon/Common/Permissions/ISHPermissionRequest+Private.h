//
//  ISHPermissionRequest+Private.h
//  ISHPermissionKit
//
//  Created by Felix Lamouroux on 27.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//


@interface ISHPermissionRequest (Private)
- (void)setPermissionCategory:(ISHPermissionCategory)category;
@end

@interface ISHPermissionRequest (Subclasses)
// These interfaces are available to subclasses, there should be no need to override these or to call them from outside of a subclass implementation.
- (ISHPermissionState)internalPermissionState;
- (void)setInternalPermissionState:(ISHPermissionState)state;
@end
