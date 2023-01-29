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

    override func viewDidLoad() {
        super.viewDidLoad()
        
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

//struct Post {
//    let userId: Int
//    let id: Int
//    let title: String
//    let body: String
//}
//
//struct PostResponse: Decodable {
//    let userId: Int?
//    let id: Int?
//    let title: String?
//    let body: String?
//}
//
//struct PostRequest: DPNetworkRequestFactory {
//    
//    func produceURLRequest() throws -> URLRequest {
//        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
//            throw NSError(domain: "URLRequest Error", code: 0)
//        }
//        
//        return URLRequest(url: url)
//    }
//    
//}
//
//struct PostMapper: DPNetworkMapperFactory {
//    
//    func mapResponseToModel(_ response: PostResponse) throws -> Post {
//        guard let userId = response.userId, let id = response.id else {
//            throw NSError(domain: "Response Error", code: 0)
//        }
//        
//        return .init(userId: userId, id: id, title: response.title ?? "", body: response.body ?? "")
//    }
//    
//}
//
//final class PostService: DPNetworkService {
//    
//    
//    
//}
