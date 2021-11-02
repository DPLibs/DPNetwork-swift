import Foundation

open class DPRequestWithMappingResponse<Response: DPResponseMappingProtocol>: DPRequest {
    public typealias ModelResult = Result<Response.ModelType?, Error>
    public typealias ModelsResult = Result<[Response.ModelType], Error>
    
    public typealias ModelClosure = (ModelResult) -> Void
    public typealias ModelsClosure = (ModelsResult) -> Void
    
    // MARK: - Props
    public private(set) var modelsIsLoadingAll: Bool = false
    
    // MARK: - Methods
    open func loadModel(urlRequest: URLRequest?, forceReload: Bool, completion: ModelClosure?) {
        self.load(urlRequest, forceReload: forceReload, decodeTo: Response.self) { loadResult in
            var result: Result<Response.ModelType?, Error> {
                switch loadResult {
                case let .success(response):
                    return .success(response.mapToModel())
                case let .failure(error):
                    return .failure(error)
                }
            }
            
            completion?(result)
        }
    }
    
    open func loadModels(urlRequest: URLRequest?, forceReload: Bool, limit: Int?, completion: ModelsClosure?) {
        if forceReload {
            self.modelsIsLoadingAll = false
        }
        
        guard !self.modelsIsLoadingAll else { return }
        
        self.load(urlRequest, forceReload: forceReload, decodeTo: [Response].self) { loadResult in
            var result: Result<[Response.ModelType], Error> {
                switch loadResult {
                case let .success(responses):
                    let models = responses.mapToModels()
                    
                    if let limit = limit {
                        self.modelsIsLoadingAll = models.count < limit
                    }
                    
                    return .success(models)
                case let .failure(error):
                    return .failure(error)
                }
            }
            
            completion?(result)
        }
    }
    
}
