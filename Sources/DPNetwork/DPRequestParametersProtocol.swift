import Foundation

public protocol DPRequestParametersProtocol: Codable {
    func toData() -> Data?
    func toDictionary() -> Dictionary?
    func toQueryString() -> String?
    func toFormData(boundary: Boundary) -> Data?
}

public extension DPRequestParametersProtocol {
    
    func toData() -> Data? {
        do {
            let data = try JSONEncoder().encode(self)
            
            return data
        } catch {
            print("[RequestParametersProtocol] - [toData] - error:", error)
            
            return nil
        }
    }
    
    func toDictionary() -> Dictionary? {
        guard let data = self.toData() else { return nil }

        do {
            let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary
            
            return dictionary
        } catch {
            print("[RequestParametersProtocol] - [toDictionary] - error:", error)
            
            return nil
        }
    }
    
    func toQueryString() -> String? {
        guard let dictionary = self.toDictionary() else { return nil }
        var resultArray: [String] = []
        
        dictionary.forEach { parameter in
            var item: String? {
                guard let key = parameter.key.addingPercentEncoding() else { return nil }
                
                switch parameter.value {
                
                case let stringValue as String:
                    guard let value = stringValue.addingPercentEncoding() else { return nil }
                    return "\(key)=\(value)"
                    
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
        
                    return arrayParameter.joined(separator: "&")
                    
                default:
                    guard let value = "\(parameter.value)".addingPercentEncoding() else { return nil }
                    return "\(key)=\(value)"
                }
            }
            
            guard let item = item else { return }
            resultArray += [item]
        }
        
        return resultArray.joined(separator: "&")
    }
    
    func toFormData(boundary: Boundary) -> Data? {
        guard let dictionary = self.toDictionary(), !dictionary.isEmpty else { return nil }
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
    
}
