

## Performing Core Data operations on Threads

MagicalRecord also provides some handy methods to set up background context for use with threading. The background saving operations are inspired by the UIView animation block methods, with few minor differences:

* The block in which you add your data saving code will never be on the main thread.
* a single NSManagedObjectContext is provided for your operations. 

For example, if we have Person entity, and we need to set the firstName and lastName fields, this is how you would use MagicalRecord to setup a background context for your use:

	Person *person = ...;
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext){
	
		Person *localPerson = [person MR_inContext:localContext];

		localPerson.firstName = @"John";
		localPerson.lastName = @"Appleseed";
		
	}];
	
In this method, the specified block provides you with the proper context in which to perform your operations, you don't need to worry about setting up the context so that it tells the Default Context that it's done, and should update because changes were performed on another thread.

To perform an action after this save block is completed, you can fill in a completion block:

	Person *person = ...;
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext){
	
		Person *localPerson = [person MR_inContext:localContext];

		localPerson.firstName = @"John";
		localPerson.lastName = @"Appleseed";
		
	} completion:^(BOOL success, NSError *error) {
	
		self.everyoneInTheDepartment = [Person findAll];
		
	}];
	
This completion block is called on the main thread (queue), so this is also safe for triggering UI updates.	