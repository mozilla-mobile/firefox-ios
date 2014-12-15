# Creating Entities

To create and insert a new instance of an Entity in the default context, you can use:

```objective-c
Person *myPerson = [Person MR_createEntity];
```

To create and insert an entity into specific context:

```objective-c
Person *myPerson = [Person MR_createEntityInContext:otherContext];
```
