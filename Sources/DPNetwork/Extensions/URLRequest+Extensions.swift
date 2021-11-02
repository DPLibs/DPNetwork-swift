import Foundation

public extension URLRequest {
    
    mutating func appendRequestHeaders(_ headers: [DPURLRequestGenerator.Header]?) {
        headers?.forEach({ header in
            self.setValue(header.value.stringValue, forHTTPHeaderField: header.key.stringValue)
        })
    }
    
}
