//
//  DPNetworkService.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import Foundation
import DPLogger

open class DPNetworkService: DPLoggable {
    public var isDPLoggingEnabled: Bool = true
    
    
    // MARK: - Init
    init() {
        self.session = .shared
    }
    
    // MARK: - Props
    open var session: URLSession
    open var dataTask: URLSessionDataTask?
//    open var handler: Handler?
//    open var mapper: Mapper?
    
    // MARK: - Methods
    open func load(_ request: DPNetworkRequestFactory, completion: (() -> Void)?) {
        do {
            let urlRequest = try request.produceURLRequest()
            
            let completionHandler: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
                guard let self = self else { return }
                
                self.log(urlRequest: urlRequest, urlReponse: response, data: data, error: error)
                
                if let error = error {
//                    completion?(.failure(error))
                } else {
//                    if let response = response as? HTTPURLResponse {
//
//                    }
                    
//                    self.handler?.prepareURLResponse(data: data, mapper: self.mapper)
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
//            completion?(.failure(error))
        }
    }
    
}
