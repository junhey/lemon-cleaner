import XCTest
@testable import Airy

final class ByteFormatterTests: XCTestCase {
    func testFormatBytes() {
        XCTAssertEqual(ByteFormatter.format(Int64(0)), "0 B")
        XCTAssertEqual(ByteFormatter.format(Int64(1024)), "1.00 KB")
        XCTAssertEqual(ByteFormatter.format(Int64(1024 * 1024 * 50)), "50.0 MB")
    }

    func testFormatSpeed() {
        XCTAssertTrue(ByteFormatter.formatSpeed(512).contains("B/s"))
        XCTAssertTrue(ByteFormatter.formatSpeed(2048).contains("KB/s"))
    }

    func testFormatPercent() {
        XCTAssertEqual(ByteFormatter.formatPercent(74.6), "75%")
    }

    func testFormatCompactSpeed() {
        XCTAssertEqual(ByteFormatter.formatCompactSpeed(512), "512")
        XCTAssertEqual(ByteFormatter.formatCompactSpeed(10_240), "10K")
        XCTAssertEqual(ByteFormatter.formatCompactSpeed(35_840), "35K")
    }
}

final class ScanResultTests: XCTestCase {
    func testTotalBytes() {
        let items = [
            ScanItem(id: "1", path: "/a", name: "a", sizeBytes: 100, category: "test"),
            ScanItem(id: "2", path: "/b", name: "b", sizeBytes: 200, category: "test"),
        ]
        let category = ScanCategory(id: "test", name: "Test", items: items)
        let result = ScanResult(categories: [category], scannedAt: Date())
        XCTAssertEqual(result.totalBytes, 300)
    }
}

final class SimilarPhotoHashTests: XCTestCase {
    func testHammingDistance() {
        XCTAssertEqual((UInt64(0) ^ UInt64(0)).nonzeroBitCount, 0)
        XCTAssertEqual((UInt64(0b1111) ^ UInt64(0b1010)).nonzeroBitCount, 2)
    }
}
