import XCTest

protocol NearEquatable {
    associatedtype Difference: Comparable
    
    func isNearEqual(to other: Self, accuracy: Difference) -> Bool
}

func XCTAssertNearEqual<T>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    accuracy: T.Difference,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
)
    where T: NearEquatable, T.Difference: FloatingPoint
{
    let (value, expectedValue): (T, T)
    
    do {
        (value, expectedValue) = (try expression1(), try expression2())
    } catch let error {
        XCTFail("Error: \(error)", file: file, line: line)
        return
    }
    
    if !value.isNearEqual(to: expectedValue, accuracy: accuracy) {
        let failureMessage = "XCTAssertEqualWithAccuracy failed: (\(value)) is not equal to (\(expectedValue)) +/- (\(accuracy))"
        let userMessage = message()
        let message = "\(failureMessage) - \(userMessage)"
        XCTFail(message, file: file, line: line)
    }
}

func XCTAssertNearEqual<T, U>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    accuracy: U.Difference,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
)
    where T: Collection, T.Element == U, U: NearEquatable, U.Difference: FloatingPoint
{
    let (values, expectedValues): (T, T)

    do {
        (values, expectedValues) = (try expression1(), try expression2())
    } catch let error {
        XCTFail("Error: \(error)", file: file, line: line)
        return
    }

    for (value, expectedValue) in Swift.zip(values, expectedValues) {
        if !value.isNearEqual(to: expectedValue, accuracy: accuracy) {
            let failureMessage = "XCTAssertEqualWithAccuracy failed: (\(values)) is not equal to (\(expectedValues)) +/- (\(accuracy))"
            let userMessage = message()
            let message = "\(failureMessage) - \(userMessage)"
            XCTFail(message, file: file, line: line)
            break
        }
    }
}
