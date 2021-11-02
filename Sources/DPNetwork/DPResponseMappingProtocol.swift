import Foundation

public protocol DPResponseMappingProtocol: Codable {
    associatedtype ModelType
    
    func mapToModel() -> ModelType?
}

// MARK: - Array + DPResponseMappingProtocol
public extension Array where Element: DPResponseMappingProtocol {
    
    func mapToModels() -> [Element.ModelType] {
        var result: [Element.ModelType] = []
        
        self.forEach({ response in
            guard let model = response.mapToModel() else { return }
            result += [model]
        })
        
        return result
    }
    
}

// MARK: - Array + DPResponseMappingProtocol + Optional
public extension Array {

    func mapOptionalsToModels<T: DPResponseMappingProtocol>() -> [T.ModelType] where Element == T? {
        var result: [T.ModelType] = []
        
        self.forEach({ response in
            guard let model = response?.mapToModel() else { return }
            result += [model]
        })
        
        return result
    }
}
