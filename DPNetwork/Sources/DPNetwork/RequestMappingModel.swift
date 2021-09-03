import Foundation

open class RequestMappingModel<Response: ResponseMappingProtocol>: Request {

    open func loadModel(_ completion: ((Response.ModelType?, HTTPURLResponse?, Error?) -> Void)? = nil) {
        self.load(model: Response.self) { result, httpURLResponse, error in
            let model = result?.mapToModel()
            
            completion?(model, httpURLResponse, error)
        }
    }
    
}
