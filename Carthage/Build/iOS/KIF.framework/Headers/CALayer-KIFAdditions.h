//
//  CALayer-KIFAdditions.h
//  Pods
//
//  Created by Radu Ciobanu on 28/01/2016.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (KIFAdditions)

/**
 *  @method hasAnimations
 *  @abstract Traverses self's hierarchy of layers and checks whether any
 * visible sublayers or self have ongoing anymations.
 *  @return YES if an animated layer has been found, NO otherwise.
 */
- (BOOL)hasAnimations;

/*!
 @method performBlockOnDescendentLayers:
 @abstract Calls a block on the layer itself and on all its descendent layers.
 @param block The block that will be called on the layers. Stop the traversation
 of the layers by assigning YES to the stop-parameter of the block.
 */
- (void)performBlockOnDescendentLayers:(void (^)(CALayer *layer, BOOL *stop))block;

@end
