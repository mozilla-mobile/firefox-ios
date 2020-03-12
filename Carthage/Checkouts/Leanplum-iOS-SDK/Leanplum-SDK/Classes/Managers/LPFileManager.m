//
//  LPFileManager.m
//  Leanplum
//
//  Created by Andrew First on 1/9/13.
//  Copyright (c) 2013 Leanplum, Inc. All rights reserved.
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

#import "LPConstants.h"
#import "LPSwizzle.h"
#import "LPFileManager.h"
#import "LPVarCache.h"
#import "Leanplum.h"
#import "LeanplumRequest.h"
#include <dirent.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <unistd.h>
#import "LPRequestFactory.h"
#import "LPRequestSender.h"
#import "LPCountAggregator.h"
#import "LPFileTransferManager.h"

typedef enum {
    kLeanplumFileOperationGet = 0,
    kLeanplumFileOperationDelete = 1,
} LeanplumFileTraversalOperation;

NSString *appBundlePath;
BOOL initializing = NO;
BOOL hasInited = NO;
NSArray *possibleVariations;
NSMutableSet *directoryExistenceCache;
NSString *documentsDirectoryCached;
NSString *cachesDirectoryCached;
NSMutableSet *skippedFiles;
NSBundle *originalMainBundle;
LeanplumVariablesChangedBlock resourceSyncingReady;

@implementation NSBundle (LeanplumExtension)

+ (NSBundle *)leanplum_mainBundle
{
    if (skippedFiles.count) {
        return [LPBundle bundleWithPath:[originalMainBundle bundlePath]];
    } else {
        return originalMainBundle;
    }
}

- (NSURL *)leanplum_appStoreReceiptURL
{
    return [originalMainBundle leanplum_appStoreReceiptURL];
}

@end

@implementation LPBundle

- (nullable instancetype)initWithPath:(NSString *)path
{
    return [super initWithPath:path];
}

- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)ext
{
    NSURL *orig = [originalMainBundle URLForResource:name withExtension:ext];
    if (orig && [skippedFiles containsObject:[orig path]]) {
        return orig;
    }
    return [super URLForResource:name withExtension:ext];
}

- (NSURL *)URLForResource:(NSString *)name
            withExtension:(NSString *)ext
             subdirectory:(NSString *)subpath
{
    NSURL *orig = [originalMainBundle URLForResource:name withExtension:ext subdirectory:subpath];
    if (orig && [skippedFiles containsObject:[orig path]]) {
        return orig;
    }
    return [super URLForResource:name withExtension:ext subdirectory:subpath];
}

- (NSURL *)URLForResource:(NSString *)name
            withExtension:(NSString *)ext
             subdirectory:(NSString *)subpath
             localization:(NSString *)localizationName
{
    NSURL *orig = [originalMainBundle URLForResource:name
                                       withExtension:ext
                                        subdirectory:subpath
                                        localization:localizationName];
    if (orig && [skippedFiles containsObject:[orig path]]) {
        return orig;
    }
    return [super URLForResource:name
                   withExtension:ext
                    subdirectory:subpath
                    localization:localizationName];
}

- (NSArray *)URLsForResourcesWithExtension:(NSString *)ext subdirectory:(NSString *)subpath
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *url in
        [originalMainBundle URLsForResourcesWithExtension:ext subdirectory:subpath]) {
        if ([skippedFiles containsObject:[url path]]) {
            [result addObject:url];
        }
    }
    [result addObjectsFromArray:[super URLsForResourcesWithExtension:ext subdirectory:subpath]];
    return result;
}

- (NSArray *)URLsForResourcesWithExtension:(NSString *)ext
                              subdirectory:(NSString *)subpath
                              localization:(NSString *)localizationName
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSURL *url in [originalMainBundle URLsForResourcesWithExtension:ext
                                                            subdirectory:subpath
                                                            localization:localizationName]) {
        if ([skippedFiles containsObject:[url path]]) {
            [result addObject:url];
        }
    }
    [result addObjectsFromArray:[super URLsForResourcesWithExtension:ext
                                                        subdirectory:subpath
                                                        localization:localizationName]];
    return result;
}

- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)ext
{
    NSString *orig = [originalMainBundle pathForResource:name ofType:ext];
    if (orig && [skippedFiles containsObject:orig]) {
        return orig;
    }
    return [super pathForResource:name ofType:ext];
}

- (NSString *)pathForResource:(NSString *)name
                       ofType:(NSString *)ext
                  inDirectory:(NSString *)subpath
{
    NSString *orig = [originalMainBundle pathForResource:name ofType:ext inDirectory:subpath];
    if (orig && [skippedFiles containsObject:orig]) {
        return orig;
    }
    return [super pathForResource:name ofType:ext inDirectory:subpath];
}

- (NSString *)pathForResource:(NSString *)name
                       ofType:(NSString *)ext
                  inDirectory:(NSString *)subpath
              forLocalization:(NSString *)localizationName
{
    NSString *orig = [originalMainBundle pathForResource:name
                                                  ofType:ext
                                             inDirectory:subpath
                                         forLocalization:localizationName];
    if (orig && [skippedFiles containsObject:orig]) {
        return orig;
    }
    return [super pathForResource:name
                           ofType:ext
                      inDirectory:subpath
                  forLocalization:localizationName];
}

- (NSArray *)pathsForResourcesOfType:(NSString *)ext inDirectory:(NSString *)subpath
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *file in [originalMainBundle pathsForResourcesOfType:ext inDirectory:subpath]) {
        if ([skippedFiles containsObject:file]) {
            [result addObject:file];
        }
    }
    [result addObjectsFromArray:[super pathsForResourcesOfType:ext inDirectory:subpath]];
    return result;
}

- (NSArray *)pathsForResourcesOfType:(NSString *)ext
                         inDirectory:(NSString *)subpath
                     forLocalization:(NSString *)localizationName
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *file in [originalMainBundle pathsForResourcesOfType:ext
                                                           inDirectory:subpath
                                                       forLocalization:localizationName]) {
        if ([skippedFiles containsObject:file]) {
            [result addObject:file];
        }
    }
    [result addObjectsFromArray:[super pathsForResourcesOfType:ext
                                                   inDirectory:subpath
                                               forLocalization:localizationName]];
    return result;
}

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)table
{
    NSString *result = [super localizedStringForKey:key value:value table:table];
    if (skippedFiles.count == 0) {
        return result;
    }
    if (![result isEqualToString:value]) {
        return result;
    }
    return [originalMainBundle localizedStringForKey:key value:value table:table];
}

@end

@implementation LPFileManager

+ (NSString *)appBundlePath
{
    if (!appBundlePath) {
        originalMainBundle = [NSBundle mainBundle];
        appBundlePath = [originalMainBundle resourcePath];
    }
    return appBundlePath;
}

/**
 * Returns the full path for the <Application_Home>/Documents directory, which is automatically
 * backed up by iCloud.
 *
 * Note: This should be used if you don't want the data to be deleted such as requests data.
 * In general all the assets like images and files should be stored in the cache directory.
 */
