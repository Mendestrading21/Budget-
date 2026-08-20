import SwiftUI

/// IC1 (ADR-038) : monogramme déterministe PARTAGÉ avec la PWA
/// (`monogramFor` dans webapp/index.html) — mots = suites de
/// lettres/chiffres Unicode, première lettre des DEUX premiers mots, en
/// majuscules. La fixture commune `fixtures/monogram-cases.json` prouve
/// les deux implémentations.
enum BudgetMonogram {
    static func letters(for name: String) -> String {
        name.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .prefix(2)
            .compactMap { word in word.first.map { String($0).uppercased() } }
            .joined()
    }
}

/// Tuile d'identité DÉCORATIVE : un monogramme local sûr dans le même
/// puits mat que `BudgetIcon`, sinon un Budget Glyph générique. Elle ne
/// remplace jamais le libellé, ne charge jamais d'image et reste cachée
/// aux technologies d'assistance. Aucune persistance (IC1).
struct BudgetIdentityIcon: View {
    let name: String
    var fallback: BudgetGlyph = .other

    var body: some View {
        let letters = BudgetMonogram.letters(for: name)
        Group {
            if letters.isEmpty {
                BudgetIcon(fallback, style: .well)
            } else {
                Text(letters)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .kerning(0.6)
                    .foregroundStyle(NeonUltraColor.textSecondary)
                    .frame(width: NeonUltraIconMetric.well, height: NeonUltraIconMetric.well)
                    .background(BudgetIconTone.neutral.background)
                    .clipShape(RoundedRectangle(cornerRadius: NeonUltraIconMetric.radius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: NeonUltraIconMetric.radius, style: .continuous)
                            .stroke(NeonUltraColor.border, lineWidth: 1)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}
