import Foundation

public protocol DPResponseMappingProtocol: Codable {
    associatedtype ModelType
    
    func mapToModel() -> ModelType?
}

public extension Array where Element: DPResponseMappingProtocol {
    
    func mapToModels() -> [Element.ModelType] {
        self.map({ $0.mapToModel() }) as? [Element.ModelType] ?? []
    }
    
}
