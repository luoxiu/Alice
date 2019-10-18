import Foundation

extension URL {
    
    var isValidHTTPURL: Bool {
        let url = try? self.validate()
        return url != nil
    }
    
    func validate() throws -> URL {
        guard let scheme = self.scheme else {
            throw HTTPError.url(.missingScheme)
        }
        
        guard scheme.isValidHTTPScheme else {
            throw HTTPError.url(.invalidScheme(scheme))
        }
        
        if self.host == nil {
            throw HTTPError.url(.missingHost)
        }
        
        return self
    }
}

