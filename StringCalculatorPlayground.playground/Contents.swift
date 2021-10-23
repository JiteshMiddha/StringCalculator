
/**
 1. Create a simple String calculator with a method: int Add(string numbers)
    a. The numbers in the string are separated by a comma.
    b. Empty strings should return 0.
    c. The return type should be an integer.
    d. Example input: “1,2,5” - expected result: “8”.
    e. Write tests to prove your input validates.
 
 2. Change the Add method to handle new lines in the input format
  a. Example: “1\n,2,3” - Result: “6”
  b. Example 2: “1,\n2,4” - Result: “7”
 
 3. Support a custom delimiter
  a. The beginning of your string will now contain a small control code that lets you set a custom delimiter.
  b. Format: “//[delimiter]\n[delimiter separated numbers]”
  c. Example: “//;\n1;3;4” - Result: 8
  d. In the above you can see that following the double forward slash we set a semicolon, followed by a new line. We then use that delimiter to split our numbers.
  e. Other examples
      i. “//$\n1$2$3” - Result: 6
      ii. “//@\n2@3@8” - Result: 13
 
 4. Calling add with a negative number should throw an exception: “Negatives not allowed”. The exception should list the number(s) that caused the exception
 */

import Foundation
import XCTest

enum StringCalculatorErrors: Error, Equatable {
  // Creating custom error with associated value
  case NoNegativeError(negativeNumbers: [Int])
  
  var localizedDescription: String {
    switch self {
    case .NoNegativeError(let negativeNumbers):
      return "Negatives are not allowed. The input contained these negative numbers: \(negativeNumbers.description)"
    }
  }
}

extension String {
  // Divide string to array of components separated by multiple separators
  public func components(separatedBy separators: [String]) -> [String] {
    var output: [String] = [self]
    for separator in separators {
      output = output.flatMap { $0.components(separatedBy: separator) }
    }
    return output.map { $0.trimmingCharacters(in: .whitespaces)}
  }
}

class StringCalculator: NSObject {
  
  let MAX_NUMBER = 1000

  func add(numbers: String?) throws -> Int {
    guard let numbers = numbers else {
      return 0  // return 0 if nil
    }

    if numbers.count == 0 {
      return 0  // return if empty string
    }
    
    // default delimiter = "," - comma
    var delimiters: [String] = [","]
    
    // getting string without // in the beginning
    let splitDelimiter = numbers.components(separatedBy: "//")
//    print("splitDelimiter" + splitDelimiter.description)
    
    if splitDelimiter.count > 1 {
      // If the string contains delimiter, splitDelimiter will contain the rest of the string without delimiter at index 1
      let delimiterString = splitDelimiter[1].components(separatedBy: "\n")[0]  // 0 index will contain the list of delimiters before "\n"
      
      // considering the list of delimiters will always be comma separated
      delimiters = delimiterString.components(separatedBy: ",")
    }
    
//    print("delimiters list: " + delimiters.description)

    let numInts = numbers
      .components(separatedBy: delimiters)  // separating by delimiters
      .compactMap{
        Int($0.filter{!$0.isWhitespace})
      }
    
    // creating list of negative numbers to return with error
    let negatives = numInts.filter {
      $0 < 0
    }
    
    if negatives.count > 0 {
      // throws error if there are any negative numbers
      throw StringCalculatorErrors.NoNegativeError(negativeNumbers: negatives)
    }
    
    // filter out numbers above 1000 (MAX_NUMBER)
    return numInts.reduce(0) { $0 + ($1 <= MAX_NUMBER ? $1: 0)}
  }
}


//Usage Example
do {
  let str = "1,-2,-5"
  try StringCalculator().add(numbers: str)
} catch {
  let err = error as! StringCalculatorErrors
  print(err.localizedDescription)
}


// Tests
struct TestCase<T: Any> {
  let input: String?
  let output: T?
}

