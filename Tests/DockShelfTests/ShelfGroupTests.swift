import XCTest
@testable import DockShelf

final class ShelfGroupTests: XCTestCase {
    func testFitWidthUsesAppCountAndUpdatesSlots() {
        let apps = [
            ShelfApp(name: "Calendar", path: "/Applications/Calendar.app"),
            ShelfApp(name: "Notes", path: "/Applications/Notes.app")
        ]
        var group = ShelfGroup(
            title: "Utilities",
            xPosition: 0,
            imagePath: nil,
            showsImage: false,
            iconSlots: 1,
            apps: apps
        )

        group.fitWidthToApps()

        XCTAssertEqual(group.iconSlots, 2)
        XCTAssertEqual(group.width, 121)
    }

    func testLegacyGroupDataUsesCurrentDefaults() throws {
        let data = Data("""
        {
          "title": "Utilities",
          "xPosition": 12
        }
        """.utf8)

        let group = try JSONDecoder().decode(ShelfGroup.self, from: data)

        XCTAssertEqual(group.title, "Utilities")
        XCTAssertEqual(group.width, 180)
        XCTAssertEqual(group.opacity, 0.34)
        XCTAssertEqual(group.iconSlots, 3)
        XCTAssertTrue(group.apps.isEmpty)
    }
}
