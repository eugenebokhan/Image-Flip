import XCTest
import SwiftSnapshotTesting

class MultipeerUITests: SnapshotTestCase {

    let app = XCUIApplication()

    override var snapshotsReferencesFolder: String {
        var path = "/Users/eugenebokhan/Desktop/"
        let testsAppName = Bundle(for: Self.self).bundleIdentifier?.components(separatedBy: ".").last
        path += testsAppName != nil ? "\(testsAppName!)-Snapshots/" : ""
        return path
    }

    override func setUpWithError() throws {
        self.continueAfterFailure = true
    }

    func testSnaphotting() throws {
        self.app.activate()
        defer { self.app.terminate() }

        let flipTextureButton = self.app.buttons["FlipTextureButton"]
        
        try self.assert(element: flipTextureButton,
                        testName: self.testName(),
                        recording: false)
        
        try self.assert(screenshot: self.app.screenshot(),
                        testName: self.testName(),
                        ignore: [.statusBar],
                        recording: false)
        
        flipTextureButton.tap()
        
        try self.assert(screenshot: self.app.screenshot(),
                        testName: self.testName(),
                        ignore: [.statusBar],
                        recording: false)
    }
}
