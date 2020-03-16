# Guide to Consuming Rust Components on iOS

The application services libraries are published as a single zip file containing all the individual component frameworks (such as *Logins.framework*, *FxAClient.framework*) and also a single composite (megazord) framework called *MozillaAppServices.framework* containing all the components.

The client-side can choose to use a single component framework, or the composite.

The package is published as a release on github: https://github.com/mozilla/application-services/releases

## Carthage

- Add the dependency line to the Cartfile, for instance: `github "mozilla/application-services" ~> "v0.16.1"` 
- `carthage` will download MozillaAppServices.frameworks.zip, and add all the available frameworks to the 'Carthage/' dir.
- Link against the provided MozillaAppServices.framework (in the *Link Binary with Libraries* step in your Xcode target).
- Add additional dependencies, see [below](#additional-dependencies).

### Adding a carthage provided framework to Xcode
- In general, to do this, add *XXX.framework* from *Carthage/Build/iOS* to *Link binary with Libraries* for the Xcode target
- `MozillaAppServices.framework` is being built as a static lib; therefore, do _not_ follow the standard Carthage procedure of adding it to your `carthage copy-frameworks` script.

### Using a Circle-CI built framework

Rather than using a tagged release version, one can grab the build from Circle-CI, like so:

`binary "https://circleci.com/api/v1.1/project/github/mozilla/application-services/2862/artifacts/0/dist/mozilla.app-services.json" ~> 0.0.1-snapshot`

## Additional dependencies

The project has additional 3rd-party dependencies that a client must link against.

### NSS

- In your project, add all the .dylibs in the `../Carthage/Build/iOS/MozillaAppServices.framework` directory to both the "Embedded Binaries" and the "Linked Frameworks and Libraries" panels.

### Protobuf

- *SwiftProtoBuf.framework* should be automatically downloaded by carthage while pulling in the application-services dependency.
- [Add that framework to Xcode.](#adding-a-carthage-provided-framework-to-xcode)

## Third-party licenses

This project incorporates code from a number of third-party dependencies,
under a variety of open-source licenses. You should review the license info
in the file `DEPENDENCIES.md` and decide on an appropriate way to include
license and attribution notices into your product.




