# Alice

[![travis](https://img.shields.io/travis/luoxiu/Alice.svg)](https://travis-ci.org/luoxiu/Alice)

Next generation of HTTP client for Swift.

> Still under development...

## Modules

In the current plan, Alice consists of the following four parts:

- Async: A high performance future & promise library.
- HTTP: An extensible HTTP client library.
- JSON: An easy to use JSON model library.
- Layer: A type-safe HTTP abstraction layer library.

These libraries will be split into their own repositories in the official release in the future. Each library can be used separately in your app.

## Usage

### HTTP(ing)

```swift
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
```

### Async

```swift
func request(_ url: URL) -> Future<HTTPResponse, HTTPError> {
    let p = Promise<HTTPResponse, HTTPError>()
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        if let e = error {
            p.fail(HTTPError.session(e))
            return
        }
        p.succeed(HTTPResponse(response, data))
    }
    return p.future
}

request(imageURL)
    .validate {
        $0.isValid()
    }
    .yield(on: workQ)
    .tryMap {
        try ImageDecoder().decode($0.data)
    }
    .main {
        self.imageView = $0
    }
    .background {
        cache.add($0, for: img)
    }
    .catch {
        Log.error($0)
    }
```

## 更新

- [Alice 5: 给 Future 加点糖](https://v2ambition.com/posts/alice-5-add-some-sugar-to-future/)
- [Alice 4: Future 的操作符](https://v2ambition.com/posts/alice-4-future-operators/)
- [Alice 3: 测试](https://v2ambition.com/posts/alice-3-test/)
- [Alice 2: Future and promise](https://v2ambition.com/posts/alice-2-future-and-promise/)
- [Alice 2: Future and promise](https://v2ambition.com/posts/alice-2-future-and-promise/)
- [Alice 1: 初始化一个 Swift 框架](https://v2ambition.com/posts/alice-1-init-a-swift-package/)
- [Alice 0: 下一代 HTTP 客户端](https://v2ambition.com/posts/alice-0-next-generation-of-http-client/)
- [Alice Pre: 起源](https://v2ambition.com/posts/alice-pre/)

## 更多

Alice 还在开发中，我将用[连载的方式](https://v2ambition.com/tags/alice-serial/)记录她的开发过程——

内容会有技术方面的：

- futures & promise 的实现
- 多线程和网络的应用
- 性能的取舍
- 怎么写测试
- 我理想的网络抽象层
- 我对接口设计的思考
- ……

也会有项目相关的：

- 创建与发布一个 Swift 框架
- 依赖管理
- CI 的工作
- 我怎么看代码风格
- ……

<b><big>欢迎关注！😉</big></b>

✨✨✨

<b><big>注意，</big>这不是教程，而是记录，</b>记录当天所做，分享当天所学。

我非常期待交流，你可以通过评论或 [issue](https://github.com/luoxiu/alice/issues) 反馈，发表你的评论和想法，让 Alice 能集百家之长，成一家之言。我期望 Alice 能在交流中的写就，在反馈中完成。

如果你是一个经验丰富的大佬，欢迎指教！这是一个尝试，过程中一定会遇到很多问题，我非常需要你的帮助！

如果是你一个开源世界的新手，那么来吧！和我一起学习，这是一个开始参与开源的绝好机会。我们可以一起成长为——巨人！
