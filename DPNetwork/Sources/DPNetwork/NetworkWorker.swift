import Foundation

public protocol NetworkWorkerInterface: AnyObject {
    var isLoggingEnabled: Bool { get set }

    func execute<T: Codable>(_ request: URLRequest, model: T.Type, completion: ((_ result: T?, _ response: HTTPURLResponse?, _ error: Error?) -> Void)?)
    func cancel(_ request: URLRequest)
}

open class NetworkWorker: NSObject, NetworkWorkerInterface {
    
    // MARK: - Props
    private weak var sessionDelegate: URLSessionDelegate?
    private var urlSession: URLSession?
    private var activeTasks: [String: URLSessionDataTask]
    private var successfulResponseStatusCodes: [ResponseStatusCode]
    public var isLoggingEnabled: Bool
    
    // MARK: - Init
    public init(
        sessionConfiguration: URLSessionConfiguration? = nil,
        sessionDelegate: URLSessionDelegate? = nil,
        successfulResponseStatusCodes: [ResponseStatusCode] = .defaultSuccessful,
        isLoggingEnabled: Bool = true
    ) {
        self.sessionDelegate = sessionDelegate
        self.urlSession = URLSession(configuration: sessionConfiguration ?? .default, delegate: sessionDelegate, delegateQueue: nil)
        self.activeTasks = [:]
        self.successfulResponseStatusCodes = successfulResponseStatusCodes
        self.isLoggingEnabled = isLoggingEnabled
    }
    
    // MARK: - RemoteWorkerInterface
    public func execute<T: Codable>(
        _ request: URLRequest, model: T.Type,
        completion: ((_ result: T?, _ response: HTTPURLResponse?, _ error: Error?) -> Void)?
    ) {
        guard let taskAbsoluteString: String = request.url?.absoluteString else {
            completion?(nil, nil, NetworkError.invalidRequest)
            
            return
        }
        
        guard self.activeTasks[taskAbsoluteString] == nil else {
            self.logging("[\(#function)] - Duplicate task with url:", request.url?.absoluteString ?? "nil")
            
            self.activeTasks[taskAbsoluteString]?.cancel()
            
            return
        }
        
        let taskCompletionHandler: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
            guard let self = self else { return }
            
            guard let receivedResponse = response as? HTTPURLResponse, error == nil else {
                self.logging("[\(#function)] - receivedResponse is nil -  error:", NetworkError.error(error) ?? "nil")
                
                self.activeTasks[taskAbsoluteString] = nil
                completion?(nil, nil, error)
                
                return
            }
            
            guard let receivedData = data else {
                self.logging(
                    "[\(#function)] -",
                    "response.statusCode:", receivedResponse.statusCode, ";",
                    "response.headers:", receivedResponse.allHeaderFields as? [String: Any] ?? "nil", ";",
                    "error:", error ?? "nil"
                )
                
                self.activeTasks[taskAbsoluteString] = nil
                completion?(nil, receivedResponse, error)
                
                return
            }
            
            self.logging(
                "[\(#function)] -",
                "request.url:", request.url?.absoluteString ?? "nil", ";",
                "request.headres:", request.allHTTPHeaderFields ?? "nil", ";",
                "request.httpBody:", String(data: request.httpBody ?? .init(), encoding: .utf8) ?? "nil", ";",
                "response.statusCode:", receivedResponse.statusCode, ";",
                "response.headers:", receivedResponse.allHeaderFields as? [String: Any] ?? "nil", ";",
                "response.data:", String(data: receivedData, encoding: .utf8) ?? "nil", ";"
            )
            
            guard self.successfulResponseStatusCodes.contains(.init(intValue: receivedResponse.statusCode)) else {
                self.activeTasks[taskAbsoluteString] = nil
                completion?(nil, receivedResponse, NetworkError.responseErrorStatusCode(receivedResponse.statusCode))
                
                return
            }
        
            if let okString = String(data: receivedData, encoding: .utf8), okString.lowercased() == "ok" {
                self.activeTasks[taskAbsoluteString] = nil
                completion?(nil, receivedResponse, nil)
                
                return
            }
            
            do {
                let jsonDecoder = JSONDecoder()
                let object = try jsonDecoder.decode(model, from: receivedData)
                
                self.activeTasks[taskAbsoluteString] = nil
                completion?(object, receivedResponse, nil)
            } catch let parsingError {
                self.logging("[\(#function)] - parsingError:", parsingError)
                
                self.activeTasks[taskAbsoluteString] = nil
                completion?(nil, receivedResponse, parsingError)
            }
        }
        
        self.activeTasks[taskAbsoluteString] = self.urlSession?.dataTask(with: request, completionHandler: taskCompletionHandler)
        self.activeTasks[taskAbsoluteString]?.resume()
    }
    
    public func cancel(_ request: URLRequest) {
        guard
            let taskAbsoluteString: String = request.url?.absoluteString,
            self.activeTasks[taskAbsoluteString] != nil
        else { return }
        
        self.logging("[\(#function)] - canceled task with url:", request.url?.absoluteString ?? "nil")
        self.activeTasks[taskAbsoluteString]?.cancel()
    }
    
    // MARK: - Module functions
    private func logging(_ items: Any...) {
        guard self.isLoggingEnabled else { return }
        
        var printItems = items
        printItems.insert("[RequestWorker] -", at: 0)
        
        print(printItems)
    }
}
