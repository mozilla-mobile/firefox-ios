
## How to expose your Rust Component to Kotlin

Welcome!

It's great that you've built a Rust Component and want to expose it to Koltin,
but we haven't written a complete guide yet.

Please share your :+1: on [the relevant github
issue](https://github.com/mozilla/application-services/issues/599) to let us
know that you wanted it.

In the meantime, here are some preliminary notes:

### High-level overview.

The [logins](/components/logins) component provides a useful example. We assume
you have written a nice core of Rust code in a [./src/](/components/logins/src)
directory for your component.

First, you will need to flatten the Rust API into a set of FFI bindings,
conventionally in a [./ffi/](/components/logins/ffi) directory. Use the
[ffi_support](https://docs.rs/ffi-support/0.1.3/ffi_support/) crate to help make
this easier, which will involve implementing some traits in the core rust code.
Consult the crate's documentation for tips and gotchas.

Next, you will need to write Kotlin code that consumes that FFI,
conventionally in a [./android/](/components/logins/android) directory. This
code should use [JNA](https://github.com/java-native-access/jna) to load the
compiled rust code via shared library and expose it as a nice safe ergonomic
Kotlin API.

It seems likely that we could provide a useful template here to get you started.
But we haven't yet.

Finally, you will need to add your package into the
[android-components](https://github.com/mozilla-mobile/android-components) repo
via some undocumented process that starts by asking in the rust-components
channel on slack.

### How should I name the resulting package?

Published packages should be named `org.mozilla.appservices.$NAME` where `$NAME`
is the name of your component, such as `logins`.  The Java namespace in which
your package defines its classes etc should be `mozilla.appservices.$NAME.*`.

### How do I publish the resulting package?

Great question! We should write or link to an answer here.

### How do I know what library name to load to access the compiled rust code?

Great question! We should write or link to an answer here.

### Why can’t we use cbindgen or an alternative C binding generator?

We could, but it wouldn’t save us that much. cbindgen would automate the process
of turning the ffi crate's source into the equivalent C header file, however it
wouldn’t help with the kotlin code (although one could imagine something that
automated generation of the kotlin bindings file). In particular, it wouldn’t
help us produce the ffi crate’s code, or the wrappers that make the bindings
safe (this is most of the work). It would be nice to automate the process, but
it hasn’t been particularly error prone to update it by hand so far.

It’s also worth noting that the ffi crate’s source doesn’t have the ownership
information encoded in it with regards to strings (they’re all pointers to
c_char), which makes generating kotlin bindings harder, since the kotlin
bindings need to take/return Pointer for strings owned by Rust, and String for
strings owned by Kotlin. This is because when we later release the string owned
by rust, it must be the same pointer we were given earlier (If you pass String,
JNA allocates temporary memory for the call, passes you it, and releases it
afterwards).

(The solution to this would likely be something like wasm_bindgen, where you
annotate your Rust source. The tool would then spit out both the FFI crate, and
the bulk of the Kotlin/Swift APIs. This would be a lot of work, but it would be
cool to have someday).

cbindgen doesn’t always work seamlessly. It’s a standalone parser of rust code,
not a rustc plugin -- it doesn’t always understand your rust library like the
compiler does. A number of these issues cropped up when autopush used it: e.g.
it being unable to parse newer rust code or having buggy handling of certain
rust syntax.

### What design principles should inform my component API?

Many, most of which aren't written down yet. This is an incomplete list:

* Avoid callbacks where possible, in favour of simple blocking calls.
* Think of building a "library", not a "framework"; the application should be in
  control and calling functions exposed by your component, not providing
  functions for your component to call.

### What challenges exist when calling back into Kotlin from Rust?

There are a number of them. The issue boils down to the fact that you need to be
completely certain that a JVM is associated with a given thread in order to call
java code on it. The difficulty is that the JVM can GC its threads and will not
let rust know about it. JNA can work around this for us to some extent, however
there are difficulties.

The approach it takes is essentially to spawn a thread for each callback
invocation. If you are certain you’re going to do a lot of callbacks and they
all originate on the same thread, you can tell it to cache these.

Calling back from Rust into Kotlin isn’t too bad so long as you ensure the
callback can not be GCed while rust code holds onto it, and you can either
accept the overhead of extra threads being instantiated on each call, or you can
ensure that it only happens from a single thread.

Note that the situation would be somewhat better if we used JNI directly (and
not JNA), but this would cause us to need to write two versions of each ffi
crate, one for iOS, and one for Android.

Ultimately, in any case where you can reasonably move to making something a
blocking call, do so. It’s very easy to run such things on a background thread
in Kotlin. This is in line with the Android documentation on JNI usage, and my
own experience. It’s vastly simpler and less painful this way.

(Of course, not every case is solvable like this).

### Why are we using JNA rather than JNI, and what tradeoffs does that involve?

We get a couple things from using JNA that we wouldn't with JNI.

1. We are able to write a *single* FFI crate. If we used JNI we'd need to write
   one FFI that android calls, and one that iOS calls.

2. JNA provides a mapping of threads to callbacks for us, making callbacks over
   the FFI possible. That said, in practice this is still error prone, and easy
   to misuse/cause memory safety bugs, but it's required for cases like logging,
   among others, and so it is a nontrivial piece of complexity we'd have to
   reimplement.

However, it comes with the following downsides:

1. JNA has bugs. In particular, its not safe to use bools with them, it thinks
   they are 32 bits, when on most platforms (every platform Rust supports) they
   are 8 bits. They've been unwilling to fix the issue due to it breaking
   backwards compatibility (which is... somewhat fair, there is a lot of C89
   code out there that uses `bool` as a typedef for a 32-bit `int`).
2. JNA makes it really easy to do the wrong thing and have it work but corrupt
   memory. Several of the caveats around this are documented in the
   [`ffi_support` docs](https://docs.rs/ffi-support/*/ffi_support/), but a
   major one is when to use `Pointer` vs `String` (getting this wrong will
   often work, but may corrupt memory).

### How do I debug Rust code with the step-debugger in Android Studio

1. Uncomment the `packagingOptions { doNotStrip "**/*.so" }` line from the
   build.gradle file of the component you want to debug.
2. In the rust code, either:
    1. Cause something to crash where you want the breakpoint. Note: Panics
        don't work here, unfortunately. (I have not found a convenient way to
        set a breakpoint to rust code, so
        `unsafe { std::ptr::write_volatile(0 as *const _, 1u8) }` usually is
        what I do).
    2. If you manage to get an LLDB prompt, you can set a breakpoint using
       `breakpoint set --name foo`, or `breakpoint set --file foo.rs --line 123`.
       I don't know how to bring up this prompt reliably, so I often do step 1 to
       get it to appear, delete the crashing code, and then set the
       breakpoint using the CLI. This is admittedly suboptimal.
3. Click the Debug button in Android Studio, to display the "Select Deployment
   Target" window.
4. Make sure the debugger selection is set to "Both". This tends to unset
   itself, so make sure.
5. Click "Run", and debug away.
