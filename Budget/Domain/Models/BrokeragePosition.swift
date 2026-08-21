import Foundation
import SwiftData

/// INV1 (ADR-047) : une position manuelle DATÉE d'un compte titres.
/// Elle EXPLIQUE le solde du compte — jamais elle ne s'y ajoute : le
/// patrimoine lit le solde du compte, pas les positions. Le prix est
/// celui que la personne a saisi à une date donnée — Budget n'affiche
/// aucun cours du marché et n'en promet pas.
@Model
final class BrokeragePosition {
    @Attribute(.unique) var id: UUID
    var instrumentName: String
    var tickerOrISIN: String?
    var quantity: Decimal
    var manualPrice: Decimal
    var priceCurrency: String
    /// La date de la SAISIE (« Prix saisi le… »), jamais un cours du jour.
    var valuationDate: Date
    var costBasis: Decimal?
    var createdAt: Date
    var updatedAt: Date

    var account: Account?

    /// Valeur expliquée = quantité × prix saisi, arrondie au centime.
    var value: Decimal {
        FinanceMath.roundedToCents(quantity * manualPrice)
    }

    init(
        id: UUID = UUID(),
        instrumentName: String,
        tickerOrISIN: String? = nil,
        quantity: Decimal,
        manualPrice: Decimal,
        priceCurrency: String = "CHF",
        valuationDate: Date,
        costBasis: Decimal? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        account: Account? = nil
    ) {
        self.id = id
        self.instrumentName = instrumentName
        self.tickerOrISIN = tickerOrISIN
        self.quantity = quantity
        self.manualPrice = manualPrice
        self.priceCurrency = priceCurrency
        self.valuationDate = valuationDate
        self.costBasis = costBasis
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.account = account
    }
}

/// Les deux seuls calculs des positions, en un endroit testable :
/// total expliqué et « Espèces / non réparti » = solde − total.
enum BrokeragePositionMath {
    static func explainedTotal(_ positions: [BrokeragePosition]) -> Decimal {
        FinanceMath.roundedToCents(positions.reduce(Decimal.zero) { $0 + $1.value })
    }

    /// 44'000 de solde et 40'000 de positions → 4'000 d'espèces, et la
    /// fortune reste 44'000 — jamais 84'000.
    static func unallocated(balance: Decimal, positions: [BrokeragePosition]) -> Decimal {
        FinanceMath.roundedToCents(balance - explainedTotal(positions))
    }
}
