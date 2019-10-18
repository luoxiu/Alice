public enum HTTPResponseStatus: RawRepresentable {
    
    case `continue`
    case switchingProtocols
    case processing
    case earlyHints
    case ok
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case imUsed
    case multipleChoices
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case switchProxy
    case temporaryRedirect
    case permanentRedirect
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case payloadTooLarge
    case uriTooLong
    case unsupportedMediaType
    case rangeNotSatisfiable
    case expectationFailed
    case misdirectedRequest
    case unprocessableEntity
    case locked
    case failedDependency
    case tooEarly
    case upgradeRequired
    case preconditionRequired
    case tooManyRequests
    case requestHeaderFieldsTooLarge
    case unavailableForLegalReasons
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended
    
    case custom(Int)
    
    public var rawValue: Int {
        return self.code
    }
    
    public init(rawValue: Int) {
        self.init(code: rawValue)
    }
    
    public var code: Int {
        switch self {
        case .continue:                     return 100
        case .switchingProtocols:           return 101
        case .processing:                   return 102
        case .earlyHints:                   return 103
        case .ok:                           return 200
        case .created:                      return 201
        case .accepted:                     return 202
        case .nonAuthoritativeInformation:  return 203
        case .noContent:                    return 204
        case .resetContent:                 return 205
        case .partialContent:               return 206
        case .multiStatus:                  return 207
        case .alreadyReported:              return 208
        case .imUsed:                       return 226
        case .multipleChoices:              return 300
        case .movedPermanently:             return 301
        case .found:                        return 302
        case .seeOther:                     return 303
        case .notModified:                  return 304
        case .useProxy:                     return 305
        case .switchProxy:                  return 306
        case .temporaryRedirect:            return 307
        case .permanentRedirect:            return 308
        case .badRequest:                   return 400
        case .unauthorized:                 return 401
        case .paymentRequired:              return 402
        case .forbidden:                    return 403
        case .notFound:                     return 404
        case .methodNotAllowed:             return 405
        case .notAcceptable:                return 406
        case .proxyAuthenticationRequired:  return 407
        case .requestTimeout:               return 408
        case .conflict:                     return 409
        case .gone:                         return 410
        case .lengthRequired:               return 411
        case .preconditionFailed:           return 412
        case .payloadTooLarge:              return 413
        case .uriTooLong:                   return 414
        case .unsupportedMediaType:         return 415
        case .rangeNotSatisfiable:          return 416
        case .expectationFailed:            return 417
        case .misdirectedRequest:            return 421
        case .unprocessableEntity:          return 422
        case .locked:                       return 423
        case .failedDependency:             return 424
        case .tooEarly:                     return 425
        case .upgradeRequired:              return 426
        case .preconditionRequired:         return 428
        case .tooManyRequests:              return 429
        case .requestHeaderFieldsTooLarge:  return 431
        case .unavailableForLegalReasons:   return 451
        case .internalServerError:          return 500
        case .notImplemented:               return 501
        case .badGateway:                   return 502
        case .serviceUnavailable:           return 503
        case .gatewayTimeout:               return 504
        case .httpVersionNotSupported:      return 505
        case .variantAlsoNegotiates:        return 506
        case .insufficientStorage:          return 507
        case .loopDetected:                 return 508
        case .notExtended:                  return 510
        case .custom(let code):             return code
        }
    }
    
    public init(code: Int) {
        switch code {
        case 100:   self = .continue
        case 101:   self = .switchingProtocols
        case 102:   self = .processing
        case 103:   self = .earlyHints
        case 200:   self = .ok
        case 201:   self = .created
        case 202:   self = .accepted
        case 203:   self = .nonAuthoritativeInformation
        case 204:   self = .noContent
        case 205:   self = .resetContent
        case 206:   self = .partialContent
        case 207:   self = .multiStatus
        case 208:   self = .alreadyReported
        case 226:   self = .imUsed
        case 300:   self = .multipleChoices
        case 301:   self = .movedPermanently
        case 302:   self = .found
        case 303:   self = .seeOther
        case 304:   self = .notModified
        case 305:   self = .useProxy
        case 306:   self = .switchProxy
        case 307:   self = .temporaryRedirect
        case 308:   self = .permanentRedirect
        case 400:   self = .badRequest
        case 401:   self = .unauthorized
        case 402:   self = .paymentRequired
        case 403:   self = .forbidden
        case 404:   self = .notFound
        case 405:   self = .methodNotAllowed
        case 406:   self = .notAcceptable
        case 407:   self = .proxyAuthenticationRequired
        case 408:   self = .requestTimeout
        case 409:   self = .conflict
        case 410:   self = .gone
        case 411:   self = .lengthRequired
        case 412:   self = .preconditionFailed
        case 413:   self = .payloadTooLarge
        case 414:   self = .uriTooLong
        case 415:   self = .unsupportedMediaType
        case 416:   self = .rangeNotSatisfiable
        case 417:   self = .expectationFailed
        case 421:   self = .misdirectedRequest
        case 422:   self = .unprocessableEntity
        case 423:   self = .locked
        case 424:   self = .failedDependency
        case 425:   self = .tooEarly
        case 426:   self = .upgradeRequired
        case 428:   self = .preconditionRequired
        case 429:   self = .tooManyRequests
        case 431:   self = .requestHeaderFieldsTooLarge
        case 451:   self = .unavailableForLegalReasons
        case 500:   self = .internalServerError
        case 501:   self = .notImplemented
        case 502:   self = .badGateway
        case 503:   self = .serviceUnavailable
        case 504:   self = .gatewayTimeout
        case 505:   self = .httpVersionNotSupported
        case 506:   self = .variantAlsoNegotiates
        case 507:   self = .insufficientStorage
        case 508:   self = .loopDetected
        case 510:   self = .notExtended
        default:    self = .custom(code)
        }
    }
}

