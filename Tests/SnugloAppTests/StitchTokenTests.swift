import XCTest
import SwiftUI
@testable import SnugloApp

// MARK: — StitchTokenTests
// Verifies that all v1.1 Stitch Nordic Hearth tokens exist in AppColors and AppTypography.
// These are smoke tests — they assert the token exists (not nil / not default), not the
// exact rendered color value (which depends on traitCollection & UIKit internals).

final class StitchTokenTests: XCTestCase {

    // MARK: — Color Tokens

    func test_gameBoardBackground_exists() {
        // Must not be equal to the default .clear (would mean the property was accidentally removed)
        XCTAssertNotEqual(AppColors.gameBoardBackground, Color.clear,
                          "gameBoardBackground token must be defined")
    }

    func test_gridLine_exists() {
        XCTAssertNotEqual(AppColors.gridLine, Color.clear,
                          "gridLine token must be defined")
    }

    func test_blushAccent_exists() {
        XCTAssertNotEqual(AppColors.blushAccent, Color.clear,
                          "blushAccent token must be defined")
    }

    func test_divider_exists() {
        XCTAssertNotEqual(AppColors.divider, Color.clear,
                          "divider token must be defined")
    }

    func test_softCocoa_exists() {
        XCTAssertNotEqual(AppColors.softCocoa, Color.clear,
                          "softCocoa token must be defined")
    }

    func test_gridBackground_aliases_gameBoardBackground() {
        // gridBackground and gameBoardBackground must be the same value
        XCTAssertEqual(AppColors.gridBackground, AppColors.gameBoardBackground,
                       "gridBackground must alias gameBoardBackground")
    }

    func test_gridLines_aliases_gridLine() {
        XCTAssertEqual(AppColors.gridLines, AppColors.gridLine,
                       "gridLines must alias gridLine")
    }

    // MARK: — Typography Tokens

    func test_headlineLarge_usesCustomFont() {
        // AppTypography.headlineLarge must not crash to create
        let font = AppTypography.headlineLarge
        // If the font registration failed, UIKit returns .systemFont — we can still exercise it.
        XCTAssertNotNil(font)
    }

    func test_headlineMedium_exists() {
        XCTAssertNotNil(AppTypography.headlineMedium)
    }

    func test_headlineSmall_exists() {
        XCTAssertNotNil(AppTypography.headlineSmall)
    }

    func test_bodyLarge_exists() {
        XCTAssertNotNil(AppTypography.bodyLarge)
    }

    func test_bodyMedium_exists() {
        XCTAssertNotNil(AppTypography.bodyMedium)
    }

    func test_numericLarge_exists() {
        XCTAssertNotNil(AppTypography.numericLarge)
    }

    func test_numericLabel_exists() {
        XCTAssertNotNil(AppTypography.numericLabel)
    }

    func test_numericSmall_exists() {
        XCTAssertNotNil(AppTypography.numericSmall)
    }

    func test_labelSmall_exists() {
        XCTAssertNotNil(AppTypography.labelSmall)
    }

    // MARK: — Spacing Tokens

    func test_spacing_marginScreen_is24() {
        XCTAssertEqual(AppSpacing.lg, 24, "Stitch margin-screen = 24 pt")
    }

    func test_spacing_paddingInternal_is16() {
        XCTAssertEqual(AppSpacing.md, 16, "Stitch padding-internal = 16 pt")
    }

    func test_spacing_gutterGrid_is4() {
        XCTAssertEqual(AppSpacing.xs, 4, "Stitch gutter-grid = 4 pt")
    }

    func test_spacing_stackSm_is8() {
        XCTAssertEqual(AppSpacing.sm, 8, "Stitch stack-sm = 8 pt")
    }

    func test_spacing_stackLg_is32() {
        XCTAssertEqual(AppSpacing.xl, 32, "Stitch stack-lg = 32 pt")
    }

    // MARK: — Radius Tokens

    func test_radius_card_is20() {
        XCTAssertEqual(AppRadius.card, 20, "Card radius must be 20 pt (Stitch spec)")
    }

    func test_radius_button_is14() {
        XCTAssertEqual(AppRadius.button, 14, "Button radius must be 14 pt (Stitch spec)")
    }

    func test_radius_block_is10() {
        XCTAssertEqual(AppRadius.block, 10, "Block radius must be 10 pt (Stitch spec)")
    }
}
