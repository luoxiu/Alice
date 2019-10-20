import Foundation
import HTTP

var url = HTTPURL("https://baidu.com")

let task = URLSession.shared.dataTask(with: url.toValidURL().success!) { (data, response, error) in
    
    print(error)
}

task.resume()

RunLoop.current.run()
