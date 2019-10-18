import Foundation

public enum HTTPError: Error {
    
    public enum URLErrorReason {
        case missingScheme
        case invalidScheme(String)
        case missingHost
        case invalidPort(Int)
        
        case malformedComponents(URLComponents)
    }
    
    case url(URLErrorReason)
    
    public enum RequestErrorReason {
        case missingURL
        case invalidResumeData(Data)
        
        case missingUploadBody
    }
    
    case request(RequestErrorReason)
    
    
    case jsonSerialization(Data, Error)
    
    case session(Error)
    
    case teacup(String)
}
