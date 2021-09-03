import Foundation

public struct ResponseStatusCode: Equatable {
    
    // MARK: - Props
    public let intValue: Int
    
    // MARK: - Init
    public init(intValue: Int) {
        self.intValue = intValue
    }
    
    static var defaultSuccessful: [Self] {
        [
            .init(intValue: 200),
            .init(intValue: 204)
        ]
    }
}
 
public extension Array where Element == ResponseStatusCode {
    
    static var defaultSuccessful: Self {
        Element.defaultSuccessful
    }
    
}
