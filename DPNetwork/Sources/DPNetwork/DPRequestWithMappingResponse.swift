import Foundation

open class DPRequestWithMappingResponse<Response: DPResponseMappingProtocol>: DPRequest {
    
    // MARK: - Props
    public private(set) var modelsIsLoadingAll: Bool = false
    
    // MARK: - Methods
    open func loadModel(
        urlRequest: URLRequest?,
        forceReload: Bool,
        completion: ((Result<Response.ModelType, Error>) -> Void)?
    ) {
        self.load(urlRequest, forceReload: forceReload, decodeTo: Response.self) { loadResult in
            var result: Result<Response.ModelType, Error> {
                switch loadResult {
                case let .success(response):
                    do {
                        let model = try response.mapToModel()
                        
                        return .success(model)
                    } catch {
                        return .failure(error)
                    }
                case let .failure(error):
                    return .failure(error)
                }
            }
            
            completion?(result)
        }
    }
    
    open func loadModels(
        urlRequest: URLRequest?,
        forceReload: Bool,
        limit: Int?,
        completion: ((Result<[Response.ModelType], Error>) -> Void)?
    ) {
        if forceReload {
            self.modelsIsLoadingAll = false
        }
        
        guard !self.modelsIsLoadingAll else { return }
        
        self.load(urlRequest, forceReload: forceReload, decodeTo: [Response].self) { loadResult in
            var result: Result<[Response.ModelType], Error> {
                switch loadResult {
                case let .success(responses):
                    do {
                        let models = try responses.map({ response in
                            try response.mapToModel()
                        })
                        
                        if let limit = limit {
                            self.modelsIsLoadingAll = models.count < limit
                        }
                        
                        return .success(models)
                    } catch {
                        return .failure(error)
                    }
                case let .failure(error):
                    return .failure(error)
                }
            }
            
            completion?(result)
        }
    }
    
}
