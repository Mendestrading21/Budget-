#!/usr/bin/env python3
"""Dérive TOUS les fichiers de marque à partir des deux images fournies par
le propriétaire (06.08.2026). Ce script est la seule source : les PNG du
dépôt n'en sont qu'un rendu, et une retouche se fait ici, jamais à la main.

    assets/marque/source-icone.png   l'anneau seul   -> icône d'application
    assets/marque/source-logo.png    anneau + « Budget » -> logo dans l'app

DEUX RÉGIMES, ET C'EST VOULU
----------------------------
· Les ICÔNES D'APPLICATION restent OPAQUES. iOS refuse la transparence :
  une icône trouée est compositée sur du BLANC, et l'anneau se retrouve
  cerné de blanc sur l'écran d'accueil. C'est une règle de plateforme, pas
  une préférence — le test e2e n° 98 la vérifie déjà.
· Les LOGOS UTILISÉS DANS L'APP deviennent TRANSPARENTS, pour se poser sur
  n'importe laquelle de nos surfaces sans rapporter un carré noir.

COMMENT LA TRANSPARENCE EST CALCULÉE
------------------------------------
Un néon sur fond noir n'a pas de contour net : le halo FAIT partie du
dessin. Découper sur un seuil le hacherait. On prend donc l'alpha dans la
luminosité (`alpha = max(r, v, b)`) puis on « dé-prémultiplie » la couleur
(`couleur / alpha`), ce qui reconstruit exactement l'original une fois
reposé sur du noir — et conserve le dégradé du halo au lieu de le trancher.

Conséquence assumée : ces logos sont faits pour des surfaces SOMBRES, ce
qui est le cas des cinq surfaces de l'app. Sur un fond clair ils
paraîtraient délavés.

Les logos internes sont aussi RECADRÉS sur leur dessin. L'artwork d'origine
laisse ~30 % de vide autour : posé tel quel dans une balise de 150 px, le
dessin n'en occuperait que 105 et paraîtrait timide. On garde une marge de
halo, pas une marge de cadre — et cette marge est ensuite estompée, sans
quoi le recadrage tranche le halo et dessine le rectangle qu'il devait ôter.

Usage :
    python3 .claude/skills/budget-neon-ultra/assets/tools/generer-marque.py
"""
import json
import pathlib
import sys

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow requis : python3 -m pip install Pillow")

RACINE = pathlib.Path(__file__).resolve().parents[5]
MARQUE = RACINE / ".claude/skills/budget-neon-ultra/assets/marque"
CANVAS = (5, 6, 10)  # #05060A — le fond de l'app


def carre(image):
    """Recadre au carré centré. Une icône non carrée est étirée par iOS."""
    largeur, hauteur = image.size
    if largeur == hauteur:
        return image
    cote = min(largeur, hauteur)
    gauche = (largeur - cote) // 2
    haut = (hauteur - cote) // 2
    return image.crop((gauche, haut, gauche + cote, haut + cote))


def opaque_sur_canvas(source, taille):
    """Icône d'application : carrée, opaque, posée sur le fond de l'app."""
    image = carre(source.convert("RGB")).resize((taille, taille), Image.LANCZOS)
    fond = Image.new("RGB", (taille, taille), CANVAS)
    # Le fond de l'artwork est déjà quasi noir ; on le compose en « screen »
    # sur notre canvas pour que les deux noirs ne se battent pas au bord.
    fond.paste(image, (0, 0))
    return fond


