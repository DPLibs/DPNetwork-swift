import Foundation

open class DPRequest: NSObject {
    public typealias CodableResult<T: Codable> = Result<T, Error>
    public typealias CodableClosure<T: Codable> = (CodableResult<T>) -> Void
    public typealias ErrotClosure = (Error?) -> Void
    
    // MARK: - Props
    open lazy var worker: DPNetworkWorkerInterface = DPNetworkWorker(
        session: .init(configuration: .default),
        successfulResponseStatusCodes: .defaultSuccessful,
        isLoggingEnabled: true
    )
    
    open private(set) var isLoading: Bool = false
    
    // MARK: - Init
    public override init() {}
    
    // MARK: - Methods
    open func cancel() {
        self.worker.cancelDataTask()
    }
    
    open func load<T: Codable>(_ urlRequest: URLRequest?, forceReload: Bool, decodeTo codableType: T.Type, completion: CodableClosure<T>?) {
        if forceReload {
            self.isLoading = false
        }

        guard !self.isLoading else { return }
        self.isLoading = true
        
        self.worker.loadURLRequest(urlRequest, decodeTo: codableType) { [weak self] data, _, error in
            var result: Result<T, Error> {
                guard let data = data, error == nil else {
                    return .failure(error ?? DPNetworkError.unknown)
                }
                
                return .success(data)
            }
            
            completion?(result)
            self?.isLoading = false
        }
    }
    
    open func loadEmpty(_ urlRequest: URLRequest?, forceReload: Bool, completion: ErrotClosure?) {
        if forceReload {
            self.isLoading = false
        }

        guard !self.isLoading else { return }
        self.isLoading = true
        
        self.worker.loadURLRequest(urlRequest) { [weak self] _, _, error in
            completion?(error)
            self?.isLoading = false
        }
    }
    
}
