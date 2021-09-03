import Foundation

open class RequestSuccess: Request {
    
    open func loadSuccess(_ completion: ((Bool, HTTPURLResponse?, Error?) -> Void)? = nil) {
        self.load(model: String.self) { _, httpURLResponse, error in
            var isSuccess: Bool {
                error == nil
            }
            
            completion?(isSuccess, httpURLResponse, error)
        }
    }
    
}
