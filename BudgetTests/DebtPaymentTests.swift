import XCTest
@testable import Budget

/// ADR-016 : un remboursement de dette avec compte de destination débite
/// le cash ET crédite le compte de dette — la fortune nette ne bouge pas.
final class DebtPaymentTests: XCTestCase {
    private let balanceService = AccountBalanceService()
    private let validationService = TransactionValidationService()
    private let netWorthService = NetWorthService(
        calendar: Calendar(identifier: .gregorian),
        balanceService: AccountBalanceService()
    )
    private let now = Date(timeIntervalSince1970: 1_781_524_800)

    private func makeAccounts() -> (current: Account, card: Account) {
        let current = Account(name: "Compte courant", type: .current, openingBalance: Decimal("5000.00"))
        let card = Account(name: "Carte de crédit", type: .creditCard, openingBalance: Decimal("-1200.00"))
        return (current, card)
    }

    func testValidationAcceptsDebtAccountDestination() {
        let (current, card) = makeAccounts()
        var draft = TransactionDraft()
        draft.date = now
        draft.amount = Decimal("300.00")
        draft.type = .debtPayment
        draft.title = "Remboursement carte"
        draft.account = current
        draft.destinationAccount = card
        draft.category = BudgetCategory(name: "Dettes", kind: .expense, iconToken: "d", sortOrder: 0)
        XCTAssertTrue(validationService.validate(draft, now: now).isEmpty,
                      "La destination d'un remboursement de dette doit être acceptée")
    }

    func testValidationStillRejectsDestinationEqualToSource() {
        let (current, _) = makeAccounts()
        var draft = TransactionDraft()
        draft.date = now
        draft.amount = Decimal("300.00")
        draft.type = .debtPayment
        draft.title = "Remboursement"
        draft.account = current
        draft.destinationAccount = current
        draft.category = BudgetCategory(name: "Dettes", kind: .expense, iconToken: "d", sortOrder: 0)
        XCTAssertTrue(validationService.validate(draft, now: now)
            .contains(.transferDestinationEqualsSource))
    }

    func testDebtPaymentMovesCashAndReducesDebtTogether() {
        let (current, card) = makeAccounts()
        let payment = BudgetTransaction(
            date: now, amount: Decimal("300.00"), type: .debtPayment,
            title: "Remboursement carte", account: current, destinationAccount: card
        )

        XCTAssertEqual(balanceService.signedEffect(of: payment, on: current), Decimal("-300.00"))
        XCTAssertEqual(balanceService.signedEffect(of: payment, on: card), Decimal("300.00"),
                       "Le compte de dette remonte vers zéro")
        XCTAssertEqual(balanceService.balance(of: card, movements: [payment]), Decimal("-900.00"))
    }

    func testNetWorthUnchangedByCapitalRepayment() {
        let (current, card) = makeAccounts()
        let before = netWorthService.breakdown(
            accounts: [current, card], assets: [], pensions: [], liabilities: []
        ).netWorth

        let payment = BudgetTransaction(
            date: now, amount: Decimal("300.00"), type: .debtPayment,
            title: "Remboursement carte", account: current, destinationAccount: card
        )
        let currentAfter = balanceService.balance(of: current, movements: [payment])
        let cardAfter = balanceService.balance(of: card, movements: [payment])
        // 5000 − 300 + (−1200 + 300) = 3800 = 5000 + (−1200)
        XCTAssertEqual(currentAfter + cardAfter, before,
                       "Un remboursement de capital ne change pas la fortune nette")
    }

    func testPartialAndOverpaymentBehaveArithmetically() {
        let (_, card) = makeAccounts()
        let partial = BudgetTransaction(
            date: now, amount: Decimal("100.00"), type: .debtPayment,
            title: "Partiel", account: Account(name: "C", type: .current), destinationAccount: card
        )
        XCTAssertEqual(balanceService.balance(of: card, movements: [partial]), Decimal("-1100.00"))

        let overpayment = BudgetTransaction(
            date: now, amount: Decimal("1500.00"), type: .debtPayment,
            title: "Trop-payé", account: Account(name: "C2", type: .current), destinationAccount: card
        )
        XCTAssertEqual(balanceService.balance(of: card, movements: [overpayment]), Decimal("300.00"),
                       "Un trop-payé laisse un solde positif visible — jamais masqué")
    }

    func testStandaloneDebtPaymentWithoutDestinationStillValid() {
        // Sans destination : dépense de remboursement vers un créancier
        // externe (la dette vit alors dans le Patrimoine, mise à jour à la main).
        let (current, _) = makeAccounts()
        var draft = TransactionDraft()
        draft.date = now
        draft.amount = Decimal("250.00")
        draft.type = .debtPayment
        draft.title = "Mensualité prêt externe"
        draft.account = current
        draft.category = BudgetCategory(name: "Dettes", kind: .expense, iconToken: "d", sortOrder: 0)
        XCTAssertTrue(validationService.validate(draft, now: now).isEmpty)
    }
}
