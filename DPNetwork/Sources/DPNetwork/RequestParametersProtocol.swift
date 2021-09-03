import Foundation

public protocol RequestParametersProtocol: Codable {
    func toData() -> Data?
//    func toDictionary() -> Dictionary?
//    func toQueryString() -> String?
//    func toFormData(boundary: Boundary) -> Data?
}

public extension RequestParametersProtocol {
    
    func toData() -> Data? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        
        return data
    }
    
//    func toDictionary() -> Dictionary? {
//        guard let data = self.toData() else { return nil }
//
//        let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
//        let result = dictionary.flatMap { $0 as? Dictionary }
//
//        return result
//    }
    
//    func toQueryString() -> String? {
//        self.toDictionary()?
//            .map({ parameter in
//                var result: String = ""
//                guard let key = parameter.key.addingPercentEncoding() else { return result }
//                
//                switch parameter.value {
//                case let stringValue as String:
//                    if let value = stringValue.addingPercentEncoding() {
//                        result = "\(key)=\(value)"
//                    }
//                case let arrayValue as [Any]:
//                    var arrayParameter: [String] = []
//        
//                    for index in 0..<arrayValue.count {
//                        var element: String {
//                            if let stringElement = arrayValue[index] as? String {
//                                return stringElement
//                            } else {
//                                return "\(arrayValue[index])"
//                            }
//                        }
//        
//                        guard let value = element.addingPercentEncoding() else { continue }
//                        arrayParameter.append("\(key)[]=\(value)")
//                    }
//        
//                    result = arrayParameter.joined(separator: "&")
//                default:
//                    if let value = "\(parameter.value)".addingPercentEncoding() {
//                        result = "\(key)=\(value)"
//                    }
//                }
//        
//                return result
//            })
//            .joined(separator: "&")
//    }
    
//    func toFormData(boundary: Boundary) -> Data? {
//        guard let dictionary = self.toDictionary(), !dictionary.isEmpty else { return nil }
//        var result = Data()
//        
//        for (key, value) in dictionary {
//            result.appendStrings([
//                "--\(boundary.stringValue)\r\n",
//                "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n",
//                "\(value)\r\n"
//            ])
//        }
//        
//        return result
//    }
    
}
