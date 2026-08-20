#!/usr/bin/env python3
"""Valide un catalogue runtime Budget sans dépendance externe."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any


KEY_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
UNSAFE_TEXT_RE = re.compile(
    r"(?:https?|data|javascript):|[<>\u0000-\u001f\u007f-\u009f\u061c\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]",
    re.IGNORECASE,
)
MARKETS = {"GLOBAL", "CH", "FR", "BE"}
ENTITY_KINDS = {"generic", "service", "institution"}
FINANCIAL_SENSES = {
    "subscription",
    "bill",
    "set_aside",
    "account",
    "broker",
    "insurance",
    "pension",
    "asset",
    "liability",
}
CATEGORIES = {
    "housing",
    "health",
    "energy",
    "water",
    "tax",
    "childcare",
    "credit",
    "video",
    "music",
    "cloud",
    "software",
    "ai",
    "gaming",
    "fitness",
    "telecom",
    "transport",
    "press",
    "delivery",
    "dating",
    "bank",
    "fintech",
    "broker",
    "pension",
    "insurance",
    "saving",
    "investment",
    "other",
}
CADENCES = {
    "none",
    "week",
    "four_weeks",
    "month",
    "quarter",
    "semiannual",
    "year",
    "custom",
}
CURRENCIES = {"CHF", "EUR"}
MARK_POLICIES = {"generic_glyph", "monogram", "approved_asset"}
ROOT_FIELDS = {"version", "identities"}
GLYPH_KEYS = {
    "accounts",
    "ai",
    "bill",
    "cloud",
    "dating",
    "delivery",
    "family",
    "fitness",
    "gaming",
    "health",
    "home",
    "investment",
    "liability",
    "music",
    "press",
    "saving",
    "shield",
    "software",
    "tax",
    "telecom",
    "transport",
    "video",
}
REQUIRED = {
    "key",
    "displayName",
    "aliases",
    "markets",
    "entityKind",
    "financialSense",
    "category",
    "cadenceHints",
    "currencyHints",
    "glyphKey",
    "markPolicy",
    "monogram",
    "assetKey",
}
FORBIDDEN_FIELDS = {
    "amount",
    "price",
    "balance",
    "rate",
    "dueDate",
    "active",
    "logoUrl",
    "remoteUrl",
    "html",
    "svg",
}


def fail(errors: list[str], where: str, message: str) -> None:
    errors.append(f"{where}: {message}")


def string_list(
    errors: list[str],
    where: str,
    value: Any,
    *,
    allowed: set[str] | None = None,
) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        fail(errors, where, "doit être une liste de chaînes")
        return []
    if allowed is not None:
        unknown = sorted(set(value) - allowed)
        if unknown:
            fail(errors, where, f"valeurs inconnues: {', '.join(unknown)}")
    if len(value) != len(set(value)):
        fail(errors, where, "ne doit pas contenir de doublon")
    return value


def validate(path: Path) -> tuple[list[str], dict[str, Any]]:
    errors: list[str] = []
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [f"{path}: JSON illisible: {exc}"], {}

    if not isinstance(document, dict):
        return ["racine: doit être un objet JSON"], {}
    missing_root = sorted(ROOT_FIELDS - set(document))
    unknown_root = sorted(set(document) - ROOT_FIELDS)
    if missing_root:
        fail(errors, "racine", f"champs manquants: {', '.join(missing_root)}")
    if unknown_root:
        fail(errors, "racine", f"champs hors contrat: {', '.join(unknown_root)}")
    if document.get("version") != 1:
        fail(errors, "version", "doit valoir 1")
    identities = document.get("identities")
    if not isinstance(identities, list):
        return errors + ["identities: doit être une liste"], document

    seen_keys: set[str] = set()
    category_counts: Counter[str] = Counter()
    market_counts: Counter[str] = Counter()

    for index, item in enumerate(identities):
        where = f"identities[{index}]"
        if not isinstance(item, dict):
            fail(errors, where, "doit être un objet")
            continue
        missing = sorted(REQUIRED - set(item))
        extra_forbidden = sorted(FORBIDDEN_FIELDS & set(item))
        unknown = sorted(set(item) - REQUIRED - FORBIDDEN_FIELDS)
        if missing:
            fail(errors, where, f"champs manquants: {', '.join(missing)}")
        if extra_forbidden:
            fail(errors, where, f"champs financiers/distants interdits: {', '.join(extra_forbidden)}")
        if unknown:
            fail(errors, where, f"champs hors contrat: {', '.join(unknown)}")

        key = item.get("key")
        if not isinstance(key, str) or not KEY_RE.fullmatch(key):
            fail(errors, f"{where}.key", "clé kebab-case ASCII invalide")
        elif key in seen_keys:
            fail(errors, f"{where}.key", f"clé dupliquée: {key}")
        else:
            seen_keys.add(key)

        name = item.get("displayName")
        if not isinstance(name, str) or not name.strip() or len(name) > 80:
            fail(errors, f"{where}.displayName", "nom vide ou supérieur à 80 caractères")

        aliases = string_list(errors, f"{where}.aliases", item.get("aliases"))
        for alias in aliases:
            if not alias.strip() or len(alias) > 80:
                fail(errors, f"{where}.aliases", f"alias vide ou trop long: {alias!r}")

        markets = string_list(
            errors, f"{where}.markets", item.get("markets"), allowed=MARKETS
        )
        if not markets:
            fail(errors, f"{where}.markets", "au moins un marché requis")
        market_counts.update(markets)

        if item.get("entityKind") not in ENTITY_KINDS:
            fail(errors, f"{where}.entityKind", "valeur inconnue")
        if item.get("financialSense") not in FINANCIAL_SENSES:
            fail(errors, f"{where}.financialSense", "valeur inconnue")

        category = item.get("category")
        if category not in CATEGORIES:
            fail(errors, f"{where}.category", "valeur inconnue")
        elif isinstance(category, str):
            category_counts[category] += 1

        string_list(
            errors, f"{where}.cadenceHints", item.get("cadenceHints"), allowed=CADENCES
        )
        string_list(
            errors, f"{where}.currencyHints", item.get("currencyHints"), allowed=CURRENCIES
        )

        glyph = item.get("glyphKey")
        if not isinstance(glyph, str) or not KEY_RE.fullmatch(glyph):
            fail(errors, f"{where}.glyphKey", "clé de glyphe invalide")
        elif glyph not in GLYPH_KEYS:
            fail(errors, f"{where}.glyphKey", "clé absente du registre éditorial fermé")

        policy = item.get("markPolicy")
        if policy not in MARK_POLICIES:
            fail(errors, f"{where}.markPolicy", "valeur inconnue")

        monogram = item.get("monogram")
        if monogram is not None and (
            not isinstance(monogram, str)
            or not monogram.strip()
            or len(monogram.strip()) > 3
        ):
            fail(errors, f"{where}.monogram", "doit contenir 1 à 3 caractères sûrs ou null")

        asset_key = item.get("assetKey")
        if policy == "approved_asset":
            if not isinstance(asset_key, str) or not KEY_RE.fullmatch(asset_key):
                fail(errors, f"{where}.assetKey", "requis et kebab-case pour approved_asset")
        elif asset_key is not None:
            fail(errors, f"{where}.assetKey", "doit être null sans actif approuvé")

        for field, value in item.items():
            strings = [value] if isinstance(value, str) else value if isinstance(value, list) else []
            for text in strings:
                if isinstance(text, str) and UNSAFE_TEXT_RE.search(text):
                    fail(errors, f"{where}.{field}", "markup, contrôle invisible ou protocole interdit")

    stats = {
        "identities": len(identities),
        "categories": dict(sorted(category_counts.items())),
        "markets": dict(sorted(market_counts.items())),
    }
    return errors, stats


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("catalogue", type=Path)
    args = parser.parse_args()
    errors, stats = validate(args.catalogue)
    if errors:
        for error in errors:
            print(f"ERREUR {error}", file=sys.stderr)
        return 1
    print(json.dumps(stats, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
