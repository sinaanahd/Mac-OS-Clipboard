import XCTest
@testable import Pasteboard

private final class PermissionStub: AccessibilityPermissionProviding, @unchecked Sendable {
    var isTrusted: Bool
    private(set) var requested = false
    init(isTrusted: Bool) { self.isTrusted = isTrusted }
    func requestAccess() { requested = true }
}

private final class EventPosterSpy: PasteEventPosting, @unchecked Sendable {
    private(set) var postCount = 0
    func postCommandV() { postCount += 1 }
}

final class AutomaticPasteServiceTests: XCTestCase {
    func testPermissionIsRequiredBeforeActivationOrKeyEvent() {
        let permission = PermissionStub(isTrusted: false)
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: permission, eventPoster: poster)
        var activated = false
        XCTAssertEqual(service.paste { activated = true; return true }, .permissionRequired)
        XCTAssertFalse(activated)
        XCTAssertEqual(poster.postCount, 0)
    }

    func testTrustedPasteActivatesTargetBeforePosting() {
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: PermissionStub(isTrusted: true), eventPoster: poster)
        XCTAssertEqual(service.paste { true }, .pasted)
        XCTAssertEqual(poster.postCount, 1)
    }

    func testFailedActivationDoesNotPost() {
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: PermissionStub(isTrusted: true), eventPoster: poster)
        XCTAssertEqual(service.paste { false }, .activationFailed)
        XCTAssertEqual(poster.postCount, 0)
    }
}
