import Foundation

/// W3.2 (Budget Autonomie 100) — les écritures TYPES : chaque mouvement
/// existant se TRADUIT en écriture équilibrée (FI-08) sans changer le
/// mouvement. Le virement interne est UNE écriture à deux jambes de
/// comptes réels (FI-09) ; la mensualité de dette garde sa jambe de
/// dette (FI-14) ; le solde d'ouverture devient une écriture (FI-12).
/// Les montants restent dans la devise SOURCE du compte — un virement
/// de change sans montant estampillé est un refus nommé (le natif
/// n'estampille pas encore : consigné pour W4). SHADOW : personne
/// n'écrit encore ces écritures dans un store (l'ombre = W3.3).
struct JournalTranslationService {

    enum TranslationError: Error, Equatable, LocalizedError {
        case compteManquant
        case destinationManquante
        case montantInvalide
        case changeSansMontantEstampille

        var errorDescription: String? {
            switch self {
            case .compteManquant:
                "Ce mouvement ne nomme aucun compte — impossible d'écrire sa jambe réelle."
            case .destinationManquante:
                "Un mouvement interne nomme sa destination — l'argent n'arrive jamais nulle part."
            case .montantInvalide:
                "Montant illisible : des centimes entiers positifs — jamais arrondis en silence."
            case .changeSansMontantEstampille:
                "Virement de change sans montant estampillé : impossible d'écrire l'arrivée."
            }
        }
    }

    /// La frontière STRICTE mouvement → centimes : le montant doit être
    /// EXACTEMENT représentable en centimes (FI-34 — une précision
    /// excédentaire signale une corruption, on refuse au lieu d'arrondir).
    private func centimesStricts(_ montant: Decimal, devise: String) throws -> Money {
        guard let money = Money(amount: montant, currency: devise),
              money.decimalValue == montant,
              money.minorUnits > 0 else {
            throw TranslationError.montantInvalide
        }
        return money
    }

    /// Traduit UN mouvement en écriture équilibrée. Le mouvement n'est
    /// jamais modifié.
    func entry(from transaction: BudgetTransaction, now: Date) throws -> JournalEntry {
        guard let compte = transaction.account else { throw TranslationError.compteManquant }
        let devise = compte.currencyCode
        let money = try centimesStricts(transaction.amount, devise: devise)
        let jambeCompte = "compte:\(compte.id.uuidString)"
        let lifecycle: JournalLifecycle = transaction.status == .posted ? .posted : .pending
        let categorie = transaction.category?.name

        func jambe(_ compte: String, debit: Bool, _ montant: Money) -> JournalPostingDraft {
            JournalPostingDraft(accountKey: compte, isDebit: debit, amount: montant)
        }

        var kind = JournalEntryKind(rawValue: transaction.type.rawValue) ?? .adjustment
        let jambes: [JournalPostingDraft]
        switch transaction.type {
        case .saving, .investment, .transfer:
            guard let destination = transaction.destinationAccount else {
                throw TranslationError.destinationManquante
            }
            // FI-19/FI-16 en germe : le natif n'estampille pas encore de
            // montant d'arrivée pour un change — refus nommé, jamais un
            // taux inventé (consigné pour W4).
            guard destination.currencyCode == devise else {
                throw TranslationError.changeSansMontantEstampille
            }
            jambes = [
                jambe(jambeCompte, debit: false, money),
                jambe("compte:\(destination.id.uuidString)", debit: true, money),
            ]
        case .income:
            jambes = [
                jambe(jambeCompte, debit: true, money),
                jambe("rentree:\(categorie ?? "Revenu")", debit: false, money),
            ]
        case .refund:
            jambes = [
                jambe(jambeCompte, debit: true, money),
                jambe("remboursement:\(categorie ?? "Autre")", debit: false, money),
            ]
        case .taxPayment:
            jambes = [
                jambe(jambeCompte, debit: false, money),
                jambe("impot:Impôts", debit: true, money),
            ]
        case .adjustment:
            jambes = transaction.adjustmentIncreasesBalance
                ? [jambe(jambeCompte, debit: true, money),
                   jambe("ajustement:correction", debit: false, money)]
                : [jambe(jambeCompte, debit: false, money),
                   jambe("ajustement:correction", debit: true, money)]
        case .debtPayment:
            // FI-14 : le capital remboursé N'EST PAS un coût de la vie —
            // sa jambe nomme la dette.
            kind = .debtPayment
            jambes = [
                jambe(jambeCompte, debit: false, money),
                jambe("dette:\(categorie ?? transaction.title)", debit: true, money),
            ]
        case .expense:
            jambes = [
                jambe(jambeCompte, debit: false, money),
                jambe("depense:\(categorie ?? "Autre")", debit: true, money),
            ]
        }
        return try JournalEntry.equilibree(
            kind: kind,
            lifecycle: lifecycle,
            effectiveDate: transaction.date,
            title: transaction.title,
            idempotencyKey: "mouvement:\(transaction.id.uuidString)",
            postings: jambes,
            now: now
        )
    }

    /// FI-12 : le solde d'ouverture d'un compte devient UNE écriture
    /// datée de la CRÉATION du compte (avant toute histoire) — zéro
    /// n'écrit rien (nil explicite), un solde négatif inverse les
    /// jambes. La migration W3.7 raffinera l'ancrage.
    func openingEntry(for account: Account, now: Date) throws -> JournalEntry? {
        guard account.openingBalance != .zero else { return nil }
        let montantAbsolu = abs(account.openingBalance)
        guard let money = Money(amount: montantAbsolu, currency: account.currencyCode),
              money.decimalValue == montantAbsolu, money.minorUnits > 0 else {
            throw TranslationError.montantInvalide
        }
        let positif = account.openingBalance > 0
        return try JournalEntry.equilibree(
            kind: .opening,
            lifecycle: .posted,
            effectiveDate: account.createdAt,
            title: "Ouverture \(account.name)",
            idempotencyKey: "ouverture:\(account.id.uuidString)",
            postings: [
                JournalPostingDraft(accountKey: "compte:\(account.id.uuidString)",
                                    isDebit: positif, amount: money),
                JournalPostingDraft(accountKey: "ouverture:\(account.id.uuidString)",
                                    isDebit: !positif, amount: money),
            ],
            now: now
        )
    }
}
