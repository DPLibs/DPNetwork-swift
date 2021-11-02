import Foundation

public struct DPBoundary {
    
    // MARK: - Props
    public let stringValue: String
    
    // MARK: - Init
    private init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public static func generate() -> Self {
        self.init(stringValue: "Boundary-\(UUID().uuidString)")
    }
}
