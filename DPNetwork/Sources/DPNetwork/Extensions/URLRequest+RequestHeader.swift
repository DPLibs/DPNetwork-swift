import Foundation

public extension URLRequest {
    
    mutating func setRequestHeaders(_ headers: [Request.Header]?) {
        headers?.forEach({ header in
            self.setValue(header.value.stringValue, forHTTPHeaderField: header.key.stringValue)
        })
    }
    
}
