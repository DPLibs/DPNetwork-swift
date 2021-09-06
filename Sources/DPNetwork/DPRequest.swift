import Foundation

open class DPRequest: NSObject {
    
    // MARK: - Props
    open lazy var session: DPURLSessionInterface = DPNetworkWorker(
        session: .init(configuration: .default),
        successfulResponseStatusCodes: .defaultSuccessful,
        isLoggingEnabled: true
    )
    
    open private(set) var isLoading: Bool = false
    
    // MARK: - Init
    public override init() {}
    
    // MARK: - Methods
    open func cancel() {
        self.session.cancelDataTask()
    }
    
    open func load<T: Codable>(
        _ urlRequest: URLRequest?,
        forceReload: Bool,
        decodeTo codableType: T.Type,
        completion: ((Result<T, Error>) -> Void)?
    ) {
        if forceReload {
            self.isLoading = false
        }

        guard !self.isLoading else { return }
        self.isLoading = true
        
        self.session.loadURLRequest(urlRequest, decodeTo: codableType) { [weak self] data, _, error in
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
    
    open func loadEmpty(
        _ urlRequest: URLRequest?,
        forceReload: Bool,
        completion: ((Error?) -> Void)?
    ) {
        if forceReload {
            self.isLoading = false
        }

        guard !self.isLoading else { return }
        self.isLoading = true
        
        self.session.loadURLRequest(urlRequest) { [weak self] _, _, error in
            completion?(error)
            self?.isLoading = false
        }
    }
    
}

// MARK: - Request + Static
public extension DPRequest {
    
    // MARK: - HTTPMethod
    enum HTTPMethod: String {
        case options = "OPTIONS"
        case get = "GET"
        case head = "HEAD"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case trace = "TRACE"
        case connect = "CONNECT"
        
        public var stringValue: String {
            return self.rawValue
        }
    }
    
    // MARK: - MethodType
    enum MethodType {
        case get
        case head
        case post
        case put
        case patch
        case delete
        case upload
        
        public var httpMethod: DPRequest.HTTPMethod {
            switch self {
            case .get:
                return .get
            case .head:
                return .head
            case .post:
                return .post
            case .put:
                return .put
            case .patch:
                return .patch
            case .delete:
                return .delete
            case .upload:
                return .post
            }
        }
    }
    
    // MARK: - BodyType
    enum BodyType {
        case none
        case json
        case formData
        case formUrlencoded
    }
    
    // MARK: - URLPath
    struct URLPath {
        // MARK: - Props
        public let path: String
        
        // MARK: - Init
        private init(path: String) {
            self.path = path
        }
        
        public static func path(_ path: String) -> Self {
            self.init(path: path)
        }
    }
    
    // MARK: - Header
    struct Header {
        
        // MARK: - Static
        public struct Key: Equatable {
            
            // MARK: - Props
            public let stringValue: String
            
            // MARK: - Init
            public init(stringValue: String) {
                self.stringValue = stringValue
            }
        }
        
        public struct Value: Equatable {
            
            // MARK: - Props
            public let stringValue: String
            
            // MARK: - Init
            public init(stringValue: String) {
                self.stringValue = stringValue
            }
        }
        
        // MARK: - Props
        public let key: Key
        public let value: Value
        
        // MARK: - Init
        public init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    // MARK: - Files
    struct Files {
        
        // MARK: - Props
        public let fileKey: String
        public let files: [DPRequest.File]
        
        // MARK: - Init
        public init(fileKey: String, files: [DPRequest.File]) {
            self.fileKey = fileKey
            self.files = files
        }
        
        // MARK: - Methods
        public func createFormData(boundary: Boundary) -> Data? {
            guard !self.files.isEmpty else { return nil }
            var result = Data()
            
            for file in self.files {
                result.appendStrings([
                    "--\(boundary.stringValue)\r\n",
                    "Content-Disposition: form-data; name=\"\(self.fileKey)\"; filename=\"\(file.filename)\"\r\n",
                    "Content-Type: \(file.data.mimeType)\r\n\r\n"
                ])
                
                result.append(file.data)
                result.appendStrings(["\r\n"])
            }
            
            return result
        }
    }
    
    // MARK: - File
    struct File {
        
        // MARK: - Props
        public let filename: String
        public let data: Data
        
        // MARK: - Init
        public init(filename: String, data: Data) {
            self.filename = filename
            self.data = data
        }
    }
    
}

// MARK: - Request.Header.Key + Store
public extension DPRequest.Header.Key {
    
    static var contentType: DPRequest.Header.Key {
        .init(stringValue: "Content-Type")
    }
    
}

// MARK: - Request.Header.Value + Store
public extension DPRequest.Header.Value {
    
    static var applicationJson: DPRequest.Header.Value {
        .init(stringValue: "application/json")
    }
    
    static var applicationFormUrlencoded: DPRequest.Header.Value {
        .init(stringValue: "application/x-www-form-urlencoded")
    }
    
    static func applicationFormData(with boundary: Boundary) -> DPRequest.Header.Value {
        .init(stringValue: "application/form-data; boundary=\(boundary.stringValue)")
    }
    
    static func multipartFormData(with boundary: Boundary) -> DPRequest.Header.Value {
        .init(stringValue: "multipart/form-data; boundary=\(boundary.stringValue)")
    }
    
}
