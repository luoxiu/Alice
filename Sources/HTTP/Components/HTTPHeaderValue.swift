import Foundation

public struct HTTPHeaderValue {
        
    public let value: String
    
    public struct Parameter {
        let attribute: String
        let value: String?
    }
    public let parameters: [Parameter]
    
    public init(value: String, parameters: [Parameter]) {
        self.value = value
        self.parameters = parameters
    }
    
    public init(rawString: String) {
        if let value = HTTPHeaderValue.parse(rawString) {
            self = value
        } else {
            self.value = rawString
            self.parameters = []
        }
    }
    
    public func toString() -> String {
        
        func serialize(_ parameter: Parameter) -> String {
            if let value = parameter.value {
                return parameter.attribute + "=" + value
            } else {
                return parameter.attribute
            }
        }
        
        var str = value
        for parameter in parameters {
            str += "; \(serialize(parameter))"
        }
        return str
    }
    
    // Copied from swift foundation.
    private static func parse(_ string: String) -> HTTPHeaderValue? {
        var type: String?
        var parameters: [Parameter] = []
        let whitespaces = CharacterSet.whitespaces
        
        func append(_ str: String) {
            if type == nil {
                type = str
            } else {
                if let r = str.range(of: "=") {
                    let name = String(str[str.startIndex..<r.lowerBound]).trimmingCharacters(in: whitespaces)
                    let value = String(str[r.upperBound..<str.endIndex]).trimmingCharacters(in: whitespaces)
                    parameters.append(Parameter(attribute: name, value: value))
                } else {
                    let name = str.trimmingCharacters(in: whitespaces)
                    parameters.append(Parameter(attribute: name, value: nil))
                }
            }
        }
        
        let backSlash = UnicodeScalar(0x5c)!    //  \
        let quote = UnicodeScalar(0x22)!        //  "
        let semicolon = UnicodeScalar(0x3b)!    //  ;
        
        enum State {
            case nonQuoted(String)
            case nonQuotedEscaped(String)
            case quoted(String)
            case quotedEscaped(String)
        }
        
        var state = State.nonQuoted("")
        for next in string.unicodeScalars {
            switch (state, next) {
            case (.nonQuoted(let s), semicolon):
                append(s)
                state = .nonQuoted("")
            case (.nonQuoted(let s), backSlash):
                state = .nonQuotedEscaped(s + String(next))
            case (.nonQuoted(let s), quote):
                state = .quoted(s)
            case (.nonQuoted(let s), _):
                state = .nonQuoted(s + String(next))
            case (.nonQuotedEscaped(let s), _):
                state = .nonQuoted(s + String(next))
            case (.quoted(let s), quote):
                state = .nonQuoted(s)
            case (.quoted(let s), backSlash):
                state = .quotedEscaped(s + String(next))
            case (.quoted(let s), _):
                state = .quoted(s + String(next))
            case (.quotedEscaped(let s), _):
                state = .quoted(s + String(next))
            }
        }

        switch state {
        case .nonQuoted(let s):         	append(s)
        case .nonQuotedEscaped(let s):  	append(s)
        case .quoted(let s):                append(s)
        case .quotedEscaped(let s):         append(s)
        }

        guard let t = type else { return nil }
        return HTTPHeaderValue(value: t, parameters: parameters)
    }
}

extension HTTPHeaderValue: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self = HTTPHeaderValue(rawString: value)
    }
}

extension HTTPHeaderValue.Parameter {
    
    public static let charsetUTF8 = HTTPHeaderValue.Parameter(attribute: "charset", value: "utf-8")
}
