import Foundation

func fixture(_ name: String, withExtension: String?) -> String {
    let testBundle = Bundle(for: SQLiteTestCase.self)
    return testBundle.url(
        forResource: URL(string: "fixtures")?.appendingPathComponent(name).path,
        withExtension: withExtension)!.path
}
