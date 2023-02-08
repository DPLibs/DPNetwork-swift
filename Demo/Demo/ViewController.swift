//
//  ViewController.swift
//  Demo
//
//  Created by Дмитрий Поляков on 15.12.2022.
//

import UIKit
import DPNetwork

class ViewController: UIViewController {
    
//    private lazy var postService = PostService()
    
    private let service: PostServiceInterface = PostService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .green
        
        self.service.load { result in
            
        }
        
//        self.postService.load(PostRequest(), completion: { result in
//            switch result {
//            case let .failure(error):
//                print("!!! failure")
//            case let .success(post):
//                print("!!! success")
//            }
//        })
    }

}

struct Post {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct PostResponse: Decodable {
    let userId: Int?
    let id: Int?
    let title: String?
    let body: String?
}

struct PostRequest: DPNURLRequestFactory {
    
    func produce() throws -> URLRequest {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            throw DPNError.failtureURLRequest
        }
        
        return URLRequest(url: url)
    }
    
}

struct PostMapper: DPNMapperFactory {
    
    func map(_ input: PostResponse) throws -> Post {
        guard let userId = input.userId, let id = input.id else {
            throw DPNError.failtureMap
        }
        
        return .init(userId: userId, id: id, title: input.title ?? "", body: input.body ?? "")
    }
    
}

protocol PostServiceInterface {
    func load(completion: @escaping (DPNResult<[Post]>) -> Void)
}

final class PostService: DPNService, PostServiceInterface {
    
    func load(completion: @escaping (DPNResult<[Post]>) -> Void) {
        self.load(request: PostRequest(), mapper: PostMapper().mappingArray(), completion: completion)
    }
    
}