let perfectCase = TestCase<Int>(input: "1,2,5", output: 8)
let doubleComma = TestCase(input: "1,,2,3", output: 6)
let emptyInput = TestCase(input: "", output: 0)
let nilInput = TestCase(input: nil, output: 0)
let stringWithNonNumber = TestCase(input: "1,k,10", output: 11)
let stringWithTrailingSpace = TestCase(input: "1,k,10 ", output: 11)
let newLineInInput1 = TestCase(input: "1\n,2,3", output: 6)
let newLineInInput2 = TestCase(input: "1,\n2,4", output: 7)
let delimeterCase1 = TestCase(input: "//;\n1;3;4", output: 8)
let delimeterCase2 = TestCase(input: "//$\n1$2$3", output: 6)
let delimeterCase3 = TestCase(input: "//@\n2@3@8", output: 13)
let doubleDelimeter = TestCase(input: "//;\n1;;3;4", output: 8)
let delimeterOnlyWithoutNumbers = TestCase(input: "//;\n", output: 0)
let delimeterWithNonNumbers = TestCase(input: "//;\n1;k;4", output: 5)
let delimeterWithNewLineInNumbers = TestCase(input: "//;\n1;\n2;4", output: 7)

// Order of negative numbers in output needs to be same with the input
let testNegatives = TestCase<[Int]>(input: "1,-2,-5", output: [-2, -5])
let negativesDoubleComma = TestCase(input: "1,,-2,3", output: [-2])
let negativesWithNonNumber = TestCase(input: "1,-k,-10", output: [-10])

// Bonus Cases
let ignoreLargeNumbers = TestCase(input: "2,1001", output: 2)
let longerDelimiters = TestCase(input: "//***\n1***2***3", output: 6)
let multipleDelimiters = TestCase(input: "//$,@\n1$2@3", output: 6)
let multipleLongSeparators = TestCase(input: "//$$$,@@\n1$$$2@@3", output: 6)


class StringCalculatorTests: XCTestCase {
  var stringCalculator: StringCalculator!
  
  override func setUp() {
    super.setUp()
    stringCalculator = StringCalculator()
  }
  func testPerfectCase() {
    let sum = try? stringCalculator.add(numbers: perfectCase.input)
    XCTAssertEqual(sum, perfectCase.output)
  }
  
  func testDoubleComma() {
    let sum = try? stringCalculator.add(numbers: doubleComma.input)
    XCTAssertEqual(sum, doubleComma.output)
  }

  func testEmptyInput() {
    let sum = try? stringCalculator.add(numbers: emptyInput.input)
    XCTAssertEqual(sum, emptyInput.output)
  }

  func testNilInput() {
    let sum = try? stringCalculator.add(numbers: nilInput.input)
    XCTAssertEqual(sum, nilInput.output)
  }

  func testStringWithNonNumber() {
    let sum = try? stringCalculator.add(numbers: stringWithNonNumber.input)
    XCTAssertEqual(sum, stringWithNonNumber.output)
  }

  func testStringWithTrailingSpace() {
    let sum = try? stringCalculator.add(numbers: stringWithTrailingSpace.input)
    XCTAssertEqual(sum, stringWithTrailingSpace.output)
  }

  func testNewLineInInput1() {
    let sum = try? stringCalculator.add(numbers: newLineInInput1.input)
    XCTAssertEqual(sum, newLineInInput1.output)
  }

  func testNewLineInInput2() {
    let sum = try? stringCalculator.add(numbers: newLineInInput2.input)
    XCTAssertEqual(sum, newLineInInput2.output)
  }

//
  func testDelimeterCase1() {
    let sum = try? stringCalculator.add(numbers: delimeterCase1.input)
    XCTAssertEqual(sum, delimeterCase1.output)
  }

  func testDelimeterCase2() {
    let sum = try? stringCalculator.add(numbers: delimeterCase2.input)
    XCTAssertEqual(sum, delimeterCase2.output)
  }

