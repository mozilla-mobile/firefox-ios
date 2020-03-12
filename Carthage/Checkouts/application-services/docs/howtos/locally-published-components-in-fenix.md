# Using locally-published components in Fenix

Note: This is a bit tedious, and you might like to try the substitution-based
approach documented in [Development with the Reference Browser](./working-with-reference-browser.md).
That approach is still fairly new, and the local-publishing approach in this document
is necessary if it fails.

Note 2: This is fenix-specific only in that some links on the page go to the
`mozilla-mobile/fenix` repository, and that I'm describing `fenix`, however
these steps should work for e.g. `reference-browser`, as well. (Same goes for
lockwise, or any other consumer of our components, but they may use a different
structure -- lockwise has no Dependencies.kt, for example)

1. Inside the `application-services` repository root:
    1. In [`.buildconfig-android.yml`](app-services-yaml), change
       `libraryVersion` to end in `-TESTING$N` <sup><a href="#note1">1</a></sup>,
       where `$N` is some number that you haven't used for this before.

       Example: `libraryVersion: 0.27.0-TESTING3`
    2. Check your `local.properties` file, and add `rust.targets=x86` if you're
       testing on the emulator, `rust.targets=arm` if you're testing on 32-bit
       arm (arm64 for 64-bit arm, etc). This will make the build that's done in
       the next step much faster.
    3. Run `./gradlew publishToMavenLocal`. This may take between 5 and 10 minutes.

2. Inside the `android-components` repository root:
    1. In [`.buildconfig.yml`](android-components-yaml), change
       `componentsVersion` to end in `-TESTING$N` <sup><a href="#note1">1</a></sup>,
       where `$N` is some number that you haven't used for this before.

       Example: `componentsVersion: 0.51.0-TESTING3`
    2. Inside [`buildSrc/src/main/java/Dependencies.kt`](android-components-deps),
       change `mozilla_appservices` to reference the `libraryVersion` you
       published in step 2 part 1.

       Example: `const val mozilla_appservices = "0.27.0-TESTING3"`

    3. Inside [`build.gradle`](android-components-build-gradle), add
       `mavenLocal()` inside `allprojects { repositories { <here> } }`.

    4. Inside the android-component's `local.properties` file, ensure
       `substitutions.application-services.dir` is *NOT* set.

    5. Run `./gradlew publishToMavenLocal`.

3. Inside the `fenix` repository root:
    1. Inside [`build.gradle`](fenix-build-gradle-1), add
       `mavenLocal()` inside `allprojects { repositories { <here> } }`.
        1. If you added a new project to the megazord (e.g. you went through the
           parts of step 1) you must also add `mavenLocal()` to
           [`buildscript { ... dependencies { <here> }}`](fenix-build-gradle-2)

    2. Inside fenix's `local.properties` file, ensure
       `substitutions.application-services.dir` is *NOT* set.

    3. Inside [`buildSrc/src/main/java/Dependencies.kt`](fenix-deps), change
       `mozilla_android_components` to the version you defined in step 3 part 1.

       Example: `const val mozilla_android_components = "0.51.0-TESTING3"`
        1. If you added a new project to the megazord (e.g. you went through the
           parts of step 1) you must also change `appservices_gradle_plugin` to
           the version you defined in step 1 part 1.

            Example: `const val appservices_gradle_plugin = "0.4.4-TESTING3"`
        2. If there are any direct dependencies on application services (at the
           moment there are not, but there have been in the past and may be in
           the future), change it's version here to the one defined in step 2
           part 1.

You should now be able to build and run fenix (assuming you could before all
this).

## Caveats

1. This assumes you have followed the [android/rust build setup](./setup-android-build-environment.md)
2. Make sure you're fully up to date in all repos, unless you know you need to
   not be.
3. This omits the steps if changes needed because, e.g. application-services
   made a breaking change to an API used in android-components. These should be
   understandable to fix, you usually should be able to find a PR with the fixes
   somewhere in the android-component's list of pending PRs (or, failing that, a
   description of what to do in the application-services changelog).
4. Ask in #rust-components slack (or #sync on mozilla IRC if you are an
   especially brave external contributor) if you get stuck.

---

<b id="note1">[1]</b>: It doesn't have to start with `-TESTING`, it only needs
to have the format `-someidentifier`. `-SNAPSHOT$N` is also very common to use,
however without the numeric suffix, this has specific meaning to gradle, so we
avoid it.  Additionally, while the `$N` we have used in our running example has
matched (e.g. all of the identifiers ended in `-TESTING3`, this is not required,
so long as you match everything up correctly at the end. This can be tricky, so
I always try to use the same number).

[app-services-yaml]: https://github.com/mozilla/application-services/blob/594f4e3f6c190bc5a6732f64afc573c09020038a/.buildconfig-android.yml#L1
[android-components-yaml]: https://github.com/mozilla-mobile/android-components/blob/b98206cf8de818499bdc87c00de942a41f8aa2fb/.buildconfig.yml#L1
[android-components-deps]: https://github.com/mozilla-mobile/android-components/blob/b98206cf8de818499bdc87c00de942a41f8aa2fb/buildSrc/src/main/java/Dependencies.kt#L37
[android-components-build-gradle]: https://github.com/mozilla-mobile/android-components/blob/b98206cf8de818499bdc87c00de942a41f8aa2fb/build.gradle#L28
[fenix-build-gradle-1]: https://github.com/mozilla-mobile/fenix/blob/f897c2e295cd1b97d4024c7a9cb45dceb7a2fa89/build.gradle#L26
[fenix-build-gradle-2]: https://github.com/mozilla-mobile/fenix/blob/f897c2e295cd1b97d4024c7a9cb45dceb7a2fa89/build.gradle#L6
[fenix-deps]: https://github.com/mozilla-mobile/fenix/blob/f897c2e295cd1b97d4024c7a9cb45dceb7a2fa89/buildSrc/src/main/java/Dependencies.kt#L28
