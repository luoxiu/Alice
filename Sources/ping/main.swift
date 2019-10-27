import Foundation
import HTTP

HTTPClient.shared.get("https://reqres.in/api/users?page=2")
    .response
    .whenComplete {
        switch $0 {
        case .success(let r):
            print(r.json ?? "no body")
        case .failure(let e):
            print(e)
        }
    }

RunLoop.current.run()
