
# Megazording

Each Rust component published by Application Services is conceptually a stand-alone library, but for
distribution we compile all the rust code for all components together into a single `.so` file. This
has a number of advantages:

* Easy and direct interoperability between different components at the Rust level
* Cross-component optimization of generated code
* Reduced code size thanks to distributing a single copy of the rust stdlib, low-level dependencies, etc.

This process is affectionately known as "megazording" and the resulting artifact as a ***megazord library***.

On iOS, this process is quite straightforward: we build all the rust code into a single statically-linked
framework, and the consuming application can import the corresponding Swift wrappers and link in just the
parts of the framework that it needs at compile time.

On Android, the situation is more complex due to the way packages and dependencies are managed.
We need to distribute each component as a separate Android ARchive (AAR) that can be managed as a dependency
via gradle, we need to provide a way for the application to avoid shipping rust code for components that it
isn't using, and we need to do it in a way that maintanins the advantages listed above.

This document describes our current approach to meeting all those requirements on Android.

## AAR Dependency Graph

We publish a separate AAR for each component (e.g. fxaclient, places, logins) which contains
*just* the Kotlin wrappers that expose the relevant functionality to Android. Each of these AARs depends on a separate
shared "megazord" AAR in which all the rust code has been compiled together into a single `.so` file.
The application's dependency graph thus looks like this:

[![megazord dependency diagram](https://docs.google.com/drawings/d/e/2PACX-1vTA6wL3ibJRNjKXsmescTfKTx0w_fpr5NcDIF_4T5AsnZfCi8UEEcav8vibocSyKpHOQOk5ysiDBm-D/pub?w=727&h=546)](https://docs.google.com/drawings/d/1owo4wo2F1ePlCq2NS0LmAOG4jRoT_eVBahGNeWHuhJY/)

This generates a kind of strange inversion of dependencies in our build pipeline:

* Each individual component defines both a rust crate and an Android AAR.
* There is a special "full-megazord" component that also defines a rust crate and an Android AAR.
* The full-megazord rust crate depends on the rust crates for each individual component.
* But the Android AAR for each component depends on the Android AAR of the full-megazord!

It's a little odd, but it has the benefit that we can use gradle's dependency-replacement features to easily
manage the rust code that is shipping in each application.

## Custom Megazords

By default, an application that uses *any* appservices component will include the compiled rust code
for *all* appservices components.

To reduce its overall code size, the application can use gradle's [module replacement
rules](https://docs.gradle.org/current/userguide/customizing_dependency_resolution_behavior.html#sec:module_replacement)
to replace the "full-megazord" AAR with a custom-built megazord AAR containing only the components it requires.
Such an AAR can be built in the same way as the "full-megazord", and simply avoid depending on the rust
crates for components that are not required.

To help ensure this replacement is done safely at runtime, the `mozilla.appservices.support.native` provides
helper functions for loading the correct megazord `.so` file.  The Kotlin wrapper for each component should
load its shared library by calling `mozilla.appservices.support.native.loadIndirect`, specifying both the
name of the component and the expected version number of the shared library.

## Unit Tests

The full-megazord AAR contains compiled rust code that targets various Android platforms, and is not
suitable for running on a Desktop development machine. In order to support integration with unittest
suites such as robolectric, each megazord has a corresponding Java ARchive (JAR) distribution named e.g.
`full-megazord-forUnitTests.jar`. This contains the rust code compiled for various Desktop architectures,
and consumers can add it to their classpath when running tests on a Desktop machine.


## Gotchas and Rough Edges

This setup mostly works, but has a handful of rough edges.

The `build.gradle` for each component needs to declare an explicit dependency on `project(":full-megazord")`,
otherwise the resulting AAR will not be able to locate the compiled rust code at runtime. It also needs to
declare a dependency between its build task and that of the full-megazord, for reasons. Typically this looks something
like:

```
tasks["generate${productFlavor}${buildType}Assets"].dependsOn(project(':full-megazord').tasks["cargoBuild"])
```

In order for unit tests to work correctly, the `build.gradle` for each component needs to add the `rustJniLibs`
directory of the full-megazord project to its `srcDirs`, otherwise the unittests will not be able to find and load
the compiled rust code. Typically this looks something like:

```
test.resources.srcDirs += "${project(':full-megazord').buildDir}/rustJniLibs/desktop"
```

The above also means that unittests will not work correctly when doing local composite builds,
because it's unreasonable to expect the main project (e.g. Fenix) to include the above in its build scripts.

