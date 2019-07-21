import XCTest

/// Allows comparing:
///
/// ```
/// T where
///     T: Collection,
///     T.Element == U,
///     U: FloatingPoint
/// ```
///
/// Useful for comparing:
/// - `[Float]`
/// - `[Double]`
@discardableResult
func XCTAssertEqual<T, U>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    accuracy: U,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) -> Bool
    where T: Collection, T.Element == U, U: FloatingPoint
{
    let (actualValues, expectedValues): (T, T)

    do {
        (actualValues, expectedValues) = (try expression1(), try expression2())
    } catch let error {
        XCTFail("Error: \(error)", file: file, line: line)
        return false
    }

    XCTAssertEqual(actualValues.count, expectedValues.count, file: file, line: line)

    for (actual, expected) in Swift.zip(actualValues, expectedValues) {
        guard abs(actual - expected) > abs(accuracy) else {
            continue
        }

        let failureMessage = "XCTAssertEqualWithAccuracy failed: (\(actual)) is not equal to (\(expected)) +/- (\(accuracy))"
        let userMessage = message()
        let message = "\(failureMessage) - \(userMessage)"
        XCTFail(message, file: file, line: line)

        return false
    }

    return true
}

/// Allows comparing:
///
/// ```
/// T where
///     T: Collection,
///     U: Collection,
///     T.Element == U,
///     U.Element == V,
///     V: FloatingPoint
/// ```
///
/// Useful for comparing:
/// - `[[Float]]`
/// - `[[Double]]`
/// - `Matrix<Float>`
/// - `Matrix<Double>`
@discardableResult
func XCTAssertEqual<T, U, V>(
    _ expression1: @autoclosure () throws -> T,
    _ expression2: @autoclosure () throws -> T,
    accuracy: V,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) -> Bool
    where T: Collection, U: Collection, T.Element == U, U.Element == V, V: FloatingPoint
{
    let (actualValues, expectedValues): (T, T)

    do {
        (actualValues, expectedValues) = (try expression1(), try expression2())
    } catch let error {
        XCTFail("Error: \(error)", file: file, line: line)
        return false
    }

    XCTAssertEqual(actualValues.count, expectedValues.count, file: file, line: line)

    for (actual, expected) in Swift.zip(actualValues, expectedValues) {
        guard XCTAssertEqual(actual, expected, accuracy: accuracy) else {
            return false
        }
    }
    return true
}
