import Foundation

// TODO: This is an immature solution...

struct HTTPURLMatchRule {
 
    enum PathComponentRule {
        case plain(String)
        case placeholder
    }
    
    private let rules: [PathComponentRule]
    
    init(_ string: String) {
        var str = string
        if !str.characterSet.isSubset(of: .urlPathAllowed), let encoded = str.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            str = encoded
        }
        
        var rules: [PathComponentRule] = []
        
        for comp in str.ns.pathComponents {
            if comp.starts(with: ":") {
                rules.append(.placeholder)
            } else {
                rules.append(.plain(comp))
            }
        }
        self.rules = rules
    }
    

    func test(_ url: HTTPURL) -> Bool {
        let comps = url.pathComponents
        
        guard comps.count >= self.rules.count else {
            return false
        }
        
        for (rule, comp) in zip(self.rules, comps) {
            switch rule {
            case .plain(let str):
                if str != comp {
                    return false
                }
            case .placeholder:
                break
            }
        }
        
        return true
    }
}
