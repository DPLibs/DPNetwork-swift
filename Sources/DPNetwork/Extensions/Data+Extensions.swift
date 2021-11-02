import Foundation

public extension Data {
    
    var mimeType: String {
        let mimeTypeSignatures: [UInt8: String] = [
            0xFF: "image/jpeg",
            0x89: "image/png",
            0x47: "image/gif",
            0x49: "image/tiff",
            0x4D: "image/tiff",
            0x25: "application/pdf",
            0xD0: "application/vnd",
            0x46: "text/plain"
        ]
        
        var code: UInt8 = 0
        copyBytes(to: &code, count: 1)
        
        return mimeTypeSignatures[code] ?? "application/octet-stream"
    }
    
    mutating func appendStrings(_ strings: [String?]) {
        strings.forEach({
            guard let string = $0, let data = string.data(using: .utf8) else { return }
            
            self.append(data)
        })
    }
    
    func toString(encoding: String.Encoding) -> String? {
        String(data: self, encoding: encoding)
    }
    
    func decodeToCodable<T: Codable>(_ codable: T.Type) throws -> T {
        try JSONDecoder().decode(codable, from: self)
    }

}
