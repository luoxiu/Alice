import Foundation

extension String {
    
    var characterSet: CharacterSet {
        return CharacterSet(charactersIn: self)
    }
    
    var ns: NSString {
        return self as NSString
    }
}

extension String {
    
    func toHTTPScheme() -> HTTPScheme? {
        return HTTPScheme(rawValue: self)
    }
    
    var isValidHTTPScheme: Bool {
        return HTTPScheme(rawValue: self) != nil
    }
}