+ (NSString *)documentsDirectory
{
    if (!documentsDirectoryCached) {
        documentsDirectoryCached = [NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    }
    return documentsDirectoryCached;
}

/**
 * Returns the full path for the <Application_Home>/Library/Caches directory, which stores data
 * that can be downloaded again or regenerated, and is not automatically backed up by iCloud.
 */
+ (NSString *)cachesDirectory
{
    if (!cachesDirectoryCached) {
        cachesDirectoryCached = [NSSearchPathForDirectoriesInDomains(
            NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];

        if ([self areDocumentsBackedUp]) {
            [self moveDoctumentsOutOfBackedUpLocation];
        }
    }
    return cachesDirectoryCached;
}

/**
 * Returns the full path of for the Leanplum_Resources directory, relative to `folder`.
 */
+ (NSString *)documentsPathRelativeToFolder:(nonnull NSString *)folder
{
    return [folder stringByAppendingPathComponent:LP_PATH_DOCUMENTS];
}

/**
 * Returns the full path of the Leanplum_Resources directory, relative to
 * <Application_Home>/Library/Caches
 */
+ (NSString *)documentsPath
{
    return [self documentsPathRelativeToFolder:[self cachesDirectory]];
}

/**
 * Returns the full path of for the Leanplum_Bundle directory, relative to `folder`.
 */
+ (NSString *)bundlePathRelativeToFolder:(NSString *)folder
{
    return [folder stringByAppendingPathComponent:LP_PATH_BUNDLE];
}

/**
 * Returns the full path of the Leanplum_Bundle directory, relative to
 * <Application_Home>/Library/Caches
 */
+ (NSString *)bundlePath
{
    return [self bundlePathRelativeToFolder:[self cachesDirectory]];
}

+ (NSString *)file:(NSString *)path
                  relativeTo:(NSString *)folder
    createMissingDirectories:(BOOL)createMissingDirectories
{
    if (!path) {
        return nil;
    }
    NSString *folderPath = [[self cachesDirectory] stringByAppendingPathComponent:folder];
    NSString *result = [folderPath stringByAppendingPathComponent:path];
    if (createMissingDirectories) {
        NSString *directory = [result stringByDeletingLastPathComponent];
        if (!directoryExistenceCache) {
            directoryExistenceCache = [NSMutableSet set];
        }
        if (![directoryExistenceCache containsObject:directory]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
            if (error != nil) {
                NSLog(@"Leanplum: Error creating directory: %@", error);
            } else {
                [directoryExistenceCache addObject:directory];
            }
        }
    }
    return result;
}

+ (NSString *)fileRelativeToAppBundle:(NSString *)path
{
    if (!path) {
        return nil;
    }
    NSString *resource = [path stringByDeletingPathExtension];
    NSString *extension = [path pathExtension];
    return [[NSBundle bundleWithPath:self.appBundlePath] pathForResource:resource ofType:extension];
}

+ (NSString *)fileRelativeToLPBundle:(NSString *)path
{
    return [self file:path relativeTo:LP_PATH_BUNDLE createMissingDirectories:YES];
}

+ (NSString *)fileRelativeToDocuments:(NSString *)path
             createMissingDirectories:(BOOL)createMissingDirectories
{
    return [self file:path
           relativeTo:LP_PATH_DOCUMENTS createMissingDirectories:createMissingDirectories];
}

+ (BOOL)isNewerLocally:(NSDictionary *)localAttributes orRemotely:(NSDictionary *)serverAttributes
{
    if (!serverAttributes) {
        return YES;
    }
    NSString *localHash = [localAttributes valueForKey:LP_KEY_HASH];
    NSString *serverHash = [serverAttributes valueForKey:LP_KEY_HASH];
    NSNumber *localSize = [localAttributes valueForKey:LP_KEY_SIZE];
    NSNumber *serverSize = [serverAttributes valueForKey:LP_KEY_SIZE];
    if (!serverSize || serverSize == (id)[NSNull null] || ![localSize isEqualToNumber:serverSize]) {
        return YES;
    }
    return localHash && (!serverHash || serverHash == (id)[NSNull null]
                            || ![localHash isEqualToString:serverHash]);
}

+ (NSString *)bundleVersion
{
    NSFileManager *fm = [NSFileManager defaultManager];

    NSString *path = [[NSBundle mainBundle] resourcePath];
    NSDictionary *attrs = [fm attributesOfItemAtPath:path error:nil];
    NSString *current = [attrs[NSFileModificationDate] description];

    return current;
}

/**
 * Checks if the Leanplum_Resources folder is present in the <Application_Home>/Documents directory,
 * which is automatically backed up by iCloud.
 */
+ (BOOL)areDocumentsBackedUp
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:
         [self documentsPathRelativeToFolder:[self documentsDirectory]]]) {
        return YES;
    }
    return NO;
}

