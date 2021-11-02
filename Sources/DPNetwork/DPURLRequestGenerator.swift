//
//  DPURLRequestGenerator.swift
//  
//
//  Created by Дмитрий Поляков on 02.11.2021.
//

import Foundation

open class DPURLRequestGenerator {
    
    // MARK: - Init
    init(
        urlPath: URLPath,
        httpMethod: HTTPMethod,
        headers: [Header]? = nil,
        queryParameters: DPRequestParametersProtocol? = nil,
        bodyType: BodyType? = nil,
        bodyParameters: DPRequestParametersProtocol? = nil,
        files: Files? = nil
    ) {
        self.urlPath = urlPath
        self.httpMethod = httpMethod
        self.bodyType = bodyType
        self.headers = headers
        self.files = files
        
        if let queryParameters = queryParameters {
            self.setQueryParameters(queryParameters)
        }
        
        if let bodyParameters = bodyParameters, let bodyType = bodyType {
            self.setBodyParameters(bodyParameters, bodyType: bodyType)
        }
    }
    
    // MARK: - Props
    public let urlPath: URLPath
    public let httpMethod: HTTPMethod
    open var headers: [Header]?
    open var queryParameters: DPRequestParametersProtocol?
    open var bodyType: BodyType?
    open var bodyParameters: DPRequestParametersProtocol?
    open var files: Files?
    
    // MARK: - Methods
    @discardableResult
    open func setQueryParameters(_ parameters: DPRequestParametersProtocol) -> DPURLRequestGenerator {
        self.queryParameters = parameters
        
        return self
    }
    
    @discardableResult
    open func setBodyParameters(_ parameters: DPRequestParametersProtocol, bodyType: BodyType) -> DPURLRequestGenerator {
        self.bodyParameters = parameters
        self.bodyType = bodyType
        
        return self
    }
    
    open func generateURLRequest() -> URLRequest? {
        guard let url = self.generateURL() else { return nil }
        let boundary = DPBoundary.generate()
        
        var request = URLRequest(url: url)
        request.httpMethod = self.httpMethod.stringValue
        request.appendRequestHeaders(self.generateHeaders(boundary: boundary))
        
        if let httpBody = self.generateHttpBody(boundary: boundary) {
            request.httpBody = httpBody
        }
        
        return request
    }
    
    open func generateURL() -> URL? {
        var urlPath = urlPath.path
        
        if let parameters = self.generateQueryParameters() {
            urlPath += "?" + parameters
        }
        
        return URL(string: urlPath)
    }
    
    open func generateHeaders(boundary: DPBoundary) -> [Header] {
        var headers = self.headers ?? []
        
        if let bodyType = self.bodyType {
            switch bodyType {
            case .json:
                headers += [.init(key: .contentType, value: .applicationJson)]
            case .formData:
                headers += [.init(key: .contentType, value: .applicationFormData(with: boundary))]
            case .formUrlencoded:
                headers += [.init(key: .contentType, value: .applicationFormUrlencoded)]
            case .multipartFormData:
                headers += [.init(key: .contentType, value: .multipartFormData(with: boundary))]
            }
        }
        
        return headers
    }
    
    open func generateHttpBody(boundary: DPBoundary) -> Data? {
        guard let bodyType = self.bodyType else { return nil }
        
        switch bodyType {
        case .json:
            return self.generateJsonHttpBody()
        case .formData:
            return self.generateFormDataHttpBody(boundary: boundary)
        case .formUrlencoded:
            return self.generateFormUrlencodedHttpBody()
        case .multipartFormData:
            var result = Data()
            
            if let parameters = self.generateFormDataHttpBody(boundary: boundary) {
                result.append(parameters)
            }
            
            if let files = self.files?.createFormData(boundary: boundary) {
                result.append(files)
            }
            
            result.appendStrings(["--\(boundary)--\r\n"])
            
            return result
        }
    }
    
    open func generateQueryParameters() -> String? {
        self.queryParameters?.toQueryString()
    }
    
    open func generateJsonHttpBody() -> Data? {
        self.bodyParameters?.toData()
    }
    
    open func generateFormDataHttpBody(boundary: DPBoundary) -> Data? {
        self.bodyParameters?.toFormData(boundary: boundary)
    }
    
    open func generateFormUrlencodedHttpBody() -> Data? {
        self.bodyParameters?.toQueryString()?.data(using: .utf8)
    }
    
    
    
}

public extension DPURLRequestGenerator {
    
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
    
    // MARK: - BodyType
    enum BodyType {
        case json
        case formData
        case formUrlencoded
        case multipartFormData
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
    
    // MARK: - Files
    struct Files {
        
        // MARK: - Props
        public let fileKey: String
        public let files: [File]
        
        // MARK: - Init
        public init(fileKey: String, files: [File]) {
            self.fileKey = fileKey
            self.files = files
        }
        
        // MARK: - Methods
        public func createFormData(boundary: DPBoundary) -> Data? {
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

}

// MARK: - Request.Header.Key + Store
public extension DPURLRequestGenerator.Header.Key {
    
    static var contentType: DPURLRequestGenerator.Header.Key {
        .init(stringValue: "Content-Type")
    }
    
}

// MARK: - Request.Header.Value + Store
public extension DPURLRequestGenerator.Header.Value {
    
    static var applicationJson: DPURLRequestGenerator.Header.Value {
        .init(stringValue: "application/json")
    }
    
    static var applicationFormUrlencoded: DPURLRequestGenerator.Header.Value {
        .init(stringValue: "application/x-www-form-urlencoded")
    }
    
    static func applicationFormData(with boundary: DPBoundary) -> DPURLRequestGenerator.Header.Value {
        .init(stringValue: "application/form-data; boundary=\(boundary.stringValue)")
    }
    
    static func multipartFormData(with boundary: DPBoundary) -> DPURLRequestGenerator.Header.Value {
        .init(stringValue: "multipart/form-data; boundary=\(boundary.stringValue)")
    }
    
}
