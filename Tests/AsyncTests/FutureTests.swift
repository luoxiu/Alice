import XCTest
@testable import Async

class FutureTests: XCTestCase {

    func testPending() {
        let p = Promise<Bool, Error>()
        
        let f = p.future

        XCTAssertTrue(f.isPending)
        XCTAssertFalse(f.isCompleted)
        
        p.succeed(true)
        XCTAssertTrue(f.isCompleted)
        XCTAssertFalse(f.isPending)
        
        p.fail(TestError.e1)
        XCTAssertTrue(f.isCompleted)
        XCTAssertFalse(f.isPending)
    }
    
    func testInspect() {
        let p = Promise<Bool, Never>()
        let f = p.future
        
        XCTAssertNil(f.inspect())
        XCTAssertNil(f.inspectWithoutLock())
        
        p.succeed(true)
        XCTAssertNotNil(f.inspect())
        XCTAssertNotNil(f.inspectWithoutLock())
        
        XCTAssertEqual(f.inspect()?.success, true)
        
        let failedFuture = Future<Bool, TestError>.failure(TestError.e1)
        XCTAssertNotNil(failedFuture.inspect())
        XCTAssertTrue(failedFuture.inspect()!.failure == TestError.e1)
    }
    
    func testComplete() {
        var count = 0
        let p1 = Promise<Bool, Never>()
        
        p1.future.whenSucceed { _ in
            count += 1
        }
        p1.succeed(true)
        
        XCTAssertEqual(count, 1)
        
        let p2 = Promise<Bool, Error>()
        p2.future.whenFail { _ in
            count += 1
        }
        p2.fail(TestError.e1)
        
        XCTAssertEqual(count, 2)
    }
    
    func testObservers() {
        var count = 0
        
        let p = Promise<Bool, Never>()
        p.future.whenSucceed { _ in
            count += 1
        }
        p.future.whenSucceed { _ in
            count += 1
        }
        p.future.whenSucceed { _ in
            count += 1
        }
        
        p.succeed(true)
        
        XCTAssertEqual(count, 3)
    }
    
    static var allTests = [
        ("testPending", testPending),
        ("testInspect", testInspect),
        ("testComplete", testComplete),
        ("testObservers", testObservers)
    ]
}
