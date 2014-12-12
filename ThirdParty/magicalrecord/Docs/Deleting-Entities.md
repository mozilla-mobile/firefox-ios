# Deleting Entities

To delete a single entity in the default context:

```objective-c
[myPerson MR_deleteEntity];
```

To delete the entity from a specific context:

```objective-c
[myPerson MR_deleteEntityInContext:otherContext];
```

To truncate all entities from the default context:

```objective-c
[Person MR_truncateAll];
```

To truncate all entities in a specific context:

```objective-c
[Person MR_truncateAllInContext:otherContext];
```
