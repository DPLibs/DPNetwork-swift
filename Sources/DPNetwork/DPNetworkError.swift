import Foundation

open class DPNetworkError: NSError {}

public extension DPNetworkError {
    
    static var unknown: DPNetworkError {
        .init(domain: "unknown", code: 0, userInfo: nil)
    }
    
    static var invalidRequest: DPNetworkError {
        .init(domain: "invalidRequest", code: 1, userInfo: nil)
    }
    
    static func responseErrorStatusCode(_ statusCode: Int) -> DPNetworkError {
        .init(domain: "responseErrorStatusCode", code: statusCode, userInfo: nil)
    }
    
    static func error(_ error: Error?) -> DPNetworkError? {
        let nsError = error as NSError?
        
        return .init(domain: nsError?.description ?? "", code: nsError?.code ?? 0, userInfo: nil)
    }
    
}
