# Application Services Release Process

These are the steps needed to cut a new release from latest master.

1. Update the changelog.
    1. Copy the contents from `CHANGES_UNRELEASED.md` into the top of `CHANGELOG.md`, except for the part that links to this document.
    2. In `CHANGELOG.md`:
        1. Replace `# Unreleased Changes` with `# v<new-version-number> (_<current date>_)`.
        2. Replace `master` in the Full Changelog link (which you pasted in from `CHANGES_UNRELEASED.md`) to be `v<new-version-number>`. E.g. if you are releasing 0.13.2, the link should be
            ```
            [Full Changelog](https://github.com/mozilla/application-services/compare/v0.13.1...v0.13.2)
            ```
            Note that this needs three dots (`...`) between the two tags (two dots is different). Yes, the second tag doesn't exist yet, you'll make it later.
        3. Optionally, go over the commits between the past release and this one and see if anything is worth including.
        4. Make sure the changelog follows the format of the other changelog entries. If you have access, [this document](https://docs.google.com/document/d/1oxdGm7OQcsy78NzXjMQKTbfzn21tl9Nopmvo8NCMWmU) is fairly comprehensive. For a concrete example, at the time of this writing, see the [0.13.0](https://github.com/mozilla/application-services/blob/master/CHANGELOG.md#0130-2019-01-09) release notes.
            - Note that we try to provide PR or issue numbers (and links) for each change. Please add these if they are missing.

    3. In `CHANGES_UNRELEASED.md`:
        1. Delete the list of changes that are now in the changelog.
        2. Update the "Full Changelog" link so that it starts at your new version and continues to master. E.g. for 0.13.2 this would be
            ```
            [Full Changelog](https://github.com/mozilla/application-services/compare/v0.13.2...master)
            ```
            Again, this needs 3 dots.

2. Bump `libraryVersion` in the top-level [.buildconfig-android.yml](https://github.com/mozilla/application-services/blob/master/.buildconfig-android.yml) file. Be sure you're following semver, and if in doubt, ask.
3. Land the commits that perform the steps above. This takes a PR, typically, because of branch protection on master.
4. Cut the actual release.
    1. Click "Releases", and then "Draft a New Release" in the github UI.
    2. Enter `v<myversion>` as the tag. In the example above it would be `v0.13.2`. It's important this is the same as the tags you put in the links in the changelog.
    3. Under the description, paste the contents of the release notes from CHANGELOG.md.
    4. Note that the release is not avaliable until the taskcluster build completes for that tag.
        - Finding this out takes a little navigation in the github UI. It's available at `https://github.com/mozilla/application-services/commits/v<VERSION NUMBER>` in the build status info (the emoji) next to the last commit.
        - If the taskcluster tag and/or release tasks fail, ping someone in slack and we'll figure out what to do.
5. If you need to manually produce the iOS build for some reason (for example, if CircleCI cannot), someone with a mac needs to do the following steps:
    1. If necessary, set up for performing iOS builds:
        ```
        $ rustup target add aarch64-apple-ios x86_64-apple-ios
        $ brew outdated carthage || brew upgrade carthage
        $ brew install swift-protobuf
        $ carthage bootstrap
        ```
    2. Run `./build-carthage.sh` in the root of the repository.
    3. Upload the resulting `MozillaAppServices.framework.zip` as an attachment on the github release.
6. In order for consumers to have access, we need to update in [android-components](https://github.com/mozilla-mobile/android-components).
    1. If the changes expose new functionality, or otherwise require changes to code or documentation in https://github.com/mozilla-mobile/android-components, perform those. This part is often done at the same time as the changes in application-services, to avoid being blocked on steps 3-4 of this document.
    2. Change the versions of our dependencies in [buildSrc/src/main/java/Dependencies.kt](https://github.com/mozilla-mobile/android-components/blob/master/buildSrc/src/main/java/Dependencies.kt).
    3. Note the relevant changes in their [docs/changelog.md](https://github.com/mozilla-mobile/android-components/blob/master/docs/changelog.md), and update the application-services version there as well in their list of dependency versions.
    4. **_Important: Manually test the changes versus the samples in android-components._**
        - We do not have automated test coverage for much of the network functionality at this point, so this is crucial.
        - You can do this before the release has been cut by adding `substitutions.application-services.dir=/path/to/application-services` in your `local.properties` file in android-components. Remember that you have done this, however, as it overrides changes in `Dependencies.kt`.

    5. Get it PRed and landed.


These are the steps needed to cut a new point-release from an existing release that is behind latest master.

1. If necessary, make a new branch named `release-v0.XX` which will be used for all point-releases on the `v0.XX.Y`
   series. Example:
    ```
    git checkout -b release-v0.31 v0.31.2
    git push -u origin release-v0.31
    ```
2. Make a new branch with any fixes to be included in the release, *remembering not to make any breaking API
   changes.*. This may involve cherry-picking fixes from master, or developing a new fix directly against the
   branch. Example:
    ```
    git checkout -b fixes-for-v0.31.3 release-v0.31
    git cherry-pick 37d35304a4d1d285c8f6f3ce3df3c412fcd2d6c6
    git push -u origin fixes-for-v0.31.3
    ```
3. Follow the above steps for cuting a new release from master, except that:
    * When opening a PR to land the commits, target the `release-v0.XX` branch rather than master.
    * When cutting the new release via github's UI, target the `release-v0.XX` branch rather than master.
4. Merge the new release back to master.
    * This will typically require a PR and involve resolving merge conflicts in the changelog.
    * This ensures we do not accidentally orphan any fixes that were made directly against the release branch,
      and also helps ensure that every release has an easily-discoverable changelog entry in master.