  func testDelimeterCase3() {
    let sum = try? stringCalculator.add(numbers: delimeterCase3.input)
    XCTAssertEqual(sum, delimeterCase3.output)
  }

  func testDoubleDelimeter() {
    let sum = try? stringCalculator.add(numbers: doubleDelimeter.input)
    XCTAssertEqual(sum, doubleDelimeter.output)
  }

  func testDelimeterOnlyWithoutNumbers() {
    let sum = try? stringCalculator.add(numbers: delimeterOnlyWithoutNumbers.input)
    XCTAssertEqual(sum, delimeterOnlyWithoutNumbers.output)
  }

  func testDelimeterWithNonNumbers() {
    let sum = try? stringCalculator.add(numbers: delimeterWithNonNumbers.input)
    XCTAssertEqual(sum, delimeterWithNonNumbers.output)
  }

  func testDelimeterWithNewLineInNumbers() {
    let sum = try? stringCalculator.add(numbers: delimeterWithNewLineInNumbers.input)
    XCTAssertEqual(sum, delimeterWithNewLineInNumbers.output)
  }
  
  func testNegativesCase() {
    XCTAssertThrowsError(try stringCalculator.add(numbers: testNegatives.input)) { error in
      XCTAssertEqual(error as! StringCalculatorErrors, StringCalculatorErrors.NoNegativeError(negativeNumbers: testNegatives.output!))
    }
  }
  
  func testNegativesDoubleComma() {
    XCTAssertThrowsError(try stringCalculator.add(numbers: negativesDoubleComma.input)) { error in
      XCTAssertEqual(error as! StringCalculatorErrors, StringCalculatorErrors.NoNegativeError(negativeNumbers: negativesDoubleComma.output!))
    }
  }
  
  func testNegativesWithNonNumber() {
    XCTAssertThrowsError(try stringCalculator.add(numbers: negativesWithNonNumber.input)) { error in
      XCTAssertEqual(error as! StringCalculatorErrors, StringCalculatorErrors.NoNegativeError(negativeNumbers: negativesWithNonNumber.output!))
    }
  }
  
  // Bonus Tests
  func testIgnoreLargeNumbers() {
    let sum = try? stringCalculator.add(numbers: ignoreLargeNumbers.input)
    XCTAssertEqual(sum, ignoreLargeNumbers.output)
  }
  
  func testLongerDelimiters() {
    let sum = try? stringCalculator.add(numbers: longerDelimiters.input)
    XCTAssertEqual(sum, longerDelimiters.output)
  }
  
  func testMultipleDelimiters() {
    let sum = try? stringCalculator.add(numbers: multipleDelimiters.input)
    XCTAssertEqual(sum, multipleDelimiters.output)
  }
  
  func testMultipleLongSeparators() {
    let sum = try? stringCalculator.add(numbers: multipleLongSeparators.input)
    XCTAssertEqual(sum, multipleLongSeparators.output)
  }
  
  // Testing string components(separatedBy separators: [String]) method
  let singleComma = TestCase(input: "1,2,3", output: ["1", "2", "3"])
  let singleSemiColon = TestCase(input: "1;2;3", output: ["1", "2", "3"])
  let twoDifferentSeparators = TestCase(input: "1,2;3", output: ["1", "2", "3"])
  let longerSeparator = TestCase(input: "1**2**3", output: ["1", "2", "3"])
  
  func testSingleSeparator() {
    XCTAssertEqual(singleComma.input?.components(separatedBy: [","]), singleComma.output)
    XCTAssertEqual(singleSemiColon.input?.components(separatedBy: [";"]), singleSemiColon.output)
  }
  
  func testMultipleSeparator() {
    XCTAssertEqual(twoDifferentSeparators.input?.components(separatedBy: [",", ";"]), twoDifferentSeparators.output)
    XCTAssertEqual(longerSeparator.input?.components(separatedBy: ["**"]), longerSeparator.output)
  }
}

// Comment this line to stop running tests
StringCalculatorTests.defaultTestSuite.run()
