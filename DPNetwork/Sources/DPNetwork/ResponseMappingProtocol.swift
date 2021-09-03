import Foundation

public protocol ResponseMappingProtocol: Codable {
    associatedtype ModelType
    
    func mapToModel() -> ModelType?
}
