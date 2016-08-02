# Skopelos (Work in progress)

A minimalistic, thread safe, non-boilerplate and super easy to use version of Active Record on Core Data.
Simply all you need for doing Core Data. Swift flavour.

[Objective-C version](https://github.com/albertodebortoli/Skiathos)

## General notes

This component aims to have an extremely easy interface to introduce Core Data into your app with almost zero effort.

The design introduced here involves a few main components:

- CoreDataStack
- AppStateReactor
- DALService (Data Access Layer)

### CoreDataStack

If you have experience with Core Data, you might know that creating a stack is an annoying process full of pitfalls.
This component is responsible for the creation of the stack (in terms of chain of managed object contexts) using the design described [here](http://martiancraft.com/blog/2015/03/core-data-stack/) by Marcus Zarra.

```
      Managed Object Model <------ Persistent Store Coordinator ------> Persistent Store
                                                ^
                                                |
                        Private Context (NSPrivateQueueConcurrencyType)
                                                ^
                                                |
              ------------> Main Context (NSMainQueueConcurrencyType) <-------------
              |                                 ^                                  |
              |                                 |                                  |
        Slave Context                     Slave Context                      Slave Context
(NSPrivateQueueConcurrencyType)   (NSPrivateQueueConcurrencyType)    (NSPrivateQueueConcurrencyType)
```

An important difference from Magical Record, or other third-party libraries, is that the saves always go in one direction, from slaves down (or up?) to the persistent store.
Other components allows you to create slaves that have the private context as parent and this causes the main context not to be updated or to be updated via notifications to merge the context.
The main context should be the source of truth and it is tied the UI: having a much simpler approach helps to create a system easier to reason about.

### AppStateReactor

You should ignore this one. It sits in the CoreDataStack and takes care of saving the inflight changes back to disk if the app goes to background, loses focus or is about to be terminated. It's a silent friend who takes care of us.


### DALService (Data Access Layer) / Skopelos

If you have experience with Core Data, you might also know that most of the operations are repetitive and that we usually call `performBlock`/`performBlockAndWait` on a context providing a block that eventually will call `save:` on that context as last statement.
Databases are all about readings and writings and for this reason our APIs are in the form of `read(statements: NSManagedObjectContext -> Void)` and `write(changes: NSManagedObjectContext -> Void)`: 2 protocols providing a CQRS (Command and Query Responsibility Segregation) approach.
Read blocks will be executed on the main context (as it's considered to be the single source of truth). Write blocks are executed on a slave context which is saved synchronously at the end; changes are eventually saved asynchronously back to the persistent store without blocking the main thread. 
The method `write(changes: NSManagedObjectContext -> Void, completion: (NSError? -> Void)?) -> Self` calls the completion handler when the changes are saved back to the persistent store.  

In other words, writings are always consistent in the main managed object context and eventual consistent in the persistent store.
Data are always available in the main managed object context.

`Skopelos` is just a subclass of `DALService`, to give a nice name to the component. 


## How to use

To use this component, you could create a property of type `Skopelos` and instantiate it like so:

```swift
self.skopelos = SkopelosClient.inMemoryStack("<#DataModelFileName>")
```
or
```swift
self.skopelos = SkopelosClient.sqliteStack("<#DataModelFileName>")
```

You could then pass around the skopelos in other parts of the app via dependency injection.
It has to be said that it's perfectly acceptable to use a singleton for the Core Data stack. Also, allocating instances over and over of `Skopelos`is expensive. Genrally speaking, we don't like singletons. They are not testable by nature, clients don't have control over the lifecycle of the object and they break some principles. For these reasons, the library comes free of singletons.

There are 2 reasons why you should inherit from `Skopelos`:

- to create a shared instance for global access
- to override `override func handleError(error: NSError)` to perform specific actions when an error is encountered and this method is called 

To create a singleton, you should inherit from Skopelos like so:

### Singleton

```swift
class SkopelosClient: Skopelos {

    static let sharedInstance = SkopelosClient.sqliteStack("DataModel")

    override func handleError(error: NSError) {
        // clients should do the right thing here
        print(error.description)
    }
}
```

### Readings and writings

Speaking of readings and writings, let's do now a comparison between some standard Core Data code and code written with Skopelos.

Standard Core Data reading:

```objc
__block NSArray *results = nil;

NSManagedObjectContext *context = ...;
[context performBlockAndWait:^{

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass(User)
    inManagedObjectContext:context];
    [request setEntity:entityDescription];

    NSError *error;
    results = [context executeFetchRequest:request error:&error];
}];

return results;
```

Standard Core Data writing:

```objc
NSManagedObjectContext *context = ...;
[context performBlockAndWait:^{

    User *user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(User)
    inManagedObjectContext:context];
    user.firstname = @"John";
    user.lastname = @"Doe";

    NSError *error;
    [context save:&error];
    if (!error)
    {
        // continue to save back to the store
    }
}];

```

Skopelos reading: 

```swift
SkopelosClient.sharedInstance.read({ (context: NSManagedObjectContext) in
    let users = User.SK_all(context)
    print(users)
})
```

Skopelos writing:

```swift
SkopelosClient.sharedInstance.write({ (context: NSManagedObjectContext) in
    let user = User.SK_create(context) as! User
    user.firstname = "John"
    user.lastname = "Doe"
})

SkopelosClient.sharedInstance.write({ (context: NSManagedObjectContext) in
    let user = User.SK_create(context) as! User
    user.firstname = "John"
    user.lastname = "Doe"
    }, completion: { (error: NSError?) in
        // changes are saved to the persistent store
})
```

Skopelos also supports dot notation and chaining:

```swift
SkopelosClient.sharedInstance.write({ (context: NSManagedObjectContext) in
    user = User.SK_create(context) as! User
    user.firstname = "John"
    user.lastname = "Doe"
}).write({ (context: NSManagedObjectContext) in
    if let userInContext = user.SK_inContext(context) {
        userInContext.SK_remove(context)
    }
}).read({ (context: NSManagedObjectContext) in
    let users = User.SK_all(context)
    print(users)
})
```

The `NSManagedObject` category provides CRUD methods always explicit on the context. The context passed as parameter should be the one received in the read or write block. You should always use these methods from within read/write blocks. Main methods are:

```swift
class func SK_create(context: NSManagedObjectContext) -> NSManagedObject
class func SK_numberOfEntities(context: NSManagedObjectContext) -> Int
func SK_remove(context: NSManagedObjectContext) -> Void
class func SK_removeAll(context: NSManagedObjectContext) -> Void
class func SK_all(context: NSManagedObjectContext) -> [NSManagedObject]
class func SK_all(predicate: NSPredicate, context:NSManagedObjectContext) -> [NSManagedObject]
class func SK_first(context: NSManagedObjectContext) -> NSManagedObject?
```

Mind the usage of `SK_inContext:` to retrieve an object in different read/write blocks (same read blocks are safe).


## Thread-safery notes

All the accesses to the persistence layer done via a `Skopelos` instance are guaranteed to be thread-safe.

It is highly suggested to enable the flag `-com.apple.CoreData.ConcurrencyDebug 1` in your project to make sure that the you don't misuse Core Data in terms of threading and concurrency (by accessing managed objects from different threads and similar errors).

This component doesn't aim to introduce interfaces with the goal of hiding the concept of `ManagedObjectContext`: it would open up the doors to threading issues in clients' code as developers should be responsible to check for the type of the calling thread at some level (that would be ignoring the benefits that Core Data gives to us).
Therefore, our design forces to make all the readings and writings via the `DALService` and the `ManagedObject` category methods are intended to always be explicit on the context (e.g. `SK_create`).


## TO DO

- Unit tests
- Solve the cast NSManagedObject to Self problem
- Create a pod/whatever
