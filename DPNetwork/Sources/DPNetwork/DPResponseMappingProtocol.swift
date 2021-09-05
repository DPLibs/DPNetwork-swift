import Foundation

public protocol DPResponseMappingProtocol: Codable {
    associatedtype ModelType
    
    func mapToModel() throws -> ModelType
}