/**
 * Moves the Leanplum_Resources folder from <Application_Home>/Documents to
 * <Application_Home>/Library/Caches
 */
+ (void)moveDoctumentsOutOfBackedUpLocation
{
    NSError *err;
    [[NSFileManager defaultManager] moveItemAtPath:[self documentsPathRelativeToFolder:
                                                    [self documentsDirectory]]
                                            toPath:[self documentsPath]
                                             error:&err];
}

/**
 * Checks if the Leanplum_Bundle folder is present in the <Application_Home>/Documents directory,
 * which is automatically backed up by iCloud.
 */
+ (BOOL)isBundleBackedUp
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:
         [self bundlePathRelativeToFolder:[self documentsDirectory]]]) {
        return YES;
    }
    return NO;
}

/**
 * Removes the Leanplum_Bundle folder and its contents from <Application_Home>/Documents
 */
+ (void)removeBundleFromBackedUpLocation
{
    [self traverse:[self bundlePathRelativeToFolder:[self documentsDirectory]]
           current:@"" files:nil isDirs:nil operation:kLeanplumFileOperationDelete];
    NSError *err;
    [[NSFileManager defaultManager] removeItemAtPath:[self bundlePathRelativeToFolder:
                                                      [self documentsDirectory]]
                                               error:&err];
}

+ (BOOL)isBundleUpToDate
{
    NSString *current = [self bundleVersion];

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:LEANPLUM_DEFAULTS_APP_VERSION_KEY] != nil) {
        // Key exists.
        NSString *saved = [defaults objectForKey:LEANPLUM_DEFAULTS_APP_VERSION_KEY];
        if ([current isEqualToString:saved]) {
            // Still running the same app version.
            return YES;
        } else {
            // The app version changed from the last launch.
            // Will save the version at the end of syncResources.
            return NO;
        }
    } else {
        // First run. Will save new bundle version at the end of syncResources.
        return NO;
    }
}

+ (void)linkItemAtPath:(NSString *)source toPath:(NSString *)dest
{
    if (symlink([source UTF8String], [dest UTF8String])) {
        NSLog(@"Leanplum: Error syncing file %@: Code %d", source, errno);
    }
}

+ (void)defineFileVariable:(NSString *)varName withFile:(NSString *)file
{
    LPVar *fileVar = [LPVar define:varName withFile:file];
    [fileVar onFileReady:^{
        NSString *computedFile = file;
        if (!computedFile) {
            computedFile = [[[varName substringFromIndex:LP_VALUE_RESOURCES_VARIABLE.length]
                stringByReplacingOccurrencesOfString:@"."
                                          withString:@"/"]
                stringByReplacingOccurrencesOfString:@"\\/"
                                          withString:@"."];
        }
        NSString *dest = [self fileRelativeToLPBundle:computedFile];
        //         if (![dest isEqual:fileVar.fileValue])
        // Update the file if the variable has changed since the last run, or is
        // not the
        // default value. The latter case is necessary if the app was updated
        // and the file got
        // reverted back to the default.
        if ([fileVar hasChanged] || ![fileVar.defaultValue isEqualToString:fileVar.stringValue]) {
            unlink([dest UTF8String]);
            if (fileVar.fileValue) {
                [self linkItemAtPath:fileVar.fileValue toPath:dest];
            }
        }
    }];
}