extension HTTPResponseStatus: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: Int) {
        self.init(code: value)
    }
}

extension HTTPResponseStatus: CustomStringConvertible {

    public var message: String {
        switch self {
        case .continue:                     return "Continue"
        case .switchingProtocols:           return "Switching Protocols"
        case .processing:                   return "Processing"
        case .earlyHints:                   return "Early Hints"
        case .ok:                           return "OK"
        case .created:                      return "Created"
        case .accepted:                     return "Accepted"
        case .nonAuthoritativeInformation:  return "Non-Authoritative Information"
        case .noContent:                    return "No Content"
        case .resetContent:                 return "Reset Content"
        case .partialContent:               return "Partial Content"
        case .multiStatus:                  return "Multi-Status"
        case .alreadyReported:              return "Already Reported"
        case .imUsed:                       return "IM Used"
        case .multipleChoices:              return "Multiple Choices"
        case .movedPermanently:             return "Moved Permanently"
        case .found:                        return "Found"
        case .seeOther:               	    return "See Other"
        case .notModified:                  return "Not Modified"
        case .useProxy:                     return "Use Proxy"
        case .switchProxy:                  return "Switch Proxy"
        case .temporaryRedirect:            return "Temporary Redirect"
        case .permanentRedirect:            return "Permanent Redirect"
        case .badRequest:                   return "Bad Request"
        case .unauthorized:                 return "Unauthorized"
        case .paymentRequired:              return "Payment Required"
        case .forbidden:                    return "Forbidden"
        case .notFound:                     return "Not Found"
        case .methodNotAllowed:             return "Method Not Allowed"
        case .notAcceptable:                return "Not Acceptable"
        case .proxyAuthenticationRequired:  return "Proxy Authentication Required"
        case .requestTimeout:               return "Request Timeout"
        case .conflict:                     return "Conflict"
        case .gone:                         return "Gone"
        case .lengthRequired:               return "Length Required"
        case .preconditionFailed:           return "Precondition Failed"
        case .payloadTooLarge:              return "Payload Too Large"
        case .uriTooLong:                   return "URI Too Long"
        case .unsupportedMediaType:         return "Unsupported Media Type"
        case .rangeNotSatisfiable:          return "Range Not Satisfiable"
        case .expectationFailed:            return "Expectation Failed"
        case .misdirectedRequest:           return "Misdirected Request"
        case .unprocessableEntity:          return "Unprocessable Entity"
        case .locked:                       return "Locked"
        case .failedDependency:             return "Failed Dependency"
        case .tooEarly:                     return "Too Early"
        case .upgradeRequired:              return "Upgrade Required"
        case .preconditionRequired:         return "Precondition Required"
        case .tooManyRequests:              return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:  return "Request Header Fields Too Large"
        case .unavailableForLegalReasons:   return "Unavailable For Legal Reasons"
        case .internalServerError:          return "Internal Server Error"
        case .notImplemented:               return "Not Implemented"
        case .badGateway:                   return "Bad Gateway"
        case .serviceUnavailable:           return "Service Unavailable"
        case .gatewayTimeout:               return "Gateway Timeout"
        case .httpVersionNotSupported:      return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:        return "Variant Also Negotiates"
        case .insufficientStorage:          return "Insufficient Storage"
        case .loopDetected:                 return "Loop Detected"
        case .notExtended:                  return "Not Extended"
        case .custom(let code):             return "HTTPResponse.Status: \(code)"
        }
    }
    
    public var description: String {
        return message
    }
}
