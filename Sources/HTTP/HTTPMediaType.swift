import Foundation

public typealias HTTPMIMEType = HTTPMediaType
public typealias HTTPContentType = HTTPMediaType

public struct HTTPMediaType {
    
    public let type: String
    
    public let subtype: String
    
    public typealias Parameter = HTTPHeaderValue.Parameter
    public let parameters: [Parameter]
    
    public init(type: String, subtype: String, parameters: [Parameter] = []) {
        self.type = type
        self.subtype = subtype
        self.parameters = parameters
    }
    
    public init?(rawString: String) {
        let headerValue = HTTPHeaderValue(rawString: rawString)
        let types = headerValue.value.split(separator: "/", maxSplits: 2)

        guard types.count == 2 else {
            return nil
        }
        
        let whitespaces = CharacterSet.whitespaces
        let type = String(types[0]).trimmingCharacters(in: whitespaces)
        let subtype = String(types[1]).trimmingCharacters(in: whitespaces)
        
        self.init(type: type, subtype: subtype, parameters: headerValue.parameters)
    }
}

extension HTTPMediaType {
    
    public static let any = HTTPMediaType(type: "*", subtype: "*")
    public static let plainText = HTTPMediaType(type: "text", subtype: "plain", parameters: [.charsetUTF8])
    public static let html = HTTPMediaType(type: "text", subtype: "html", parameters: [.charsetUTF8])
    public static let css = HTTPMediaType(type: "text", subtype: "css", parameters: [.charsetUTF8])
    public static let urlEncodedForm = HTTPMediaType(type: "application", subtype: "x-www-form-urlencoded", parameters: [.charsetUTF8])
    public static let formData = HTTPMediaType(type: "multipart", subtype: "form-data")
    public static let multipart = HTTPMediaType(type: "multipart", subtype: "mixed")
    public static let json = HTTPMediaType(type: "application", subtype: "json", parameters: [.charsetUTF8])
    public static let xml = HTTPMediaType(type: "application", subtype: "xml", parameters: [.charsetUTF8])
    public static let dtd = HTTPMediaType(type: "application", subtype: "xml-dtd", parameters: [.charsetUTF8])
    public static let pdf = HTTPMediaType(type: "application", subtype: "pdf")
    public static let zip = HTTPMediaType(type: "application", subtype: "zip")
    public static let tar = HTTPMediaType(type: "application", subtype: "x-tar")
    public static let gzip = HTTPMediaType(type: "application", subtype: "x-gzip")
    public static let bzip2 = HTTPMediaType(type: "application", subtype: "x-bzip2")
    public static let binary = HTTPMediaType(type: "application", subtype: "octet-stream")
    public static let gif = HTTPMediaType(type: "image", subtype: "gif")
    public static let jpeg = HTTPMediaType(type: "image", subtype: "jpeg")
    public static let png = HTTPMediaType(type: "image", subtype: "png")
    public static let svg = HTTPMediaType(type: "image", subtype: "svg+xml")
    public static let audio = HTTPMediaType(type: "audio", subtype: "basic")
    public static let midi = HTTPMediaType(type: "audio", subtype: "x-midi")
    public static let mp3 = HTTPMediaType(type: "audio", subtype: "mpeg")
    public static let wave = HTTPMediaType(type: "audio", subtype: "wav")
    public static let ogg = HTTPMediaType(type: "audio", subtype: "vorbis")
    public static let avi = HTTPMediaType(type: "video", subtype: "avi")
    public static let mpeg = HTTPMediaType(type: "video", subtype: "mpeg")
}
