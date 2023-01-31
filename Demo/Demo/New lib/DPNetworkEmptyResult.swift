//
//  DPNetworkEmptyResult.swift
//  Demo
//
//  Created by Дмитрий Поляков on 29.01.2023.
//

import Foundation

public enum DPNResultEmpty {
    case success
    case failure(Error)
}

typealias DPNResult<Success> = Result<Success, Error>
typealias DPNDataTaskCompletion = (data: Data?, urlResponse: URLResponse?, error: Error?)
typealias DPNSerilizeResult = DPNResult<Data>

public struct DPNError: LocalizedError, Equatable {
    
    // MARK: - Init
    public init(id: String, message: String) {
        self.id = id
        self.message = message
    }
    
    // MARK: - Props
    public let id: String
    public let message: String
    
    // MARK: - LocalizedError
    public var errorDescription: String? {
        self.message
    }
    
    public var failureReason: String? {
        self.message
    }
    
    // MARK: - Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Store
    public static let failtureMap = DPNError(id: "failtureMap", message: "Failture map")
}

public protocol DPNMapperFactory {
    associatedtype Input
    associatedtype Output
    
    func map(_ input: Input) throws -> Output
}

public protocol DPNURLRequestFactory {
    func produce() throws -> URLRequest
}

public struct DPNURLRequest: DPNURLRequestFactory {
    
    public let url: URL?
    
    public func produce() throws -> URLRequest {
        guard let url = self.url else { throw DPNError.failtureMap }
        
        return URLRequest(url: url)
    }
    
}

public protocol DPNSerilizerFactory: AnyObject {
    associatedtype Output
    
    func serilize(_ data: Data, completion: @escaping (Output) -> Void)
}

open class DPNService: NSObject {
    
    func prepare() -> DPNService {
        self
    }
    
    func load<Mapper: DPNMapperFactory>(request: DPNURLRequestFactory, mapper: Mapper, completion: @escaping (DPNResult<Mapper.Output>) -> Void) {
        
    }
    
    func load(request: DPNURLRequestFactory, completion: @escaping (DPNResultEmpty) -> Void) {
//        self.load(request: request) { [weak self] context in
//            self?.seriliaze(context, completion: { [weak self] result in
//                <#code#>
//            })
//        }
    }
    
    func load(request: DPNURLRequestFactory, completion: @escaping (DPNResult<DPNDataTaskCompletion>) -> Void) {
        do {
            let urlRequest = try request.produce()
            
            let task = URLSession.shared.dataTask(with: urlRequest) { data, urlResponse, error in
                let success = DPNDataTaskCompletion(data, urlResponse, error)
                completion(.success(success))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func seriliaze(_ content: DPNDataTaskCompletion, completion: @escaping (DPNSerilizeResult) -> Void) {
        if let error = content.error {
            completion(.failure(error))
        } else if let data = content.data {
            completion(.success(data))
        }
    }
    
}
