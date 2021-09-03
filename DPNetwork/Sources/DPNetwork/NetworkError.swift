import Foundation

open class NetworkError: NSError {
    
    public override init(domain: String, code: Int, userInfo: [String: Any]?) {
        super.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

public extension NetworkError {
    
    static var invalidRequest: NetworkError {
        .init(domain: "invalidRequest", code: 999, userInfo: nil)
    }
    
    static func responseErrorStatusCode(_ statusCode: Int) -> NetworkError {
        .init(domain: "responseErrorStatusCode", code: statusCode, userInfo: nil)
    }
    
    static func error(_ error: Error?) -> NetworkError? {
        let nsError = error as NSError?
        
        return .init(domain: nsError?.description ?? "", code: nsError?.code ?? 0, userInfo: nil)
    }
    
}
