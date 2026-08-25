import XCTest
import SwiftData
@testable import Budget

/// W1.6 — Runner Swift des fixtures canoniques (ADR-059).
/// Lit les MÊMES fichiers `fixtures/canon/*.json` que le runner Web
/// (`webapp/tests/canon.test.mjs`), construit l'état en mémoire, appelle
/// les services RÉELS (AccountBalanceService, MonthlySnapshotService,
/// NetWorthService) et compare aux attendus EN UNITÉS MINEURES ENTIÈRES,
/// champ par champ. C'est la gate de parité FI-40 : une divergence entre
/// plateformes échoue en NOMMANT la fixture et le champ.
///
/// Les fixtures que le natif ne peut pas encore tenir sont consignées
/// dans `enAttenteNatif` avec leur raison et le lot qui les fermera —
/// jamais un skip silencieux.
final class CanonicalFixtureTests: XCTestCase {

    // Écarts consignés : fixture → (raison, lot). Retirer une entrée
    // exige que la fixture passe — jamais l'inverse. W4.2b a fermé le
    // constat n° 6 (conversion FX datée des agrégats) : la liste est
    // VIDE — chaque fixture canonique s'exécute sur le moteur natif.
    private let enAttenteNatif: [String: String] = [:]

    private struct FixtureCanon: Decodable {
        struct Entrees: Decodable {
            struct Compte: Decodable {
                let id: String; let nom: String; let genre: String
                let devise: String; let ouvertureMineures: Int
                let cash: Bool; let patrimoine: Bool; let actif: Bool
            }
            struct Mouvement: Decodable {
                let id: String; let date: String; let type: String
                let statut: String; let montantMineures: Int; let devise: String
                let compte: String; let destination: String?
                let categorie: String?; let titre: String
                let hausse: Bool?; let recurrence: String?
            }
            struct Recurrence: Decodable {
                let id: String; let titre: String; let type: String
                let nature: String?; let montantMineures: Int; let devise: String
                let jour: Int; let rythme: String; let compte: String
            }
            struct Taux: Decodable {
                let base: String; let cote: String; let taux: String
                let date: String; let source: String
            }
            let deviseBase: String; let date: String
            let comptes: [Compte]; let mouvements: [Mouvement]
            let recurrences: [Recurrence]
            let taux: [Taux]?
        }
        struct Attendus: Decodable {
            struct Mois: Decodable {
                let annee: Int; let mois: Int
                let recuMineures: Int?; let depenseMineures: Int?
                let misDeCoteMineures: Int?; let liquideMineures: Int?
                let finDeMoisMineures: Int?; let resultatMineures: Int?
            }
            struct Patrimoine: Decodable {
                let fortuneTotaleMineures: Int?
                let epargneAccessibleMineures: Int?
            }
            let soldesMineures: [String: Int]
            let mois: Mois?
            let patrimoine: Patrimoine?
        }
        let version: Int; let nom: String
        let entrees: Entrees; let attendus: Attendus
    }

    private var calendar: Calendar!

    override func setUp() {
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.locale = FinanceFormatting.locale
    }

