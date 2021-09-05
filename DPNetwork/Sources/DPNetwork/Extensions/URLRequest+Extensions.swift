import Foundation

public extension URLRequest {
    
    mutating func setRequestHeaders(_ headers: [DPRequest.Header]?) {
        headers?.forEach({ header in
            self.setValue(header.value.stringValue, forHTTPHeaderField: header.key.stringValue)
        })
    }
    
    static func create(
        urlPath: DPRequest.URLPath,
        methodType: DPRequest.MethodType,
        bodyType: DPRequest.BodyType,
        parameters: DPRequestParametersProtocol?,
        headers: [DPRequest.Header]?,
        files: DPRequest.Files?
    ) -> Self? {
        switch methodType {
        
        case .get,
             .head:
            var urlPath = urlPath.path
            
            if let parameters = parameters?.toQueryString() {
                urlPath += "?" + parameters
            }
            
            guard let url = URL(string: urlPath) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = methodType.httpMethod.stringValue
            request.setRequestHeaders(headers)
            
            return request
            
        case .post,
             .put,
             .patch,
             .delete:
            guard let url = URL(string: urlPath.path) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = methodType.httpMethod.stringValue
            request.setRequestHeaders(headers)
            
            switch bodyType {
            case .none:
                break
            case .json:
                if let httpBody = parameters?.toData() {
                    request.httpBody = httpBody
                    request.setRequestHeaders([.init(key: .contentType, value: .applicationJson)])
                }
            case .formData:
                let boundary = Boundary.generate()
                
                if let httpBody = parameters?.toFormData(boundary: boundary) {
                    request.httpBody = httpBody
                    request.setRequestHeaders([.init(key: .contentType, value: .applicationFormData(with: boundary))])
                }
            }
            
            return request
            
        case .upload:
            guard let url = URL(string: urlPath.path) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = methodType.httpMethod.stringValue
            request.setRequestHeaders(headers)
            
            let boundary = Boundary.generate()
            request.setRequestHeaders([.init(key: .contentType, value: .multipartFormData(with: boundary))])
            
            var httpBody: Data {
                var result = Data()
                
                result.appendDatas([
                    parameters?.toFormData(boundary: boundary),
                    files?.createFormData(boundary: boundary)
                ])
                
                result.appendStrings(["--\(boundary)--\r\n"])
                
                return result
            }
            
            request.httpBody = httpBody
            
            return request
        }
    }
    
}