+ (void)ensureVariablesExist:(NSString *)varName withTree:(NSDictionary *)valuesTree
{
    for (NSString *key in valuesTree.allKeys) {
        id value = valuesTree[key];
        NSString *childKey = [varName stringByAppendingFormat:@".%@", key];
        if ([[value class] isSubclassOfClass:NSDictionary.class]) {
            [self ensureVariablesExist:childKey withTree:value];
        } else {
            if (![[LPVarCache sharedCache] getVariable:childKey]) {
                [self defineFileVariable:childKey withFile:nil];
            }
        }
    }
}

+ (void)defineResources
{
    LPVar *var = [LPVar define:LP_VALUE_RESOURCES_VARIABLE withDictionary:@{}];
    [var onValueChanged:^{
        LP_TRY
        id value = [var objectForKeyPath:nil];
        [self ensureVariablesExist:LP_VALUE_RESOURCES_VARIABLE withTree:value];
        LP_END_TRY
    }];
}

+ (NSString *)fileValue:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue
{
    NSString *result;
    if ([stringValue isEqualToString:defaultValue]) {
        result = [self fileRelativeToAppBundle:defaultValue];
        if ([[NSFileManager defaultManager] fileExistsAtPath:result]) {
            return result;
        }
    }
    result = [self fileRelativeToDocuments:stringValue createMissingDirectories:NO];
    if (![[NSFileManager defaultManager] fileExistsAtPath:result]) {
        result = [self fileRelativeToAppBundle:stringValue];
        if (![[NSFileManager defaultManager] fileExistsAtPath:result]) {
            result = [self fileRelativeToLPBundle:defaultValue];
            if (![[NSFileManager defaultManager] fileExistsAtPath:result]) {
                return [self fileRelativeToAppBundle:defaultValue];
            }
        }
    }
    return result;
}

+ (BOOL)fileExists:(NSString *)name
{
    NSString *realPath = [LPFileManager fileRelativeToAppBundle:name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:realPath]) {
        realPath = [LPFileManager fileRelativeToDocuments:name createMissingDirectories:NO];
        if (![[NSFileManager defaultManager] fileExistsAtPath:realPath]) {
            return NO;
        }
    }
    return YES;
}

+ (BOOL)shouldDownloadFile:(NSString *)value defaultValue:(NSString *)defaultValue
{
    return value && ![value isEqualToString:defaultValue] && ![self fileExists:value];
}

// Returns whether the file is going to be downloaded.
+ (BOOL)maybeDownloadFile:(NSString *)value
             defaultValue:(NSString *)defaultValue
               onComplete:(void (^)(void))complete
{
    if (IS_NOOP) {
        return NO;
    }
    
    [[LPCountAggregator sharedAggregator] incrementCount:@"maybe_download_file"];
    
    if ([self shouldDownloadFile:value defaultValue:defaultValue]) {
        [[LPFileTransferManager sharedInstance] downloadFile:value onResponse:^(id<LPNetworkOperationProtocol> operation, id json) {
            if (complete) {
                complete();
            }
        } onError:^(NSError *error) {
            if (complete) {
                complete();
            }
        }];
        return YES;
    }
    return NO;
}

+ (void)initAsync:(BOOL)async
{
    [self initWithInclusions:nil andExclusions:nil async:async];
}

+ (BOOL)hasInited
{
    return hasInited;
}

+ (BOOL)initializing
{
    return initializing;
}

+ (void)setResourceSyncingReady:(LeanplumVariablesChangedBlock)block
{
    resourceSyncingReady = block;
}

+ (NSArray *)convertStringArrayToRegexArray:(NSArray *)stringArray
{
    NSMutableArray *regexArray = [NSMutableArray array];
    NSError *error = nil;
    for (NSString *patternString in stringArray) {
        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:patternString
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&error];
        if (!error) {
            [regexArray addObject:regex];
        } else {
            NSLog(@"Leanplum: Error: %@", error);
            error = nil;
        }
    }
    return regexArray;
}