def plancher(image):
    """Niveau du fond à retirer. DEUX mesures, et on garde la plus haute.

    1. La médiane du BORD. L'artwork n'est pas noir PUR (≈ #060612) : sans
       cette soustraction, le PNG « transparent » garde un voile sombre sur
       tout le carré — alpha 17 dans les coins au lieu de 0.

    2. Le 85ᵉ centile de TOUTE l'image. Le bord ne suffit pas : l'artwork
       porte une nappe lumineuse très large autour de l'anneau, qui monte de
       18 au bord à ~46 près du trait. Invisible sur son fond d'origine
       (17-18 partout), elle devient une TACHE CLAIRE sur notre canvas
       #05060A, et cette tache s'arrête net au recadrage : un rectangle.
       Le dessin franc occupe 8 % (verrou) à 13 % (anneau) des pixels ; le
       85ᵉ centile reste donc du fond par construction, pas par réglage.

    Le halo SERRÉ autour du trait, lui, est bien au-dessus et survit."""
    largeur, hauteur = image.size
    pixels = image.load()
    bord = []
    for i in range(0, largeur, 4):
        bord.append(max(pixels[i, 0]))
        bord.append(max(pixels[i, hauteur - 1]))
    for j in range(0, hauteur, 4):
        bord.append(max(pixels[0, j]))
        bord.append(max(pixels[largeur - 1, j]))
    bord.sort()
    tout = sorted(max(pixels[x, y]) for y in range(0, hauteur, 2)
                  for x in range(0, largeur, 2))
    niveau = max(bord[len(bord) // 2], tout[int(len(tout) * 0.85)])
    # Garde-fou : un plancher qui mordrait le dessin serait un bug, pas un
    # réglage. On refuse plutôt que de rendre un logo amputé en silence.
    if niveau > 96:
        raise SystemExit(
            f"plancher mesuré à {niveau}/255 : le dessin occuperait moins de "
            "15 % de l'image, ou l'artwork a un fond clair. Vérifier la source.")
    return niveau


def recadrer_contenu(rgba, marge=0.06):
    """Recadre sur le dessin, halo compris. Le seuil ne sert QU'À trouver le
    cadre : aucun pixel n'est effacé, on ne fait que jeter du vide. La marge
    rendue est proportionnelle, donc la même à toutes les tailles.

    Puis les bords sont ESTOMPÉS sur la largeur de cette marge. Sans cela le
    recadrage tranche le halo là où il vaut encore ~14/255 : posé sur nos
    surfaces, ce bord net dessine un RECTANGLE plus clair autour du logo —
    exactement le carré que le recadrage était censé supprimer. Le fondu ne
    touche que la marge ajoutée : à la distance `m` du bord il vaut déjà 1,
    et c'est là que commence le dessin (seuil 24). Le dessin est donc
    intouché, par construction et pas par chance."""
    alpha = rgba.split()[3]
    boite = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
    if not boite:
        return rgba
    gauche, haut, droite, bas = boite
    m = round(max(droite - gauche, bas - haut) * marge)
    largeur, hauteur = rgba.size
    coupe = rgba.crop((max(0, gauche - m), max(0, haut - m),
                       min(largeur, droite + m), min(hauteur, bas + m)))
    if m < 2:
        return coupe
    w, h = coupe.size
    canal = coupe.split()[3]
    lu = canal.load()
    for y in range(h):
        for x in range(w):
            v = lu[x, y]
            if not v:
                continue
            d = min(x, y, w - 1 - x, h - 1 - y) / m
            if d >= 1:
                continue
            lu[x, y] = round(v * d * d * (3 - 2 * d))  # smoothstep, sans marche
    coupe.putalpha(canal)
    return coupe


def transparent(source, taille):
    """Logo interne : alpha tiré de la luminosité au-dessus du plancher de
    fond, couleur dé-prémultipliée. Le halo garde son dégradé — le découper
    sur un seuil le hacherait."""
    image = carre(source.convert("RGB")).resize((taille, taille), Image.LANCZOS)
    fond = plancher(image)
    etendue = max(1, 255 - fond)
    pixels = image.load()
    sortie = Image.new("RGBA", (taille, taille))
    dest = sortie.load()
    for y in range(taille):
        for x in range(taille):
            r, v, b = pixels[x, y]
            crete = max(r, v, b)
            if crete <= fond:
                dest[x, y] = (0, 0, 0, 0)
                continue
            a = min(255, round((crete - fond) * 255 / etendue))
            facteur = 255 / crete
            dest[x, y] = (
                min(255, int(r * facteur)),
                min(255, int(v * facteur)),
                min(255, int(b * facteur)),
                a,
            )
    return sortie


def logo_interne(source, cote_max=512):
    """Rend la transparence en pleine résolution, PUIS recadre, PUIS réduit —
    dans cet ordre. Recadrer après réduction perdrait de la définition sur un
    dessin qu'on vient justement d'agrandir en le recadrant."""
    plein = recadrer_contenu(transparent(source, 1024))
    plein.thumbnail((cote_max, cote_max), Image.LANCZOS)
    return plein


def ecrire(image, chemin):
    chemin.parent.mkdir(parents=True, exist_ok=True)
    image.save(chemin, "PNG", optimize=True)
    print(f"{chemin.relative_to(RACINE)} — {image.size[0]}×{image.size[1]} {image.mode}")


def imageset(source, dossier, nom, points):
    """Catalogue d'images iOS : les trois échelles d'un même dessin. Un seul
    PNG suffirait à Xcode, mais il serait rééchantillonné à l'affichage sur
    les écrans @2x et @3x — sur un trait fin en dégradé, ça se voit."""
    plein = recadrer_contenu(transparent(source, 1600))
    dossier.mkdir(parents=True, exist_ok=True)
    images = []
    for echelle in (1, 2, 3):
        largeur = points * echelle
        rendu = plein.copy()
        rendu.thumbnail((largeur, largeur * 4), Image.LANCZOS)
        fichier = f"{nom}@{echelle}x.png" if echelle > 1 else f"{nom}.png"
        ecrire(rendu, dossier / fichier)
        images.append({"idiom": "universal", "filename": fichier, "scale": f"{echelle}x"})
    (dossier / "Contents.json").write_text(json.dumps(
        {"images": images, "info": {"author": "generer-marque.py", "version": 1}},
        indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    icone = Image.open(MARQUE / "source-icone.png")
    logo = Image.open(MARQUE / "source-logo.png")

    # --- Icônes d'application : OPAQUES, une seule et même image partout.
    for taille, cible in [
        (512, RACINE / "webapp/icon-512.png"),
        (192, RACINE / "webapp/icon-192.png"),
        (180, RACINE / "webapp/apple-touch-icon.png"),
        (1024, RACINE / "Budget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png"),
    ]:
        if not cible.parent.exists():
            print(f"ignoré (dossier absent) : {cible}")
            continue
        ecrire(opaque_sur_canvas(icone, taille), cible)

    # --- Logos internes : TRANSPARENTS et recadrés sur le dessin.
    ecrire(logo_interne(icone), RACINE / "webapp/logo-anneau.png")
    ecrire(logo_interne(logo), RACINE / "webapp/logo-budget.png")

    # --- Le même verrou, côté natif. 180 pt de large sur l'écran de
    #     bienvenue : c'est LUI qui fixe les trois échelles.
    catalogue = RACINE / "Budget/Resources/Assets.xcassets"
    if catalogue.exists():
        imageset(logo, catalogue / "LogoBudget.imageset", "LogoBudget", 180)
        # L'anneau seul, pour l'écran verrouillé — 84 pt, comme la PWA.
        imageset(icone, catalogue / "LogoAnneau.imageset", "LogoAnneau", 84)


if __name__ == "__main__":
    main()
