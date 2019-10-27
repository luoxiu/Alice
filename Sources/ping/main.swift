import Foundation
import HTTP

let client = HTTPClient()

client.use { (req, next) in
    let tag = Date()
    return try next.respond(to: req).with {
        $0.headers.set("\(Date().timeIntervalSince(tag))", for: "Time-Spent")
    }
}

let authMiddleware = HTTPAnyMiddleware { (req, next) in
    let newReq = req.mHeaders {
        $0.set("bearer a1b2c3", for: .authorization)
    }
    return try next.respond(to: newReq)
}
client.use(authMiddleware, when: .path("users"))

client.get("https://reqres.in/api/users/2")
    .response
    .whenComplete {
        switch $0 {
        case .success(let r):
            print(r.request.headers.value(for: .authorization) as Any)  // a1b2c3
            print(r.headers.value(for: "Time-Spent") as Any)            // 0.02
            print(r.statusCode, r.statusMessage)                        // 200 OK
            print(r.json as Any)                                        // ["data": ["id": 2, "email": "q@reqres.in"]]
            print(r.string as Any)                                      // "{\"data\":{\"id\":2,\"email\":\"janet.weaver@reqres.in\"}}"
        case .failure(let e):
            print(e)
        }
    }

RunLoop.current.run()
