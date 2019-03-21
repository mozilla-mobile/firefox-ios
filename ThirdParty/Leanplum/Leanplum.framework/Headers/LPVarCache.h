//
//  VarCache.h
//  Leanplum
//
//  Created by Andrew First on 5/2/12.
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import <Foundation/Foundation.h>

@class LPVar;

typedef void (^CacheUpdateBlock)(void);
typedef void (^RegionInitBlock)(NSDictionary *, NSSet *, NSSet *);

@interface LPVarCache : NSObject

+(instancetype)sharedCache;

// Location initialization
- (void)registerRegionInitBlock:(RegionInitBlock)block;

// Handling variables.
- (LPVar *)define:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind;
- (NSArray *)getNameComponents:(NSString *)name;
- (void)loadDiffs;
- (void)saveDiffs;
// Returns YES if the file was registered.
- (void)registerVariable:(LPVar *)var;
- (LPVar *)getVariable:(NSString *)name;

// Handling values.
- (id)getValueFromComponentArray:(NSArray *) components fromDict:(NSDictionary *)values;
- (id)getMergedValueFromComponentArray:(NSArray *) components;
- (NSDictionary *)diffs;
- (NSDictionary *)messageDiffs;
- (NSArray *)updateRulesDiffs;
- (NSArray *)eventRulesDiffs;
- (BOOL)hasReceivedDiffs;
- (void)applyVariableDiffs:(NSDictionary *)diffs_
                  messages:(NSDictionary *)messages_
               updateRules:(NSArray *)updateRules_
                eventRules:(NSArray *)eventRules_
                  variants:(NSArray *)variants_
                   regions:(NSDictionary *)regions_
          variantDebugInfo:(NSDictionary *)variantDebugInfo_;
- (void)applyUpdateRuleDiffs:(NSArray *)updateRuleDiffs;
- (void)onUpdate:(CacheUpdateBlock)block;
- (void)onInterfaceUpdate:(CacheUpdateBlock)block;
- (void)onEventsUpdate:(CacheUpdateBlock)block;
- (void)setSilent:(BOOL)silent;
- (BOOL)silent;
- (id)mergeHelper:(id)vars withDiffs:(id)diff;
- (int)contentVersion;
- (NSArray *)variants;
- (NSDictionary *)regions;
- (NSDictionary *)defaultKinds;

- (NSDictionary *)variantDebugInfo;
- (void)setVariantDebugInfo:(NSDictionary *)variantDebugInfo;

- (void)clearUserContent;

// Handling actions.
- (NSDictionary *)actionDefinitions;
- (NSDictionary *)messages;
- (void)registerActionDefinition:(NSString *)name
                          ofKind:(int)kind
                   withArguments:(NSArray *)args
                      andOptions:(NSDictionary *)options;

// Development mode.
- (void)setDevModeValuesFromServer:(NSDictionary *)values
                    fileAttributes:(NSDictionary *)fileAttributes
                 actionDefinitions:(NSDictionary *)actionDefinitions;
- (BOOL)sendVariablesIfChanged;
- (BOOL)sendActionsIfChanged;

// Handling files.
- (void)registerFile:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue;
- (void)maybeUploadNewFiles;
- (NSDictionary *)fileAttributes;

- (NSMutableDictionary *)userAttributes;
- (void)saveUserAttributes;

@end
