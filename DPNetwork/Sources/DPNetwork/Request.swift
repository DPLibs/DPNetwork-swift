import Foundation

open class Request: NSObject {
    
    // MARK: - Props
    public let urlPath: Request.URLPath
    public let methodType: Request.MethodType
    public let bodyType: Request.BodyType
    public let parameters: RequestParametersProtocol?
    public let headers: [Request.Header]?
    public let files: Request.Files?
    
    public lazy var worker: NetworkWorkerInterface = NetworkWorker()
    public private(set) var isLoading: Bool = false
    
    // MARK: - Init
    public init(
        urlPath: Request.URLPath,
        methodType: Request.MethodType,
        bodyType: Request.BodyType,
        parameters: RequestParametersProtocol?,
        headers: [Request.Header]?,
        files: Request.Files?
    ) {
        self.urlPath = urlPath
        self.methodType = methodType
        self.bodyType = bodyType
        self.parameters = parameters
        self.headers = headers
        self.files = files
    }
    
    // MARK: - Methods
    open func createURLRequest() -> URLRequest? {
        switch self.methodType {
        
        case .get,
             .head:
            var urlPath = self.urlPath.path
            
            if let parameters = self.parametersToQueryString() {
                urlPath += "?" + parameters
            }
            
            guard let url = URL(string: urlPath) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = self.methodType.httpMethod.stringValue
            request.setRequestHeaders(self.headers)
            
            return request
            
        case .post,
             .put,
             .patch,
             .delete:
            guard let url = URL(string: self.urlPath.path) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = self.methodType.httpMethod.stringValue
            request.setRequestHeaders(self.headers)
            
            switch self.bodyType {
            case .none:
                break
            case .json:
                if let httpBody = self.parameters?.toData() {
                    request.httpBody = httpBody
                    request.setRequestHeaders([.init(key: .contentType, value: .applicationJson)])
                }
            case .formData:
                let boundary = Boundary.generate()
                
                if let httpBody = self.parametersToFormData(boundary: boundary) {
                    request.httpBody = httpBody
                    request.setRequestHeaders([.init(key: .contentType, value: .applicationFormData(with: boundary))])
                }
            }
            
            return request
            
        case .upload:
            guard let url = URL(string: self.urlPath.path) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = self.methodType.httpMethod.stringValue
            request.setRequestHeaders(self.headers)
            
            let boundary = Boundary.generate()
            request.setRequestHeaders([.init(key: .contentType, value: .multipartFormData(with: boundary))])
            
            var httpBody: Data {
                var result = Data()
                
                result.appendDatas([
                    self.parametersToFormData(boundary: boundary),
                    self.files?.createFormData(boundary: boundary)
                ])
                
                result.appendStrings(["--\(boundary)--\r\n"])
                
                return result
            }
            
            request.httpBody = httpBody
            
            return request
        }
    }
    
    open func parametersToData() -> Data? {
        self.parameters?.toData()
    }
    
    open func parametersToDictionary() -> Dictionary? {
        guard let data = self.parametersToData() else { return nil }

        let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        let result = dictionary.flatMap { $0 as? Dictionary }

        return result
    }
    
    open func parametersToQueryString() -> String? {
        guard let dictionary = self.parametersToDictionary() else { return nil }
        
        let result = dictionary
            .map({ parameter in
                var result: String = ""
                guard let key = parameter.key.addingPercentEncoding() else { return result }
                
                switch parameter.value {
                case let stringValue as String:
                    if let value = stringValue.addingPercentEncoding() {
                        result = "\(key)=\(value)"
                    }
                case let arrayValue as [Any]:
                    var arrayParameter: [String] = []
        
                    for index in 0..<arrayValue.count {
                        var element: String {
                            if let stringElement = arrayValue[index] as? String {
                                return stringElement
                            } else {
                                return "\(arrayValue[index])"
                            }
                        }
        
                        guard let value = element.addingPercentEncoding() else { continue }
                        arrayParameter.append("\(key)[]=\(value)")
                    }
        
                    result = arrayParameter.joined(separator: "&")
                default:
                    if let value = "\(parameter.value)".addingPercentEncoding() {
                        result = "\(key)=\(value)"
                    }
                }
        
                return result
            })
            .joined(separator: "&")
        
        return result
    }
    
    open func parametersToFormData(boundary: Boundary) -> Data? {
        guard let dictionary = self.parametersToDictionary(), !dictionary.isEmpty else { return nil }
        var result = Data()
        
        for (key, value) in dictionary {
            result.appendStrings([
                "--\(boundary.stringValue)\r\n",
                "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
                "\(value)\r\n"
            ])
        }
        
        return result
    }
    
    open func load<T: Codable>(model: T.Type, completion: ((T?, HTTPURLResponse?, Error?) -> Void)?) {
        guard let request = self.createURLRequest() else { return }
        
        guard !self.isLoading else { return }
        self.isLoading = true
        
        self.worker.execute(request, model: model) { [weak self] result, httpURLResponse, error in
            guard let self = self else { return }
            
            self.isLoading = false
            completion?(result, httpURLResponse, error)
        }
    }
    
    open func cancel() {
        guard let request = self.createURLRequest() else { return }
        
        self.worker.cancel(request)
    }
    
}

// MARK: - Request + Static
public extension Request {
    
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
        
        public var httpMethod: Request.HTTPMethod {
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
        public let files: [Request.File]
        
        // MARK: - Init
        public init(fileKey: String, files: [Request.File]) {
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
public extension Request.Header.Key {
    
    static var contentType: Self {
        .init(stringValue: "Content-Type")
    }
    
}

// MARK: - Request.Header.Value + Store
public extension Request.Header.Value {
    
    static var applicationJson: Self {
        .init(stringValue: "application/json")
    }
    
    static func applicationFormData(with boundary: Boundary) -> Self {
        .init(stringValue: "application/form-data; boundary=\(boundary.stringValue)")
    }
    
    static func multipartFormData(with boundary: Boundary) -> Self {
        .init(stringValue: "multipart/form-data; boundary=\(boundary.stringValue)")
    }
    
}
