import WidgetKit
import SwiftUI

/* PFOS-P7 : le widget Budget — un MIROIR en lecture seule du mois
   courant. Il ne calcule rien : il affiche l'instantané que l'app a
   écrit à son dernier passage (WidgetSnapshotStore), avec l'heure de
   cet instantané en clair — honnêteté d'abord. Sans instantané (app
   jamais ouverte, groupe d'apps non provisionné), il INVITE à ouvrir
   l'app au lieu d'inventer des chiffres. Identité sombre unique
   (ADR-024/074) : fond obsidienne, vert = argent reçu, corail =
   dépensé, violet neutre = mis de côté, aucun halo sur les montants. */

struct BudgetWidgetEntry: TimelineEntry {
    let date: Date
    let summary: WidgetMonthSummary?
    /// Vrai uniquement dans la galerie de widgets : l'aperçu est un
    /// EXEMPLE marqué comme tel, jamais présenté comme vos données.
    let isExample: Bool
}

extension WidgetMonthSummary {
    /// Aperçu de la galerie — données d'exemple, étiquetées « Exemple ».
    static let apercuGalerie = WidgetMonthSummary(
        schemaVersion: WidgetMonthSummary.currentSchemaVersion,
        monthLabel: "Ce mois",
        generatedAt: Date(),
        currencyCode: "CHF",
        availableCents: 182_050,
        incomeCents: 545_000,
        livingExpensesCents: 289_450,
        setAsideCents: 118_700
    )
}

struct BudgetWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetWidgetEntry {
        BudgetWidgetEntry(date: Date(), summary: .apercuGalerie, isExample: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetWidgetEntry) -> Void) {
        if context.isPreview {
            completion(BudgetWidgetEntry(date: Date(), summary: .apercuGalerie, isExample: true))
        } else {
            completion(BudgetWidgetEntry(date: Date(), summary: WidgetSnapshotStore.load(), isExample: false))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetWidgetEntry>) -> Void) {
        // Une seule entrée : le miroir ne change que quand l'app écrit
        // (elle demande alors le rechargement). Le réveil horaire ne sert
        // qu'à rafraîchir la mention « au … » si l'app reste fermée.
        let entry = BudgetWidgetEntry(date: Date(), summary: WidgetSnapshotStore.load(), isExample: false)
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

enum WidgetPalette {
    static let fond = Color(red: 9 / 255, green: 12 / 255, blue: 18 / 255)
    static let texte = Color.white
    static let secondaire = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let positif = Color(red: 54 / 255, green: 211 / 255, blue: 153 / 255)
    static let negatif = Color(red: 255 / 255, green: 107 / 255, blue: 122 / 255)
    static let violet = Color(red: 124 / 255, green: 58 / 255, blue: 237 / 255)
}

enum WidgetFormatting {
    /// fr-CH, deux décimales, séparateur de milliers — même lecture que
    /// l'app. Le préfixe devise et le montant restent sur une seule ligne.
    static func montant(_ cents: Int, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "fr_CH")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let value = NSDecimalNumber(decimal: WidgetMonthSummary.amount(fromCents: cents))
        return "\(code)\u{00A0}\(formatter.string(from: value) ?? "0.00")"
    }

    static func horodatage(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_CH")
        formatter.dateFormat = "dd.MM 'à' HH:mm"
        return formatter.string(from: date)
    }
}

struct BudgetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BudgetWidgetEntry

    var body: some View {
        Group {
            if let summary = entry.summary {
                rempli(summary)
            } else {
                vide
            }
        }
        .containerBackground(for: .widget) { WidgetPalette.fond }
    }

    private var vide: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Budget")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WidgetPalette.texte)
            Text("Ouvrez l'app pour remplir ce widget avec votre mois.")
                .font(.system(size: 12))
                .foregroundStyle(WidgetPalette.secondaire)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
    }

    private func rempli(_ summary: WidgetMonthSummary) -> some View {
        let dispo = WidgetFormatting.montant(summary.availableCents, code: summary.currencyCode)
        let recu = WidgetFormatting.montant(summary.incomeCents, code: summary.currencyCode)
        let depense = WidgetFormatting.montant(summary.livingExpensesCents, code: summary.currencyCode)
        let cote = WidgetFormatting.montant(summary.setAsideCents, code: summary.currencyCode)
        let source = entry.isExample
            ? "Exemple"
            : "au \(WidgetFormatting.horodatage(summary.generatedAt))"
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(summary.monthLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(WidgetPalette.secondaire)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(source)
                    .font(.system(size: 10))
                    .foregroundStyle(WidgetPalette.secondaire)
                    .lineLimit(1)
            }
            Text("Disponible")
                .font(.system(size: 11))
                .foregroundStyle(WidgetPalette.secondaire)
            Text(dispo)
                .font(.system(size: family == .systemSmall ? 17 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(summary.availableCents < 0 ? WidgetPalette.negatif : WidgetPalette.texte)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if family != .systemSmall {
                Spacer(minLength: 2)
                HStack(spacing: 10) {
                    ligne("Reçu", valeur: recu, teinte: WidgetPalette.positif)
                    ligne("Dépensé", valeur: depense, teinte: WidgetPalette.negatif)
                    ligne("Mis de côté", valeur: cote, teinte: WidgetPalette.violet)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(summary.monthLabel), \(source). Disponible \(dispo). Reçu \(recu), dépensé \(depense), mis de côté \(cote)."
        )
    }

    private func ligne(_ mot: String, valeur: String, teinte: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(mot)
                .font(.system(size: 10))
                .foregroundStyle(WidgetPalette.secondaire)
                .lineLimit(1)
            Text(valeur)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(teinte)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BudgetMonthWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BudgetMonthWidget", provider: BudgetWidgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
        }
        .configurationDisplayName("Mois en cours")
        .description("Disponible, reçu, dépensé et mis de côté — à jour du dernier passage dans l'app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct BudgetWidgetsBundle: WidgetBundle {
    var body: some Widget {
        BudgetMonthWidget()
    }
}
