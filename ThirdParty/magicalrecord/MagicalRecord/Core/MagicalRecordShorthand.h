#ifdef MR_SHORTHAND





#import "MagicalRecordDeprecated.h"

@interface NSManagedObject (MagicalAggregationShortHand)
+ (NSNumber *) numberOfEntities;
+ (NSNumber *) numberOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSUInteger) countOfEntities;
+ (NSUInteger) countOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter inContext:(NSManagedObjectContext *)context;
+ (BOOL) hasAtLeastOneEntity;
+ (BOOL) hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context;
+ (NSNumber *)aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSNumber *)aggregateOperation:(NSString *)function onAttribute:(NSString *)attributeName withPredicate:(NSPredicate *)predicate;
- (instancetype) objectWithMinValueFor:(NSString *)property;
- (instancetype) objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context;
@end

@interface NSManagedObject (MagicalFindersShortHand)
+ (NSArray *) findAll;
+ (NSArray *) findAllInContext:(NSManagedObjectContext *)context;
+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSArray *) findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSArray *) findAllWithPredicate:(NSPredicate *)searchTerm;
+ (NSArray *) findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (instancetype) findFirst;
+ (instancetype) findFirstInContext:(NSManagedObjectContext *)context;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchTerm;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)attributes, ...;
+ (instancetype) findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ...;
+ (instancetype) findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (instancetype) findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (instancetype) findFirstOrderedByAttribute:(NSString *)attribute ascending:(BOOL)ascending;
+ (instancetype) findFirstOrderedByAttribute:(NSString *)attribute ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSArray *) findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (NSFetchedResultsController *) fetchAllWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate;
+ (NSFetchedResultsController *) fetchAllWithDelegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate;
+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate;
+ (NSFetchedResultsController *) fetchAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending delegate:(id<NSFetchedResultsControllerDelegate>)delegate inContext:(NSManagedObjectContext *)context;
#endif
@end
@interface NSManagedObject (MagicalRecordShortHand)
+ (NSUInteger) defaultBatchSize;
+ (void) setDefaultBatchSize:(NSUInteger)newBatchSize;
+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request;
+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
+ (instancetype) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request;
+ (instancetype) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (void) performFetch:(NSFetchedResultsController *)controller;
#endif
+ (NSEntityDescription *) entityDescription;
+ (NSEntityDescription *) entityDescriptionInContext:(NSManagedObjectContext *)context;
+ (NSArray *) propertiesNamed:(NSArray *)properties;
+ (instancetype) createEntity;
+ (instancetype) createEntityInContext:(NSManagedObjectContext *)context;
+ (instancetype) createInContext:(NSManagedObjectContext *)context MR_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "createEntityInContext:");
- (BOOL) deleteEntity;
- (BOOL) deleteInContext:(NSManagedObjectContext *)context MR_DEPRECATED_WILL_BE_REMOVED_IN_PLEASE_USE("4.0", "deleteEntityInContext:");
- (BOOL) deleteEntityInContext:(NSManagedObjectContext *)context;
+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate;
+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (BOOL) truncateAll;
+ (BOOL) truncateAllInContext:(NSManagedObjectContext *)context;
+ (NSArray *) ascendingSortDescriptors:(NSArray *)attributesToSortBy;
+ (NSArray *) descendingSortDescriptors:(NSArray *)attributesToSortBy;
- (instancetype) inContext:(NSManagedObjectContext *)otherContext;
- (instancetype) inThreadContext;
@end
@interface NSManagedObject (MagicalRequestsShortHand)
+ (NSFetchRequest *) createFetchRequest;
+ (NSFetchRequest *) createFetchRequestInContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAll;
+ (NSFetchRequest *) requestAllInContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value;
+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue;
+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
@end
@interface NSManagedObjectContext (MagicalObservingShortHand)
- (void) observeContext:(NSManagedObjectContext *)otherContext;
- (void) stopObservingContext:(NSManagedObjectContext *)otherContext;
- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext;
- (void) observeiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
- (void) stopObservingiCloudChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
@end
@interface NSManagedObjectContext (MagicalRecordShortHand)
+ (void) initializeDefaultContextWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
+ (NSManagedObjectContext *) context NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) contextWithParent:(NSManagedObjectContext *)parentContext NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) newMainQueueContext NS_RETURNS_RETAINED;
+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator NS_RETURNS_RETAINED;
+ (void) resetDefaultContext;
+ (NSManagedObjectContext *) rootSavingContext;
+ (NSManagedObjectContext *) defaultContext;
- (NSString *) description;
- (NSString *) parentChain;
- (void) setWorkingName:(NSString *)workingName;
- (NSString *) workingName;
- (void) MR_deleteObjects:(id <NSFastEnumeration>)managedObjects;
@end
#import "NSManagedObjectContext+MagicalSaves.h"
@interface NSManagedObjectContext (MagicalSavesShortHand)
- (void) saveOnlySelfWithCompletion:(MRSaveCompletionHandler)completion;
- (void) saveToPersistentStoreWithCompletion:(MRSaveCompletionHandler)completion;
- (void) saveOnlySelfAndWait;
- (void) saveToPersistentStoreAndWait;
- (void) saveWithOptions:(MRSaveOptions)mask completion:(MRSaveCompletionHandler)completion;
- (void) save MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveWithErrorCallback:(void(^)(NSError *error))errorCallback MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveInBackgroundCompletion:(void (^)(void))completion MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveNestedContexts MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
- (void) saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion MR_DEPRECATED_WILL_BE_REMOVED_IN("3.0");
@end
@interface NSManagedObjectContext (MagicalThreadingShortHand)
+ (NSManagedObjectContext *) contextForCurrentThread;
+ (void) clearNonMainThreadContextsCache;
+ (void) resetContextForCurrentThread;
+ (void) clearContextForCurrentThread;
@end
@interface NSManagedObjectModel (MagicalRecordShortHand)
+ (NSManagedObjectModel *) defaultManagedObjectModel;
+ (void) setDefaultManagedObjectModel:(NSManagedObjectModel *)newDefaultModel;
+ (NSManagedObjectModel *) mergedObjectModelFromMainBundle;
+ (NSManagedObjectModel *) newManagedObjectModelNamed:(NSString *)modelFileName NS_RETURNS_RETAINED;
+ (NSManagedObjectModel *) managedObjectModelNamed:(NSString *)modelFileName;
+ (NSManagedObjectModel *) newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName NS_RETURNS_RETAINED;
@end
@interface NSPersistentStore (MagicalRecordShortHand)
+ (NSURL *) defaultLocalStoreUrl;
+ (NSPersistentStore *) defaultPersistentStore;
+ (void) setDefaultPersistentStore:(NSPersistentStore *) store;
+ (NSURL *) urlForStoreName:(NSString *)storeFileName;
+ (NSURL *) cloudURLForUbiqutiousContainer:(NSString *)bucketName;
@end
@interface NSPersistentStoreCoordinator (MagicalRecordShortHand)
+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator;
+ (void) setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;
+ (NSPersistentStoreCoordinator *) coordinatorWithInMemoryStore;
+ (NSPersistentStoreCoordinator *) newPersistentStoreCoordinator NS_RETURNS_RETAINED;
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *) coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore;
+ (NSPersistentStoreCoordinator *) coordinatorWithiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
+ (NSPersistentStoreCoordinator *) coordinatorWithiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionHandler;
- (NSPersistentStore *) addInMemoryStore;
- (NSPersistentStore *) addAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
- (NSPersistentStore *) addSqliteStoreNamed:(id)storeFileName withOptions:(__autoreleasing NSDictionary *)options;
- (void) addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent;
- (void) addiCloudContainerID:(NSString *)containerID contentNameKey:(NSString *)contentNameKey localStoreNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)subPathComponent completion:(void(^)(void))completionBlock;
@end






#endif

