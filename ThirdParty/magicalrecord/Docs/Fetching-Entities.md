# Fetching Entities

> This document is being revised for MagicalRecord 2.3.0, and may contain information that is out of date. Please refer to the MagicalRecord's headers if anything here doesn't make sense.

#### Basic Finding

Most methods in MagicalRecord return an `NSArray` of results.

As an example, if you have an entity named *Person* related to a *Department* entity (as seen in many examples throughout [Apple's Core Data  documentation)[https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/), you can retrieve all of the *Person* entities from your persistent store using the following method:

```objective-c
NSArray *people = [Person MR_findAll];
```

To return the same entities sorted by a specific attribute:

```objective-c
NSArray *peopleSorted = [Person MR_findAllSortedBy:@"LastName"
                                         ascending:YES];
```

To return the entities sorted by multiple attributes:

```objective-c
NSArray *peopleSorted = [Person MR_findAllSortedBy:@"LastName,FirstName"
                                         ascending:YES];
```

To return the results sorted by multiple attributes with different values. If you don't provide a value for any attribute, it will default to whatever you've set in your model:

```objective-c
NSArray *peopleSorted = [Person MR_findAllSortedBy:@"LastName:NO,FirstName"
                                         ascending:YES];

// OR

NSArray *peopleSorted = [Person MR_findAllSortedBy:@"LastName,FirstName:YES"
                                         ascending:NO];
```

If you have a unique way of retrieving a single object from your data store (such as an identifier attribute), you can use the following method:

```objective-c
Person *person = [Person MR_findFirstByAttribute:@"FirstName"
                                       withValue:@"Forrest"];
```

#### Advanced Finding

If you want to be more specific with your search, you can use a predicate:

```objective-c
NSPredicate *peopleFilter = [NSPredicate predicateWithFormat:@"Department IN %@", @[dept1, dept2]];
NSArray *people = [Person MR_findAllWithPredicate:peopleFilter];
```

#### Returning an NSFetchRequest

```objective-c
NSPredicate *peopleFilter = [NSPredicate predicateWithFormat:@"Department IN %@", departments];
NSFetchRequest *people = [Person MR_requestAllWithPredicate:peopleFilter];
```

For each of these single line calls, an `NSFetchRequest` and `NSSortDescriptor`s for any sorting criteria  are created.

#### Customizing the Request

```objective-c
NSPredicate *peopleFilter = [NSPredicate predicateWithFormat:@"Department IN %@", departments];

NSFetchRequest *peopleRequest = [Person MR_requestAllWithPredicate:peopleFilter];
[peopleRequest setReturnsDistinctResults:NO];
[peopleRequest setReturnPropertiesNamed:@[@"FirstName", @"LastName"]];

NSArray *people = [Person MR_executeFetchRequest:peopleRequest];
```

#### Find the number of entities

You can also perform a count of all entities of a specific type in your persistent store:

```objective-c
NSNumber *count = [Person MR_numberOfEntities];
```

Or, if you're looking for a count of entities based on a predicate or some filter:

```objective-c
NSNumber *count = [Person MR_numberOfEntitiesWithPredicate:...];
```

There are also complementary methods which return `NSUInteger` rather than `NSNumber` instances:

```objective-c
+ (NSUInteger) MR_countOfEntities;
+ (NSUInteger) MR_countOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSUInteger) MR_countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
+ (NSUInteger) MR_countOfEntitiesWithPredicate:(NSPredicate *)searchFilter
                                     inContext:(NSManagedObjectContext *)context;
```

#### Aggregate Operations

```objective-c
NSNumber *totalCalories = [CTFoodDiaryEntry MR_aggregateOperation:@"sum:"
                                                      onAttribute:@"calories"
                                                    withPredicate:predicate];

NSNumber *mostCalories  = [CTFoodDiaryEntry MR_aggregateOperation:@"max:"
                                                      onAttribute:@"calories"
                                                    withPredicate:predicate];

NSArray *caloriesByMonth = [CTFoodDiaryEntry MR_aggregateOperation:@"sum:"
                                                       onAttribute:@"calories"
                                                     withPredicate:predicate
                                                           groupBy:@"month"];
```

#### Finding entities in a specific context

All find, fetch, and request methods have an `inContext:` method parameter that allows you to specify which managed object context you'd like to query:

```objective-c
NSArray *peopleFromAnotherContext = [Person MR_findAllInContext:someOtherContext];

Person *personFromContext = [Person MR_findFirstByAttribute:@"lastName"
                                                  withValue:@"Gump"
                                                  inContext:someOtherContext];

NSUInteger count = [Person MR_numberOfEntitiesWithContext:someOtherContext];
```
