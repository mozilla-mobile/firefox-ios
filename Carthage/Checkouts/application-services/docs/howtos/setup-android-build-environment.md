## Doing a local build of the Android Components:

This document describes how to make local builds of the Android components in
this repository. Most consumers of these components *do not* need to follow
this process, but will instead use pre-built components [todo: link to this]

This document, and the build process itself, is a work-in-progress - please file issues (or just update the wiki!) if you notice errors or omissions.

## Prepare your build environment

*NOTE: This section is almost certainly incomplete - given it is typically
only done once, things have probably been forgotten or over-simplified.
Please file PRs if you notice errors or omissions here*

This process should work OK on Mac and Linux. It also works on [Windows via WSL by following these instructions](#using-windows).

Typically, this process only needs to be run once, although periodically you
may need to repeat some steps (eg, rust updates should be done periodically)

At the end of this process you should have the following environment variables set up.

- `ANDROID_NDK_ROOT`
- `ANDROID_NDK_HOME`
- `ANDROID_NDK_API_VERSION`
- `ANDROID_HOME`
- `JAVA_HOME`

These variables are required every time you build, so you should add them to
a rc file or similar so they persist between reboots etc.

1. Install NDK r20 from https://developer.android.com/ndk/downloads
    - Extract it, put it somewhere (`$HOME/.android-ndk-r20` is a reasonable
      choice, but it doesn't matter), and set `ANDROID_NDK_ROOT` to this location.
    - Set `ANDROID_NDK_HOME` to match `ANDROID_NDK_ROOT`, for compatibility with
      some android grandle plugins.

2. Install `rustup` from https://rustup.rs:
    - If you already have it, run `rustup update`
    - Run `rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android`

3. Ensure your clone of `mozilla/application-services` is up to date.

4. Install or locate Java
    - Either install Java, or, if Android Studio is installed, you can probably find one
      installed in a `jre` directory under the Android Studio directory.
    - Set `JAVA_HOME` to this location and add it to your rc file.

5. Install or locate the Android SDKs
   - Install the Android SDKs. If Android Studio is involved, it may have already installed
     them somewhere - use the "SDK Manager" to identify this location.
   - Set `ANDROID_HOME` to this location and add it to your rc file.

6. Build NSS and SQLCipher
    - `cd path/to/application-services/libs` (Same dir you were just in for step 4)
    - `./build-all.sh android` (Go make some coffee or something, this will take
       some time as it has to compile NSS and SQLCipher for x86, x86_64, arm, and arm64).
    - Note that if something goes wrong here
        - Check all environment variables mentions above are set and correct.

## Building

Having done the above, the build process is the easy part! Again, ensure all
environment variables mentioned above are in place.

1. Ensure your clone of application-services is up-to-date.

2. Ensure rust is up-to-date by running `rustup`

3. The builds are all performed by `./gradlew` and the general syntax used is
   `./gradlew project:task`

   You can see a list of projects by executing `./gradlew projects` and a list
   of tasks by executing `./gradlew tasks`.

### Publishing the components to your local maven repository.

The easiest way to use the build is to have your Android project reference the component from your local maven repository - this is done by the `publishToMavenLocal` task - so:

    ./gradlew publishToMavenLocal

should work. Check your `~/.m2` directory (which is your local maven repo) for the components.

You can also publish single projects - eg:

    ./gradlew service-sync-places:publishToMavenLocal

For more information about using the local maven repo, see this [android components guide](https://mozilla-mobile.github.io/android-components/contributing/testing-components-inside-app)

### Other build types

If you just want the build artifacts, you probably want one of the `assemble` tasks - either
   `assembleDebug` or `assembleRelease`.

For example, to build a debug version of the places library, the command you
want is `./gradlew places:assembleDebug`

After building, you should find the built artifact under the `target` directory,
with sub-directories for each Android architecture. For example, after executing:

    % ./gradlew places:assembleDebug

you will find:

    target/aarch64-linux-android/release/libplaces_ffi.so
    target/x86_64-linux-android/release/libplaces_ffi.so
    target/i686-linux-android/release/libplaces_ffi.so
    target/armv7-linux-androideabi/release/libplaces_ffi.so

(You will probably notice that even though as used `assembleDebug`, the directory names are `release` - this may change in the future)

You should also find the .kt files for the project somewhere there and in the right directory structure if that turns out to be useful.

# Using Windows

It's currently tricky to get some of these builds working on Windows, primarily due to our use of `sqlcipher`. However, by using the Windows Subsystem for Linux, it is possible to get builds working, but still have them published to your "native" local maven cache so it's available for use by a "native" Android Studio.

As above, this document may be incomplete, so please edit or open PRs where necessary.

In general, you will follow the exact same process outlined above, with one or 2 unique twists.

## Setting up the build environment

You need to install most of the build tools in WSL. This means you end up with many tools installed twice - once in WSL and once in "native" Windows - but the only cost of that is disk-space.

You will need the following tools in WSL:

* unzip - `sudo apt install unzip`

* python 3 - `sudo apt install python3`

* java - you may already have it? try `java -version`. Java ended up causing me grief (stuck at 100% CPU doing nothing), but google pointed at one popular way of installing java:

    ```
    sudo add-apt-repository ppa:webupd8team/java
    sudo apt-get update
    sudo apt-get install oracle-java8-installer
    sudo apt install oracle-java8-set-default
    ```

* tcl, used for sqlcipher builds - `sudo apt install tcl-dev`

* Android SDKs - this process is much the same as for normal Linux - roughly

  * visit https://developer.android.com/studio/, at the bottom of the page locate the current SDKs for linux
at time of writing, this is https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip

    ```
    cd ~
    mkdir android-sdk
    cd android-sdk
    unzip {path-to.zip}
    export ANDROID_HOME=$HOME/android-sdk
    $ANDROID_HOME/tools/bin/sdkmanager "platforms;android-26"
    $ANDROID_HOME/tools/bin/sdkmanager --licenses
    ```

(Note - it may be necessary to execute `$ANDROID_HOME/tools/bin/sdkmanager "build-tools;26.0.2" "platform-tools" "platforms;android-26" "tools"`, but may not! See also [this gist](https://gist.github.com/fdmnio/fd42caec2e5a7e93e12943376373b7d0) which google found for me and might have useful info.

* Follow all the other steps above - eg, you still need the NDK setup in WSL and all environment variables above set.

## Configure Maven

We now want to configure maven to use the native windows maven repository - then, when doing `./gradlew install` from WSL, it ends up in the Windows maven repo.

* Execute `sudo apt install maven` - this should have created a `~/.m2` folder as the WSL maven repository. In this directory, create a file `~/.m2/settings.xml` with the content:

    ```
    <settings>
      <localRepository>/mnt/c/Users/{username}/.m2/repository</localRepository>
    </settings>
    ```

  (obviously with {username} adjusted appropriately)

* Now you should be ready to roll - `./gradlew install` should complete and publish the components to your native maven repo!

\o/
