# Budget visual system

## Canonical direction

The primary visual reference is `visual/01_canonical_budget_identity.png`. The graph reference is `visual/02_graph_and_glass_reference.jpeg`. Other images are supporting mood references. Do not reproduce third-party brand names, logos, or layouts literally.

## Experience qualities

- Neutral, premium, reassuring, precise.
- Dark-luxury glass without becoming a gaming or crypto interface.
- Financially credible, but warmer than a bank.
- Lifestyle accents connect money to home, family, holidays, comfort, and peace of mind.

## Color tokens

Core:

- Graphite `#0B0E14`
- Midnight `#0F1624`
- Slate Blue `#1E2333`
- Indigo `#4B5CFF`
- Off White `#F2F4F8`
- Cool Gray `#7A8699`
- Amber `#FFB24D`

Supporting:

- Electric Blue `#5AA7FF`
- Violet `#8B5CF6`
- Cyan `#55DDE0`
- Positive `#39D98A`
- Negative `#FF667A`
- Warning `#FFB24D`

Create semantic colors rather than referencing raw hex values throughout the app. Verify contrast in both appearances.

## Typography

Use the native iOS system font in implementation. Approximate the reference's Sora/Inter character through hierarchy, weight, tracking, and spacing. Do not distribute font files.

Suggested roles:

- Hero amount: 34–42 pt, semibold/rounded where appropriate, monospaced digits.
- Screen title: 28–34 pt bold.
- Section title: 17–20 pt semibold.
- Card label: 12–14 pt medium, secondary color.
- Body: 15–17 pt regular.
- Caption: 11–13 pt regular.

Never lock critical text to a fixed size that breaks Dynamic Type.

## Glass construction

A glass card should usually contain:

1. A dark translucent fill.
2. A top-left soft highlight.
3. A low-opacity border, optionally with an indigo-to-violet accent on active cards.
4. A subtle inner shadow or overlay.
5. One restrained outer shadow.
6. Blur/material only when performance remains smooth.

Use stronger glass on hero cards and lighter treatments on list rows. Do not stack multiple heavy materials in scrolling cells.

## Shape and spacing

- Main cards: 20–28 pt radius.
- Small controls: 12–16 pt radius.
- Screen horizontal margin: 16–20 pt.
- Card internal padding: 16–24 pt.
- Use an 8 pt spacing rhythm, allowing 4 pt for micro-alignment.
- Prefer breathing room over many thin dividers.

## Charts

Charts must resemble the luminous, calm visual language of the graph reference:

- Thin luminous line with a restrained blue–indigo–violet gradient.
- Small highlighted points only where useful.
- Very subtle grid lines.
- Limited labels; expose details through selection/VoiceOver.
- Donut charts use a generous center and clear central value.
- Bars use narrow rounded capsules with soft bloom on the active period.
- Positive/negative color has semantic meaning; do not color every series randomly.
- Provide a nonvisual textual summary.
- Avoid 3D charts, misleading truncated axes, excessive area fill, and decorative volatility.

## Icons

Use SF Symbols as the implementation baseline with a coherent weight and rendering mode. Build custom vector assets only for the Budget monogram or a genuinely missing concept. Icons must have text labels in primary navigation.

## Emoji policy

Emojis make the product more human without reducing trust:

- Good contexts: greeting, family holiday goal, home, food, transport, celebration, wellbeing.
- Maximum one or two small emojis in a card title area.
- Never use emoji as the only icon or status signal.
- Avoid emoji in tax warnings, validation errors, privacy/security actions, and formal exports.
- Respect reduced motion and accessibility labels.

## Dashboard composition

The dashboard hierarchy is:

1. Truly available money.
2. Days remaining and daily available amount.
3. Income, living costs, savings/investments, and taxes.
4. Budget-versus-actual chart.
5. Three priority actions.
6. Recent or uncategorized transactions.

Do not fill the first viewport with every module.

## Light appearance

The canonical identity is dark, but the app must support a premium light appearance:

- Warm off-white or very pale cool gray background.
- White translucent cards with subtle navy borders.
- Indigo remains the primary accent.
- Reduce bloom and shadow strength.
- Preserve semantic colors and chart readability.