    private func dossierCanon() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // BudgetTests/
            .deletingLastPathComponent()   // racine du dépôt
            .appendingPathComponent("fixtures/canon")
    }

    private func francs(_ mineures: Int) -> Decimal {
        Decimal(mineures) / Decimal(100)
    }

    private func mineures(_ montant: Decimal) -> Int {
        NSDecimalNumber(decimal: montant * Decimal(100)).intValue
    }

    private func dateISO(_ iso: String, heure: Int = 12) -> Date {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        return calendar.date(from: DateComponents(
            year: parts[0], month: parts[1], day: parts[2], hour: heure))!
    }

    private func typeCompte(_ genre: String) -> AccountType? {
        switch genre {
        case "current": .current
        case "cash": .cash
        case "savings": .savings
        case "brokerage": .broker
        case "pension": .occupationalPension
        case "lifeinsurance": .pillar3b
        default: nil
        }
    }

    private func rythme(_ valeur: String) -> (RecurrenceUnit, Int)? {
        switch valeur {
        case "week": (.week, 1)
        case "twoWeeks": (.week, 2)
        case "fourWeeks": (.week, 4)
        case "month": (.month, 1)
        case "quarter": (.month, 3)
        case "semester": (.month, 6)
        case "year": (.year, 1)
        default: nil
        }
    }

    func testFixturesCanoniquesSurLeMoteurNatif() throws {
        let dossier = dossierCanon()
        let fichiers = try FileManager.default.contentsOfDirectory(atPath: dossier.path)
            .filter { $0.hasSuffix(".json") }
            .sorted()
        XCTAssertFalse(fichiers.isEmpty, "aucune fixture canonique trouvée — chemin faux ?")

        var executees = 0
        for nomFichier in fichiers {
            let donnees = try Data(contentsOf: dossier.appendingPathComponent(nomFichier))
            let fixture = try JSONDecoder().decode(FixtureCanon.self, from: donnees)
            if let raison = enAttenteNatif[fixture.nom] {
                // Consigné, jamais silencieux : l'écart est imprimé.
                print("CANON NATIF — en attente : \(fixture.nom) (\(raison))")
                continue
            }
            try verifie(fixture, fichier: nomFichier)
            executees += 1
        }
        XCTAssertGreaterThanOrEqual(executees, 13,
            "la gate doit exécuter TOUTES les fixtures depuis W4.2b — \(executees) seulement")
    }

    private func verifie(_ fixture: FixtureCanon, fichier: String) throws {
        let e = fixture.entrees
        let now = dateISO(e.date)
        // Conteneur en mémoire : les relations SwiftData (compte ↔
        // mouvements) ne se peuplent qu'une fois les objets insérés.
        let container = try PersistenceFactory.makeInMemoryContainer()
        let context = ModelContext(container)
        let household = Household(name: "Canon", taxProvisionRate: Decimal("0.30"))
        context.insert(household)

        var comptes: [String: Account] = [:]
        var listeComptes: [Account] = []
        for c in e.comptes {
            guard let type = typeCompte(c.genre) else {
                XCTFail("[\(fixture.nom)] genre de compte inconnu « \(c.genre) »"); return
            }
            let compte = Account(
                name: c.nom, type: type, currencyCode: c.devise,
                openingBalance: francs(c.ouvertureMineures),
                isActive: c.actif,
                includeInAvailableCash: c.cash,
                includeInNetWorth: c.patrimoine
            )
            context.insert(compte)
            comptes[c.id] = compte
            listeComptes.append(compte)
        }

        var recurrencesParId: [String: RecurringTransaction] = [:]
        var listeRecurrences: [RecurringTransaction] = []
        for r in e.recurrences {
            guard let type = TransactionType(rawValue: r.type) else {
                XCTFail("[\(fixture.nom)] type de récurrence inconnu « \(r.type) »"); return
            }
            guard let (unite, pas) = rythme(r.rythme) else {
                XCTFail("[\(fixture.nom)] rythme inconnu « \(r.rythme) »"); return
            }
            let premiereDate = calendar.date(from: DateComponents(
                year: 2026, month: 1, day: min(r.jour, 28), hour: 10))!
            let recurrence = RecurringTransaction(
                title: r.titre, amount: francs(r.montantMineures), type: type,
                intervalUnit: unite, intervalCount: pas,
                firstOccurrence: premiereDate,
                isSubscription: r.nature == "abonnement",
                account: comptes[r.compte]
            )
            context.insert(recurrence)
            recurrencesParId[r.id] = recurrence
            listeRecurrences.append(recurrence)
        }

        var mouvements: [BudgetTransaction] = []
        for m in e.mouvements {
            guard let type = TransactionType(rawValue: m.type) else {
                XCTFail("[\(fixture.nom)] type de mouvement inconnu « \(m.type) »"); return
            }
            guard let statut = TransactionStatus(rawValue: m.statut) else {
                XCTFail("[\(fixture.nom)] statut inconnu « \(m.statut) »"); return
            }
            let mouvement = BudgetTransaction(
                date: dateISO(m.date, heure: 10),
                amount: francs(m.montantMineures),
                type: type, status: statut, title: m.titre,
                adjustmentIncreasesBalance: m.hausse ?? true,
                recurringID: m.recurrence.flatMap { recurrencesParId[$0]?.id },
                account: comptes[m.compte],
                destinationAccount: m.destination.flatMap { comptes[$0] }
            )
            context.insert(mouvement)
            mouvements.append(mouvement)
        }

        // W4.2b (ADR-065) : les taux de la fixture deviennent des quotes
        // datées et sourcées — un taux illisible fait échouer la fixture,
        // jamais un repli silencieux.
        var quotes: [FxQuote] = []
        for t in (e.taux ?? []) {
            guard let taux = Decimal(string: t.taux), taux > 0 else {
                XCTFail("[\(fixture.nom)] taux illisible « \(t.taux) »"); return
            }
            quotes.append(FxQuote(
                base: t.base, quote: t.cote, rate: taux,
                observedAt: dateISO(t.date), source: t.source))
        }

        let balanceService = AccountBalanceService()

        for (id, attendu) in fixture.attendus.soldesMineures {
            guard let compte = comptes[id] else {
                XCTFail("[\(fixture.nom)] solde attendu d'un compte introuvable « \(id) »"); continue
            }
            let obtenu = mineures(balanceService.balance(of: compte, movements: mouvements))
            XCTAssertEqual(obtenu, attendu,
                "[\(fixture.nom)] solde \(id) : attendu \(attendu), obtenu \(obtenu)")
        }

        if let mois = fixture.attendus.mois {
            let ancre = calendar.date(from: DateComponents(
                year: mois.annee, month: mois.mois, day: 15, hour: 12))!
            let snapshot = MonthlySnapshotService(calendar: calendar).snapshot(
                monthOf: ancre, now: now, household: household,
                accounts: listeComptes, transactions: mouvements,
                recurrings: listeRecurrences, fxQuotes: quotes
            )
            verifieChamp(fixture.nom, "mois.recuMineures", mois.recuMineures, snapshot.totalIncome)
            verifieChamp(fixture.nom, "mois.depenseMineures", mois.depenseMineures, snapshot.totalLivingExpenses)
            verifieChamp(fixture.nom, "mois.misDeCoteMineures", mois.misDeCoteMineures,
                         snapshot.totalSavings + snapshot.totalInvestments)
            verifieChamp(fixture.nom, "mois.liquideMineures", mois.liquideMineures, snapshot.available.liquidBalance)
            verifieChamp(fixture.nom, "mois.finDeMoisMineures", mois.finDeMoisMineures, snapshot.available.total)
            verifieChamp(fixture.nom, "mois.resultatMineures", mois.resultatMineures, snapshot.cashFlow)
        }

        if let patrimoine = fixture.attendus.patrimoine {
            let netWorthService = NetWorthService(calendar: calendar, balanceService: balanceService)
            if let attendu = patrimoine.fortuneTotaleMineures {
                let fortune = netWorthService.breakdown(
                    accounts: listeComptes, assets: [], pensions: [], liabilities: [],
                    baseCurrency: e.deviseBase, fxQuotes: quotes, asOf: now
                ).netWorth
                let obtenu = mineures(fortune)
                XCTAssertEqual(obtenu, attendu,
                    "[\(fixture.nom)] patrimoine.fortuneTotaleMineures : attendu \(attendu), obtenu \(obtenu)")
            }
            if let attendu = patrimoine.epargneAccessibleMineures {
                let obtenu = mineures(netWorthService.accessibleSavings(accounts: listeComptes))
                XCTAssertEqual(obtenu, attendu,
                    "[\(fixture.nom)] patrimoine.epargneAccessibleMineures : attendu \(attendu), obtenu \(obtenu)")
            }
        }
    }

    private func verifieChamp(_ fixture: String, _ champ: String, _ attendu: Int?, _ valeur: Decimal) {
        guard let attendu else { return }
        let obtenu = mineures(valeur)
        XCTAssertEqual(obtenu, attendu,
            "[\(fixture)] \(champ) : attendu \(attendu), obtenu \(obtenu)")
    }
}
