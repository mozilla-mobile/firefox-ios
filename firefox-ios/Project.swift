import ProjectDescription
import ProjectDescriptionHelpers

/*
 Where to find what (Tuist/ProjectDescriptionHelpers/):
   BuildConfigurations.swift    — build configs + baseSettings
   Packages+Ecosia.swift        — SPM packages
   BuildScripts.swift           — client + extension build scripts
   ExtensionConfigurations.swift — 6 configs per extension (ShareTo, WidgetKit)
   Targets+Client.swift         — Client app target
   Targets+Extensions.swift     — ShareTo, WidgetKitExtension
   Targets+Frameworks.swift     — Account, Storage, Sync, Localizations, Ecosia, RustMozillaAppServices
   Targets+Tests.swift           — all test targets
   Schemes+Ecosia.swift         — Ecosia, EcosiaBeta, EcosiaSnapshotTests schemes
 */

// MARK: - Targets (order: extensions & frameworks first, then app, then tests)

let allTargets: [Target] =
    ExtensionTargets.all() +
    FrameworkTargets.all() +
    [ClientTarget.target()] +
    TestTargets.all()

// MARK: - Project

let project = Project(
    name: "Client",
    organizationName: "com.ecosia",
    options: .options(
        automaticSchemesOptions: .disabled,
        disableSynthesizedResourceAccessors: true
    ),
    packages: Packages.all,
    settings: .settings(configurations: BuildConfigurations.all),
    targets: allTargets,
    schemes: EcosiaSchemes.all,
    // Ecosia: Register root agent instruction files as Xcode project files so
    // that Xcode's Coding Assistant can index and use them. Files under
    // Ecosia/Ecosia.docc/ are already covered by the Ecosia framework target's
    // resource glob and don't need to be listed here.
    additionalFiles: [
        "../AGENTS.md",
        "../CLAUDE.md"
    ] + BuildConfigurations.additionalFiles,
)
