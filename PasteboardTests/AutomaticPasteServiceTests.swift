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

@MainActor
final class AutomaticPasteServiceTests: XCTestCase {
    func testPermissionIsRequiredBeforeActivationOrKeyEvent() async {
        let permission = PermissionStub(isTrusted: false)
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: permission, eventPoster: poster)
        var activated = false
        let result = await service.paste {
            activated = true
            return true
        } isTargetFrontmost: { false }
        XCTAssertEqual(result, .permissionRequired)
        XCTAssertFalse(activated)
        XCTAssertEqual(poster.postCount, 0)
    }

    func testTrustedPasteWaitsForFrontmostTargetBeforePostingOnce() async {
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: PermissionStub(isTrusted: true), eventPoster: poster)
        var checks = 0
        let result = await service.paste {
            true
        } isTargetFrontmost: {
            checks += 1
            return checks == 3
        } wait: { _ in }
        XCTAssertEqual(result, .pasted)
        XCTAssertEqual(poster.postCount, 1)
        XCTAssertEqual(checks, 3)
    }

    func testFailedActivationDoesNotPost() async {
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: PermissionStub(isTrusted: true), eventPoster: poster)
        let result = await service.paste { false } isTargetFrontmost: { true }
        XCTAssertEqual(result, .activationFailed)
        XCTAssertEqual(poster.postCount, 0)
    }

    func testTargetThatNeverBecomesFrontmostDoesNotPost() async {
        let poster = EventPosterSpy()
        let service = AutomaticPasteService(permission: PermissionStub(isTrusted: true),
                                            eventPoster: poster)
        let result = await service.paste { true } isTargetFrontmost: { false } wait: { _ in }
        XCTAssertEqual(result, .activationFailed)
        XCTAssertEqual(poster.postCount, 0)
    }
}
