import Foundation

open class RequestMappingModels<Response: ResponseMappingProtocol>: Request {
    public private(set) var isLoadingAll: Bool = false
    
    open func loadModels(isReload: Bool, limit: Int?, completion: (([Response.ModelType], HTTPURLResponse?, Error?) -> Void)? = nil) {
        if isReload {
            self.isLoadingAll = false
        }
        
        guard !self.isLoadingAll else { return }
        self.cancel()
        
        self.load(model: [Response].self) { [weak self] result, httpURLResponse, error in
            guard let self = self else { return }
            
            if let limit = limit, let result = result {
                self.isLoadingAll = limit > result.count
            }
            
            let models = result?.map({ $0.mapToModel() }) as? [Response.ModelType] ?? []
            completion?(models, httpURLResponse, error)
        }
    }
}
