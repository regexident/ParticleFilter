import XCTest

func XCTAssertEqual<T, U>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    accuracy: U,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
)
    where T: Collection, T.Element == U, U: FloatingPoint
{
    let (values, expectedValues): (T, T)
    
    do {
        (values, expectedValues) = (try expression1(), try expression2())
    } catch let error {
        XCTFail("Error: \(error)", file: file, line: line)
        return
    }

    for (value, expectedValue) in Swift.zip(values, expectedValues) {
        if abs(value - expectedValue) > abs(accuracy) {
            let failureMessage = "XCTAssertEqualWithAccuracy failed: (\(values)) is not equal to (\(expectedValues)) +/- (\(accuracy))"
            let userMessage = message()
            let message = "\(failureMessage) - \(userMessage)"
            XCTFail(message, file: file, line: line)
            break
        }
    }
}
