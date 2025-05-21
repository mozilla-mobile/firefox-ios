import SwiftUI

public extension Image {
    /// Attempts to load `name` from your asset catalog first; if missing, falls back to SF Symbols.
    init(assetOrSymbol name: String, bundle: Bundle? = nil) {
        if let uiImage = UIImage(named: name, in: bundle, compatibleWith: nil) {
            // Found in Assets
            self = Image(uiImage: uiImage)
        } else {
            // Not in Assets → assume an SF Symbol
            self = Image(systemName: name)
        }
    }
}
