//
//  DPNetworkService.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import Foundation

open class DPNetworkService<Mapper: DPNetworkMapperFactory> {
    
    // MARK: - Init
    init() {
        self.session = .shared
    }
    
    // MARK: - Props
    public typealias ModelResult = Result<Mapper.Model?, Error>
    public typealias ModelResultClosure = (ModelResult) -> Void
    
    open var session: URLSession
    open var dataTask: URLSessionDataTask?
    open var mapper: Mapper?
    open var completion: ModelResultClosure?
    
    // MARK: - Methods
    open func load(_ request: DPNetworkRequestFactory) {
        do {
            let urlRequest = try request.generateURLRequest()
            
            let completionHandler: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.completion?(.failure(error))
                } else {
                    if let response = response as? HTTPURLResponse {
                        
                    }
                }
                
//                guard let response = response as? HTTPURLResponse, error == nil else {
//                    let networkError: DPNetworkError = .error(error) ?? .unknown
//                    self.logging("[\(#function)] - error:", networkError)
//                    completion?(nil, nil, networkError)
//
//                    return
//                }
//
//                guard self.successfulResponseStatusCodes.contains(.init(intValue: response.statusCode)) else {
//                    let networkError: DPNetworkError = .responseErrorStatusCode(response.statusCode)
//                    self.logging("[\(#function)] - error:", networkError)
//                    completion?(nil, nil, networkError)
//
//                    return
//                }
//
//                completion?(data, response, nil)
            }

            self.dataTask?.cancel()
            self.dataTask = self.session.dataTask(with: urlRequest, completionHandler: completionHandler)
            self.dataTask?.resume()
        } catch {
            self.completion?(.failure(error))
        }
    }
    
}
