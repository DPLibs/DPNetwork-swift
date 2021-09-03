import Foundation

public extension String {
    
    func addingPercentEncoding() -> String? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@!$&'()*+,;=")

        return self.addingPercentEncoding(withAllowedCharacters: allowed)
    }
    
}
