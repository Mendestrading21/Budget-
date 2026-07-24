import SwiftUI
import SwiftData

/// Progressive local onboarding: privacy promise, household, location,
/// tax provision rate, first account. Everything is created in one save
/// at the end; demo mode stays available from the first screen.
struct OnboardingFlowView: View {
    @Environment(AppContainer.self) private var appContainer
    @Environment(\.modelContext) private var modelContext

    @State private var model = OnboardingViewModel()
    @State private var saveErrorMessage: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            BudgetScreenBackground()
            VStack(spacing: BudgetSpacing.large) {
                if model.step != .welcome {
                    progressHeader
                }

                ScrollView {
                    VStack(spacing: BudgetSpacing.medium) {
                        stepContent
                        if let message = model.validationMessage ?? saveErrorMessage {
                            Label(message, systemImage: "exclamationmark.circle")
                                .font(BudgetFont.body)
                                .foregroundStyle(BudgetColor.negative)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityLabel("Erreur : \(message)")
                        }
                    }
                    .padding(.horizontal, BudgetSpacing.screenMargin)
                }
                .scrollBounceBehavior(.basedOnSize)

                controls
                    .padding(.horizontal, BudgetSpacing.screenMargin)
                    .padding(.bottom, BudgetSpacing.medium)
            }
            .padding(.top, BudgetSpacing.medium)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.step)
    }

    // MARK: - Header

    private var progressHeader: some View {
        VStack(spacing: BudgetSpacing.small) {
            ProgressView(
                value: Double(model.step.progressIndex),
                total: Double(OnboardingStep.progressTotal - 1)
            )
            .tint(BudgetColor.indigo)
            .accessibilityLabel("Étape \(model.step.progressIndex + 1) sur \(OnboardingStep.progressTotal)")
        }
        .padding(.horizontal, BudgetSpacing.screenMargin)
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch model.step {
        case .welcome: welcomeStep
        case .household: householdStep
        case .location: locationStep
        case .taxRate: taxRateStep
        case .firstAccount: firstAccountStep
        case .income: incomeStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: BudgetSpacing.large) {
            VStack(spacing: BudgetSpacing.small) {
                Text("Budget")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient.budgetAccent)
                Text("Le tableau de bord financier de votre ménage")
                    .font(BudgetFont.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, BudgetSpacing.extraLarge)

            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    Label {
                        Text("Vos données restent sur cet appareil. Pas de compte en ligne, pas de serveur, pas de connexion bancaire.")
                    } icon: {
                        Image(systemName: "lock.shield")
                            .foregroundStyle(BudgetColor.positive)
                    }
                    Label {
                        Text("Les montants et calculs sont des estimations d'organisation, pas des conseils financiers.")
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(BudgetColor.informative)
                    }
                }
                .font(BudgetFont.body)
            }
        }
    }

    private var householdStep: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
            stepTitle("Votre ménage", subtitle: "Comment souhaitez-vous l'appeler ?")
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    labeledField("Nom du ménage") {
                        TextField("Famille Martin", text: Bindable(model).householdName)
                            .textInputAutocapitalization(.words)
                    }
                    labeledField("Votre prénom (facultatif)") {
                        TextField("Alex", text: Bindable(model).ownerFirstName)
                            .textInputAutocapitalization(.words)
                    }
                    labeledField("Prénom de votre partenaire (facultatif)") {
                        TextField("Camille", text: Bindable(model).partnerFirstName)
                            .textInputAutocapitalization(.words)
                    }
                }
            }
        }
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
            stepTitle("Où habitez-vous ?", subtitle: "Le canton prépare les futurs modules impôts et prévoyance.")
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    labeledField("Canton") {
                        Picker("Canton", selection: Bindable(model).canton) {
                            ForEach(SwissCanton.allCases) { canton in
                                Text(canton.displayName).tag(canton)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BudgetColor.indigo)
                    }
                    labeledField("Commune (facultatif)") {
                        TextField("Lausanne", text: Bindable(model).municipality)
                            .textInputAutocapitalization(.words)
                    }
                    labeledField("Devise de base") {
                        Text("CHF — franc suisse")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var taxRateStep: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
            stepTitle("Provision d'impôts", subtitle: "Quelle part de vos revenus mettre de côté pour les impôts ?")
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    Text(FinanceFormatting.percent(model.taxProvisionRate))
                        .font(BudgetFont.heroAmount)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("Taux de provision : \(FinanceFormatting.percent(model.taxProvisionRate))")

                    Slider(
                        value: Binding(
                            get: { NSDecimalNumber(decimal: model.taxProvisionRate).doubleValue },
                            set: { model.taxProvisionRate = FinanceMath.roundedToCents(Decimal($0)) }
                        ),
                        in: 0...0.5,
                        step: 0.01
                    )
                    .tint(BudgetColor.indigo)
                    .accessibilityLabel("Taux de provision d'impôts")
                    .accessibilityValue(FinanceFormatting.percent(model.taxProvisionRate))

                    Label {
                        Text("30 % est un simple point de départ d'organisation — ni un taux officiel, ni une recommandation fiscale. Ajustez-le à votre situation : il reste modifiable à tout moment dans Impôts.")
                            .font(BudgetFont.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(BudgetColor.informative)
                    }
                }
            }
        }
    }

    private var firstAccountStep: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
            stepTitle("Votre premier compte", subtitle: "Vous pourrez en ajouter d'autres ensuite.")
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    labeledField("Nom du compte") {
                        TextField("Compte courant", text: Bindable(model).accountName)
                    }
                    labeledField("Type") {
                        Picker("Type", selection: Bindable(model).accountType) {
                            ForEach(AccountType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BudgetColor.indigo)
                    }
                    labeledField("Solde actuel (CHF)") {
                        TextField("2'500.00", text: Bindable(model).openingBalanceText)
                            .keyboardType(.decimalPad)
                    }
                }
            }
        }
    }

    private var incomeStep: some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
            stepTitle("Revenus et logement", subtitle: "Facultatif — deux repères qui remplissent vos prévisions tout seuls.")
            GlassCard {
                VStack(alignment: .leading, spacing: BudgetSpacing.medium) {
                    labeledField("Salaire mensuel net (CHF, facultatif)") {
                        TextField("5'500.00", text: Bindable(model).salaryText)
                            .keyboardType(.decimalPad)
                    }
                    labeledField("Jour de versement") {
                        Picker("Jour de versement", selection: Bindable(model).salaryDay) {
                            ForEach(1...28, id: \.self) { day in
                                Text("Le \(day) du mois").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BudgetColor.indigo)
                    }
                    labeledField("Loyer ou charge de logement (CHF, facultatif)") {
                        TextField("1'800.00", text: Bindable(model).rentText)
                            .keyboardType(.decimalPad)
                    }
                    labeledField("Jour de paiement") {
                        Picker("Jour de paiement", selection: Bindable(model).rentDay) {
                            ForEach(1...28, id: \.self) { day in
                                Text("Le \(day) du mois").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(BudgetColor.indigo)
                    }
                    Text("Créés comme paiements réguliers — modifiables ou supprimables à tout moment.")
                        .font(BudgetFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: BudgetSpacing.small) {
            Button {
                saveErrorMessage = nil
                if model.step == .income {
                    finish()
                } else {
                    model.advance()
                }
            } label: {
                Text(model.step == .income ? "Créer mon ménage" : "Continuer")
                    .font(BudgetFont.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.budgetAccent, in: RoundedRectangle(cornerRadius: BudgetRadius.control))
                    .foregroundStyle(.white)
            }

            if model.step == .income {
                Button("Passer cette étape") {
                    saveErrorMessage = nil
                    model.skipIncome()
                    finish()
                }
                .font(BudgetFont.body)
                .foregroundStyle(BudgetColor.electricBlue)
                .accessibilityHint("Termine sans salaire ni loyer — vous pourrez les ajouter plus tard.")
            }

            if model.step == .welcome {
                Button {
                    appContainer.isDemoMode = true
                } label: {
                    Text("Explorer avec des données de démonstration")
                        .font(BudgetFont.body)
                        .foregroundStyle(BudgetColor.electricBlue)
                }
                .accessibilityHint("Ouvre l'app avec des données fictives, sans toucher à vos données réelles.")
            } else {
                Button("Retour") {
                    model.goBack()
                }
                .font(BudgetFont.body)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func finish() {
        do {
            try model.finish(
                context: modelContext,
                calendar: appContainer.calendar,
                now: appContainer.dateProvider.now
            )
            // RootView's @Query sees the new household and swaps to the app.
        } catch {
            saveErrorMessage = "L'enregistrement a échoué. Réessayez ; aucune donnée n'a été perdue."
        }
    }

    // MARK: - Building blocks

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
            Text(title)
                .font(BudgetFont.screenTitle)
            Text(subtitle)
                .font(BudgetFont.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeledField(_ label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: BudgetSpacing.micro) {
            Text(label)
                .font(BudgetFont.cardLabel)
                .foregroundStyle(.secondary)
            content()
        }
    }
}

#Preview("Onboarding") {
    let appContainer = try! AppContainer(inMemory: true)
    return OnboardingFlowView()
        .environment(appContainer)
        .modelContainer(appContainer.modelContainer)
}
