//
//  LoadableCategory.h
//  KIF
//
//  Created by Karl Stenerud on 7/16/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

/** Make all categories in the current file loadable without using -load-all.
 *
 * Normally, compilers will skip linking files that contain only categories.
 * Adding a call to this macro adds a dummy class, which causes the linker
 * to add the file.
 *
 * @param UNIQUE_NAME A globally unique name.
 */
#define MAKE_CATEGORIES_LOADABLE(UNIQUE_NAME) @interface FORCELOAD_##UNIQUE_NAME : NSObject @end @implementation FORCELOAD_##UNIQUE_NAME @end
