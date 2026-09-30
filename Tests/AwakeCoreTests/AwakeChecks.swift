import Foundation

/// Entry point of `swift run AwakeChecks`: an executable suite that works without XCTest.
/// Add a `test…` method in an `extension AwakeChecks` file, then list it below.
@main
@MainActor
struct AwakeChecks {
    static func main() async throws {
        let t = Self()
        var count = 0
        func run(_ body: () async throws -> Void) async throws {
            try await body()
            count += 1
        }

        // Model and state rules
        try await run(t.testDemoStartsOffAndRetainsStateAcrossLoads)
        try await run(t.testFailedUpdatePreservesLastConfirmedStateAndCanRetry)
        try await run(t.testPendingUpdateDisablesFurtherWrites)
        try await run(t.testLoginItemFailureDoesNotClaimEnabled)
        try await run(t.testLoadRestoresKeepAwakeAndDisplayPreference)

        // Timer
        try await run(t.testTimerExpiryTurnsKeepAwakeOff)
        try await run(t.testChangingDurationWhileOnCancelsPreviousTimer)
        try await run(t.testLoadDoesNotRestartRunningTimer)
        try await run(t.testEndDateTracksTimerLifecycle)
        try await run(t.testExpiryDuringBusyWriteIsAppliedAfterwards)
        try await run(t.testTimerExpiryNeverPromptsForPassword)

        // Quit and helper
        try await run(t.testShutdownRestoresSleepWithoutPrompting)
        try await run(t.testShutdownWithoutHelperLeavesFlagAndDoesNotCrash)
        try await run(t.testCancelledPasswordPromptIsReportedAndStateKept)
        try await run(t.testHelperInstalledFlagFollowsSuccessfulInstall)

        // pmset lock
        try await run(t.testParsesPmsetSleepDisabled)
        try await run(t.testSudoersLineAllowsOnlyPmsetZeroOrOne)
        try await run(t.testHelperInstalledUsesPrivilegedPath)
        try await run(t.testLoadSurfacesLeftoverPmsetLock)
        try await run(t.testUnlockClearsLeftoverPmsetLock)
        try await run(t.testToggleWritesPmsetFlag)

        // IOKit assertions
        try await run(t.testAssertionCreateAndRelease)
        try await run(t.testFallsBackToIdleSystemSleepWhenPreventSystemSleepFails)
        try await run(t.testDisplayCreateFailureReleasesPartialAssertions)
        try await run(t.testFailedRollbackKeepsHoldTracked)
        try await run(t.testStayingOnThrowsWhenOldReleaseFails)
        try await run(t.testFailedAssertionCreateLeavesKeepAwakeOff)
        try await run(t.testRealIOKitAssertionCreateAndRelease)

        // Persistence
        try await run(t.testPreferencesRoundTripThroughUserDefaults)

        print("PASS: all \(count) scenarios")
    }
}