+ (void)traverse:(NSString *)absDir
         current:(NSString *)relDir
           files:(NSMutableArray *)files
          isDirs:(NSMutableArray *)isDirs
       operation:(LeanplumFileTraversalOperation)operation
{
    DIR *dirp = opendir([absDir UTF8String]);
    if (!dirp) {
        return;
    }
    struct dirent *dp;
    while ((dp = readdir(dirp)) != NULL) {
        NSString *str = [[NSString alloc] initWithBytes:dp->d_name
                                                 length:dp->d_namlen
                                               encoding:NSUTF8StringEncoding];
        if (![str isEqualToString:@"."] && ![str isEqualToString:@".."]) {
            NSString *path = [relDir stringByAppendingPathComponent:str];
            NSString *absPath = [absDir stringByAppendingPathComponent:str];
            if (dp->d_type == DT_DIR) {
                [files addObject:path];
                [isDirs addObject:@(YES)];
                [self traverse:absPath current:path files:files isDirs:isDirs operation:operation];
                if (operation == kLeanplumFileOperationDelete) {
                    rmdir([absPath UTF8String]);
                }
            } else {
                [files addObject:path];
                [isDirs addObject:@(NO)];
                if (operation == kLeanplumFileOperationDelete) {
                    unlink([absPath UTF8String]);
                }
            }
        }
    }
    (void)closedir(dirp);
}

+ (void)traverse:(NSString *)absoluteDir
         current:(NSString *)relativeDir
           files:(NSMutableArray *)files
{
    DIR *dirp = opendir([absoluteDir UTF8String]);
    if (!dirp) {
        return;
    }
    struct dirent *dp;
    while ((dp = readdir(dirp)) != NULL) {
        NSString *str = [[NSString alloc] initWithBytes:dp->d_name
                                                 length:dp->d_namlen
                                               encoding:NSUTF8StringEncoding];
        if (![str isEqualToString:@"."] && ![str isEqualToString:@".."]) {
            NSString *path = [relativeDir stringByAppendingPathComponent:str];
            NSString *absPath = [absoluteDir stringByAppendingPathComponent:str];
            if (dp->d_type == DT_DIR) {
                [files addObject:path];
                [self traverse:absPath current:path files:files];
            } else {
                [files addObject:path];
            }
        }
    }
    (void)closedir(dirp);
}

+ (void)initWithInclusions:(NSArray *)inclusions
             andExclusions:(NSArray *)exclusions
                     async:(BOOL)async
{
    RETURN_IF_NOOP;
    initializing = YES;
    if (hasInited) {
        return;
    }
    if (async) {
        dispatch_queue_t resourceQueue = dispatch_queue_create("com.leanplum.resourceQueue", NULL);
        dispatch_async(resourceQueue, ^{
            LP_TRY [self enableResourceSyncingWithInclusions:inclusions andExclusions:exclusions];
            LP_END_TRY
        });
    } else {
        [self enableResourceSyncingWithInclusions:inclusions andExclusions:exclusions];
    }
}

