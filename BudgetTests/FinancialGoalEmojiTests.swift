import XCTest
@testable import Budget

/// P10 (ADR-046) : l'emoji d'un objectif est un CHOIX — modifier ne le
/// réécrit jamais. Il ne suit le type que tant qu'il n'a pas été
/// personnalisé (le parcours e2e 167 prouve la même règle côté PWA).
final class FinancialGoalEmojiTests: XCTestCase {
    func testCustomEmojiSurvivesEditingAndKindChange() {
        XCTAssertEqual(
            FinancialGoal.emojiAfterEditing(current: "🚗", from: .custom, to: .custom), "🚗",
            "un emoji personnel survit à une simple modification"
        )
        XCTAssertEqual(
            FinancialGoal.emojiAfterEditing(current: "🚗", from: .travel, to: .property), "🚗",
            "un emoji personnel survit même quand le type change"
        )
    }

    func testDefaultEmojiFollowsTheKindOnlyWhileNeverCustomized() {
        XCTAssertEqual(
            FinancialGoal.emojiAfterEditing(current: "🏖️", from: .travel, to: .vehicle), "🚗",
            "l'emoji par défaut du type suit le nouveau type"
        )
        XCTAssertEqual(
            FinancialGoal.emojiAfterEditing(current: nil, from: .travel, to: .vehicle), "🚗",
            "sans emoji, le défaut du nouveau type s'applique"
        )
        XCTAssertEqual(
            FinancialGoal.emojiAfterEditing(current: "🏖️", from: .travel, to: .travel), "🏖️",
            "sans changement, rien ne bouge"
        )
    }

    func testRestoredEmojiIsNotDestroyedByTheFormRule() {
        // Une sauvegarde restaurée porte l'emoji d'origine (BackupService
        // transporte goal.emoji) : la règle du formulaire le préserve.
        let goal = FinancialGoal(
            name: "Ma voiture", kind: .travel, emoji: "🚗",
            targetAmount: Decimal(5000)
        )
        XCTAssertEqual(
            FinancialGoal.emojiAfterEditing(current: goal.emoji, from: goal.kind, to: .travel), "🚗",
            "l'emoji restauré ne disparaît pas à la première modification"
        )
    }
}
