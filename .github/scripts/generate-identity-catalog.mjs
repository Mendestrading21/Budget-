#!/usr/bin/env node
// Génère Budget/Core/Identity/BudgetIdentityCatalog.swift depuis
// fixtures/catalogue-identites.json — la MÊME autorité éditoriale que la
// PWA (P08-C, ADR-041). Déterministe : mêmes octets à chaque exécution.
// Usage :
//   node .github/scripts/generate-identity-catalog.mjs           # écrit
//   node .github/scripts/generate-identity-catalog.mjs --check   # vérifie (CI)

import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";

const root = new URL("../..", import.meta.url).pathname;
const target = join(root, "Budget/Core/Identity/BudgetIdentityCatalog.swift");
const fixture = JSON.parse(readFileSync(join(root, "fixtures/catalogue-identites.json"), "utf8"));

const swiftString = value => `"${String(value).replaceAll("\\", "\\\\").replaceAll('"', '\\"')}"`;
const swiftArray = values => `[${values.map(swiftString).join(", ")}]`;

const entries = fixture.identities.map(e => `        .init(key: ${swiftString(e.key)}, `
  + `displayName: ${swiftString(e.displayName)}, `
  + `aliases: ${swiftArray(e.aliases ?? [])}, `
  + `markets: ${swiftArray(e.markets ?? [])}, `
  + `entityKind: ${swiftString(e.entityKind)}, `
  + `financialSense: ${swiftString(e.financialSense)}, `
  + `category: ${swiftString(e.category)}, `
  + `cadenceHints: ${swiftArray(e.cadenceHints ?? [])}, `
  + `monogram: ${e.monogram == null ? "nil" : swiftString(e.monogram)}, `
  + `glyphKey: ${swiftString(e.glyphKey)})`).join(",\n");

const swift = `import Foundation

// GÉNÉRÉ — ne pas éditer à la main.
// Source : fixtures/catalogue-identites.json (autorité éditoriale du skill
// budget-identites-locales). Régénérer :
//   node .github/scripts/generate-identity-catalog.mjs
// La CI échoue si ce fichier dérive de la fixture (P08-C, ADR-041).
//
// Le catalogue SUGGÈRE : jamais un montant, un solde, un compte, une date,
// un statut actif ni un abonnement possédé. Tout est local, hors ligne,
// sans aucune image ni requête réseau.

struct BudgetIdentityEntry: Sendable, Equatable {
    let key: String
    let displayName: String
    let aliases: [String]
    let markets: [String]
    let entityKind: String
    let financialSense: String
    let category: String
    let cadenceHints: [String]
    let monogram: String?
    let glyphKey: String
}

enum BudgetIdentityCatalog {
    static let version = ${Number(fixture.version)}

    static let all: [BudgetIdentityEntry] = [
${entries},
    ]

    /// V1 iOS : la base reste nativement CHF (garde-fou du skill) — seuls
    /// les services suisses et internationaux sont proposés.
    static var iosMarketEntries: [BudgetIdentityEntry] {
        all.filter { $0.markets.contains("CH") || $0.markets.contains("GLOBAL") }
    }

    /// Sens proposés sur « Ce qui revient » (P08) — les institutions
    /// attendent leurs propres lots (P05-C, P13-C).
    static let serviceSenses: Set<String> = ["subscription", "bill", "set_aside"]

    static var serviceEntries: [BudgetIdentityEntry] {
        iosMarketEntries.filter { serviceSenses.contains($0.financialSense) }
    }

    /// P05-C (ADR-043) : institutions proposées sur « Comptes » —
    /// banques, courtiers et prévoyance (les assureurs attendent P13-C).
    static let institutionSenses: Set<String> = ["account", "broker", "pension"]

    static var institutionEntries: [BudgetIdentityEntry] {
        iosMarketEntries.filter { $0.entityKind == "institution" && institutionSenses.contains($0.financialSense) }
    }

    /// L'entrée d'institution qui correspond EXACTEMENT à un nom saisi
    /// (nom ou alias, plié accents/casse) — jamais un « contient » :
    /// « CA » ou « BP » ne devinent rien (règle du skill).
    static func institutionEntry(matching name: String) -> BudgetIdentityEntry? {
        let needle = folded(name.trimmingCharacters(in: .whitespaces))
        guard !needle.isEmpty else { return nil }
        return all.first { entry in
            entry.entityKind == "institution"
                && ([entry.displayName] + entry.aliases).contains { folded($0) == needle }
        }
    }

    private static func folded(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_CH"))
    }
}
`;

const mode = process.argv.includes("--check") ? "check" : "write";
if (mode === "check") {
  let current = "";
  try { current = readFileSync(target, "utf8"); } catch { /* absent */ }
  if (current !== swift) {
    console.error("BudgetIdentityCatalog.swift dérive de fixtures/catalogue-identites.json — exécutez node .github/scripts/generate-identity-catalog.mjs");
    process.exit(1);
  }
  console.log("BudgetIdentityCatalog.swift : synchronisé avec la fixture ✓");
} else {
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, swift);
  console.log(`écrit : ${target} (${fixture.identities.length} identités)`);
}
