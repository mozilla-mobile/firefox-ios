# Swift Code Standards

## MVVM with SwiftUI

- Use MVVM architecture with SwiftUI for new UI components
- Follow protocol-oriented programming principles
- Prefer value types (structs) over reference types (classes) when possible
- Use `ObservableObject` and `@Published` properties for view models

## SwiftUI First Approach

- Use SwiftUI for new UI components; only use UIKit when SwiftUI is insufficient
- Always create a SwiftUI preview to test the View's behavior
- Implement theming through the `EcosiaThemeable` protocol (defined in `Ecosia/UI/ThemeableSwiftUIView.swift`)
- Apply themes with the `.ecosiaThemed(windowUUID, $theme)` view modifier; this automatically updates the theme on appear and on `ThemeDidChange` notifications

### Full theming pattern

1. Define a theme container conforming to `EcosiaThemeable`:

```swift
struct MyComponentTheme: EcosiaThemeable {
    var backgroundColor = Color.white
    var textColor = Color.black

    mutating func applyTheme(theme: Theme) {
        backgroundColor = Color(theme.colors.ecosia.backgroundPrimary)
        textColor = Color(theme.colors.ecosia.textPrimary)
    }
}
```

2. Use it in the view (`windowUUID` is required for per-window theme management):

```swift
struct MyComponent: View {
    private let windowUUID: WindowUUID
    @State private var theme = MyComponentTheme()

    var body: some View {
        Text("Hello")
            .foregroundColor(theme.textColor)
            .background(theme.backgroundColor)
            .ecosiaThemed(windowUUID, $theme)
    }
}
```

- Never use `EcosiaColor` primitives directly in views; always go through a theme's semantic tokens (e.g. `theme.colors.ecosia.backgroundPrimary`).
- `EcosiaColor` is a palette of raw primitives; it is only referenced from within theme implementations.

## Layout and design

### Design system tokens

Always use Ecosia design system types for spacing, borders, and typography. Never use raw `CGFloat` literals for these values.

| Token type | Type | Location |
|---|---|---|
| Spacing | `EcosiaSpacing` | `Ecosia/UI/DesignSystem/EcosiaSpacing.swift` |
| Border radius | `EcosiaBorders` | `Ecosia/UI/DesignSystem/EcosiaBorders.swift` |
| Typography scale | `EcosiaTypography` | `Ecosia/UI/DesignSystem/EcosiaTypography.swift` |
| Colors (semantic) | `theme.colors.ecosia.*` | via `EcosiaThemeable` (see **SwiftUI First Approach**) |

Usage example:

```swift
let spacing = EcosiaSpacing()
let borders = EcosiaBorders()

Text("Hello")
    .padding(spacing._m)           // 16 pt
    .cornerRadius(borders._l)      // 10 pt
```

The same types exist under both `Ecosia/UI/DesignSystem/` (framework) and `firefox-ios/Ecosia/UI/DesignSystem/` (Client target). Use the copy that is in scope for your target; do not mix the two.

### Adaptive layout

- Respect safe areas (notch, Dynamic Island, home indicator, hardware keyboard on iPad). For full-bleed or custom bar layouts, account for `safeAreaInsets` so content and controls are not clipped.
- Adapt to iPhone portrait/landscape, iPad full screen, Split View, and Stage Manager. Prefer adaptive stacks and readable-width containers over fixed pixel values.
- Prefer stack-based layout, `ViewThatFits`, and the SwiftUI `Layout` protocol. Use `GeometryReader` only when the layout genuinely requires a measured container size.
- Handle the software keyboard: keep focused fields visible, avoid obscuring primary actions, and support sensible dismissal.
- Follow [Apple's Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) for navigation, hierarchy, and platform conventions.

## Naming Conventions

- Variables/Functions: `camelCase` (e.g., `searchViewModel`, `handleUserTap`)
- Types/Classes/Structs: `PascalCase` (e.g., `FeedbackViewModel`, `EcosiaHomeView`)
- Constants: `PascalCase` for static properties (e.g., `DefaultTimeout`)
- Methods: Use verbs (e.g., `fetchData`, `applyTheme`, `handleError`)
- Booleans: Use `is`/`has`/`should` prefixes (e.g., `isLoading`, `hasContent`)
- Follow Apple's API Design Guidelines

## Swift Best Practices

- Use strong typing with proper optional handling (`if let`, `guard let`)
- Leverage `async/await` for asynchronous operations
- Use `Result` type for error handling scenarios
- Prefer `let` over `var` for immutable properties
- Use protocol extensions for shared functionality
- Avoid force unwrapping (`!`) except in controlled scenarios
- Use computed properties where appropriate

## Error Handling & Logging

- Use `EcosiaLogger` for consistent logging (levels: `.debug`, `.info`, `.warning`, `.error`)
- Use `.error` log level instead of `.warning` for error conditions
- Include relevant context in log messages; never log sensitive user data
- Implement `Result` type for operations that can fail
- Use `async/await` with proper error propagation using `throws`
- Handle network errors gracefully with user-friendly messages
- Provide fallback behavior for non-critical failures
- Implement retry logic with exponential backoff for network operations

## Analytics

- **ALL** analytics instrumentation must be at the UI/ViewModel layer
- Use `Analytics.shared` (never reassign the shared instance)
- Follow established event patterns in `Analytics.Values.swift`
- Track user actions, not internal system events
- Example: `Analytics.shared.activity(.homePageViewed)`

## Accessibility

- Dark mode compatibility
- Dynamic Type support
- VoiceOver support
- Reduce Motion preference

## Performance

- Use Instruments for performance profiling
- Implement lazy loading for views and data
- Optimize network requests with proper caching strategies
- Keep state management lean: avoid redundant `@Published` churn, unnecessary view body work, and heavy synchronous work on the main thread; offload background processing appropriately
- Use `@StateObject` vs `@ObservedObject` appropriately
- Use `LazyVStack`/`LazyHStack` for efficient list rendering
- Prevent memory leaks and retain cycles

## Security

- Encrypt sensitive data using Keychain Services
- Use secure communication (certificate pinning where needed)
- Implement biometric authentication for sensitive operations
- Follow App Transport Security requirements
- Validate and sanitize all user inputs