+ (void)enableResourceSyncingWithInclusions:(NSArray *)inclusions
                              andExclusions:(NSArray *)exclusions
{
    NSArray *inclusionRegexes = [self convertStringArrayToRegexArray:inclusions];
    NSArray *exclusionRegexes = [self convertStringArrayToRegexArray:exclusions];

    NSError *error = nil;
    NSString *appPath = [[NSBundle mainBundle] executablePath];
    [self defineResources];
    BOOL isBundleUpToDate = [self isBundleUpToDate];
    skippedFiles = [NSMutableSet set];

    // Clean out dest.
    if (!isBundleUpToDate) {
        [self traverse:self.bundlePath
               current:@""
                 files:nil
                isDirs:nil
             operation:kLeanplumFileOperationDelete];
    }

    // Remove the bundle from the iCloud backed up directory.
    if ([self isBundleBackedUp]) {
        isBundleUpToDate = NO;
        [self removeBundleFromBackedUpLocation];
    }

    NSMutableArray *files = [NSMutableArray array];
    NSMutableArray *isDirs = [NSMutableArray array];
    [self traverse:self.appBundlePath
           current:@""
             files:files
            isDirs:isDirs
         operation:kLeanplumFileOperationGet];
    for (int i = 0; i < files.count; i++) {
        NSString *file = files[i];
        BOOL isDir = [isDirs[i] boolValue];
        NSString *source = [self.appBundlePath stringByAppendingPathComponent:file];
        NSString *dest = [self fileRelativeToLPBundle:file];

        // Set up file syncing.
        if ([source isEqual:appPath]) {
            // Skip over the app executable.
            continue;
        }

        // Set up file syncing.
        if ([file isEqual:@"PkgInfo"] || [file isEqual:@"ResourceRules.plist"] ||
            [file hasPrefix:@"_CodeSignature"] || [file isEqual:@"embedded.mobileprovision"] ||
            [file isEqual:@"Info.plist"]) {
            // Skip over the app executable.
            if (!isBundleUpToDate) {
                // Skip files that have permission errors.
                if (![file hasPrefix:@"_CodeSignature"]) {
                    [self linkItemAtPath:source toPath:dest];
                }
            }
            continue;
        }

        // Match patterns.
        BOOL included = NO;
        if (!inclusionRegexes || inclusionRegexes.count == 0) {
            included = YES;
        }
        for (NSRegularExpression *regex in inclusionRegexes) {
            if ([regex firstMatchInString:file options:0 range:NSMakeRange(0, file.length)]) {
                included = YES;
                break;
            }
        }
        if (included) {
            for (NSRegularExpression *regex in exclusionRegexes) {
                if ([regex firstMatchInString:file options:0 range:NSMakeRange(0, file.length)]) {
                    included = NO;
                    break;
                }
            }
        }
        if (!included) {
            [skippedFiles addObject:source];
            continue;
        }

        // Create symlink.
        if (!isBundleUpToDate && !isDir) {
            [self linkItemAtPath:source toPath:dest];
        }

        // Create variable.
        NSString *varName = [LP_VALUE_RESOURCES_VARIABLE
            stringByAppendingFormat:@".%@",
            [[file stringByReplacingOccurrencesOfString:@"." withString:@"\\."]
                                        stringByReplacingOccurrencesOfString:@"/"
                                                                  withString:@"."]];
        if (isDir) {
            [LPVar define:varName withDictionary:@{}];
        } else {
            [self defineFileVariable:varName withFile:file];
        }
    }
    [LPSwizzle swizzleClassMethod:@selector(mainBundle)
                  withClassMethod:@selector(leanplum_mainBundle)
                            error:&error
                            class:[NSBundle class]];
    [LPSwizzle swizzleMethod:@selector(appStoreReceiptURL)
                  withMethod:@selector(leanplum_appStoreReceiptURL)
                       error:&error
                       class:[NSBundle class]];

    if (!isBundleUpToDate) {
        [[NSUserDefaults standardUserDefaults] setObject:[self bundleVersion]
                                                  forKey:LEANPLUM_DEFAULTS_APP_VERSION_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (error) {
        NSLog(@"Leanplum: %@", error);
    }
    hasInited = YES;
    initializing = NO;
    if (resourceSyncingReady) {
        resourceSyncingReady();
    }
}

+ (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *) filePathString
{
    LP_TRY
    if (!filePathString) {
        return NO;
    }

    NSURL* url= [NSURL fileURLWithPath:filePathString];
    if (url && [[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        NSError *error = nil;
        BOOL success = [url setResourceValue:[NSNumber numberWithBool: YES]
                                      forKey:NSURLIsExcludedFromBackupKey
                                       error:&error];
        if (!success) {
            NSLog(@"Leanplum: Error excluding %@ from backup %@", [url lastPathComponent], error);
        }
        return success;
    }
    return NO;
    LP_END_TRY
}

@end
