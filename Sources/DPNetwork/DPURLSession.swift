import Foundation

public protocol DPURLSessionInterface: AnyObject {
    var isLoggingEnabled: Bool { get set }
    
    func cancelDataTask()
    func loadURLRequest(_ urlRequest: URLRequest?, completion: DPURLSession.LoadCompletion<Data>?)
    func loadURLRequest<T: Codable>(_ urlRequest: URLRequest?, decodeTo codableType: T.Type, completion: DPURLSession.LoadCompletion<T>?)
}

open class DPURLSession: URLSession, DPURLSessionInterface {
    
    // MARK: - Static
    public typealias LoadCompletion<DataType> = (DataType?, HTTPURLResponse?, Error?) -> Void
    
    public struct ResponseStatusCode: Equatable {
        
        // MARK: - Props
        public let intValue: Int
        
        // MARK: - Init
        public init(intValue: Int) {
            self.intValue = intValue
        }
    }
    
    // MARK: - Props
    public let successfulResponseStatusCodes: [ResponseStatusCode]
    
    open var isLoggingEnabled: Bool
    open var dataTask: URLSessionDataTask?
    
    // MARK: - Init
    public init(
        configuration: URLSessionConfiguration,
        delegate: URLSessionDelegate?,
        delegateQueue: OperationQueue?,
        successfulResponseStatusCodes: [ResponseStatusCode],
        isLoggingEnabled: Bool
    ) {
        self.successfulResponseStatusCodes = successfulResponseStatusCodes
        self.isLoggingEnabled = isLoggingEnabled
        
        super.init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
    
    // MARK: - Methods
    open func cancelDataTask() {
        self.dataTask?.cancel()
    }
    
    open func logging(_ items: Any...) {
        guard self.isLoggingEnabled else { return }
        
        var printItems = items
        printItems.insert("[RequestWorker] -", at: 0)
        
        print(printItems)
    }
    
    open func loadURLRequest(
        _ urlRequest: URLRequest?,
        completion: LoadCompletion<Data>?
    ) {
        guard let urlRequest = urlRequest else {
            completion?(nil, nil, DPNetworkError.invalidRequest)
            return
        }
        
        let completionHandler: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
            guard let self = self else { return }
            
            guard let response = response as? HTTPURLResponse, error == nil else {
                let networkError: DPNetworkError = .error(error) ?? .unknown
                self.logging("[\(#function)] - error:", networkError)
                completion?(nil, nil, networkError)
                
                return
            }
            
            self.logging(
                "[\(#function)] -",
                "request.url:", urlRequest.url?.absoluteString ?? "nil", ";",
                "request.headres:", urlRequest.allHTTPHeaderFields ?? "nil", ";",
                "request.httpBody:", String(data: urlRequest.httpBody ?? .init(), encoding: .utf8) ?? "nil", ";",
                "response.statusCode:", response.statusCode, ";",
                "response.headers:", response.allHeaderFields as? [String: Any] ?? "nil", ";",
                "response.data:", data?.toString(encoding: .utf8) ?? "nil"
            )
            
            guard self.successfulResponseStatusCodes.contains(.init(intValue: response.statusCode)) else {
                let networkError: DPNetworkError = .responseErrorStatusCode(response.statusCode)
                self.logging("[\(#function)] - error:", networkError)
                completion?(nil, nil, networkError)
                
                return
            }
            
            completion?(data, response, nil)
        }
        
        self.dataTask?.cancel()
        self.dataTask = self.dataTask(with: urlRequest, completionHandler: completionHandler)
        self.dataTask?.resume()
    }
    
    open func loadURLRequest<T: Codable>(
        _ urlRequest: URLRequest?,
        decodeTo codableType: T.Type,
        completion: LoadCompletion<T>?
    ) {
        self.loadURLRequest(urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                let networkError: DPNetworkError = .error(error) ?? .unknown
                self.logging("[\(#function)] - error:", networkError)
                completion?(nil, nil, networkError)
                
                return
            }
            
            do {
                let dataDecoded = try data.decodeToCodable(codableType)
                
                completion?(dataDecoded, response, nil)
            } catch {
                self.logging("[\(#function)] - error:", error)
                completion?(nil, nil, error)
            }
        }
    }
    
}

// MARK: - DPURLSession.StatusCode + Store
public extension DPURLSession.ResponseStatusCode {
    
    static var defaultSuccessful: [Self] {
        [
            .init(intValue: 200),
            .init(intValue: 204)
        ]
    }
    
}

// MARK: - DPURLSession.StatusCode + Array
public extension Array where Element == DPURLSession.ResponseStatusCode {
    
    static var defaultSuccessful: Self {
        Element.defaultSuccessful
    }
    
}
