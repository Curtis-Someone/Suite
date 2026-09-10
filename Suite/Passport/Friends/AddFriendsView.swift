import SwiftUI
import SwiftData

/// Full-screen sheet · Passport → Friends → "+". Two self-contained paths:
/// share your own invite (QR + code), or enter one you were sent. No contacts
/// UI this round.
struct AddFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]

    @State private var entered = ""
    @FocusState private var codeFieldFocused: Bool

    private var settings: UserSettings { settingsList.first ?? UserSettings.current(in: context) }
    private var myCode: String { FriendsService.myCode(settings) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 28) {
                    invitePanel
                    orDivider
                    enterCodePanel
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .task { _ = myCode; try? context.save() }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                SuiteIconView(icon: .close, size: 18, color: Theme.Palette.textPrimary)
                    .frame(width: 42, height: 42)
                    .overlay(Circle().strokeBorder(Theme.Palette.border))
            }
            .accessibilityLabel("Close")
            Text("Add friends")
                .font(.Suite.title).tracking(25 * -0.02)
                .foregroundStyle(Theme.Palette.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }

    // MARK: Your invite

    private var invitePanel: some View {
        VStack(spacing: 18) {
            Text("YOUR INVITE")
                .font(.Suite.label).tracking(1.6).textCase(.uppercase)
                .foregroundStyle(Theme.Palette.textTertiary)

            QRCodeView(text: FriendsService.inviteURL(code: myCode).absoluteString, size: 190)
                .padding(18)
                .background(Color(red: 0.039, green: 0.039, blue: 0.039),
                            in: RoundedRectangle(cornerRadius: Theme.Radius.card))

            Text(myCode)
                .font(.jetBrainsMono(20, .medium)).tracking(3)
                .foregroundStyle(Theme.Palette.textPrimary)

            ShareLink(item: FriendsService.shareMessage(code: myCode)) {
                HStack(spacing: 10) {
                    SuiteIconView(icon: .share, size: 17, color: Theme.Palette.onAccent)
                    Text("Share")
                        .font(.Suite.button)
                        .foregroundStyle(Theme.Palette.onAccent)
                }
                .frame(maxWidth: .infinity).frame(height: Theme.Size.cta)
                .background(Theme.Palette.accent, in: Capsule())
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Theme.Palette.surfaceSunken, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Theme.Palette.divider).frame(height: 1)
            Text("or").font(.Suite.bodyS).foregroundStyle(Theme.Palette.textTertiary)
            Rectangle().fill(Theme.Palette.divider).frame(height: 1)
        }
    }

    // MARK: Enter a code

    private var enterCodePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enter a code")
                .font(.Suite.bodyStrong)
                .foregroundStyle(Theme.Palette.textPrimary)
            Text("Got a link or code from a friend? Paste it here.")
                .font(.Suite.bodyS)
                .foregroundStyle(Theme.Palette.textSecondary)

            TextField("Friend code", text: $entered)
                .font(.jetBrainsMono(16, .medium))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($codeFieldFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .padding(.horizontal, 16)
                .frame(height: Theme.Size.field)
                .background(Theme.Palette.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.chip))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.chip)
                    .strokeBorder(codeFieldFocused ? Theme.Palette.accent : Theme.Palette.border,
                                  lineWidth: codeFieldFocused ? 1.6 : 1))

            SuiteButton(title: "Send request",
                        isEnabled: entered.trimmingCharacters(in: .whitespaces).count >= 6,
                        action: submit)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func submit() {
        guard FriendsService.addByCode(entered, in: context) != nil else { return }
        entered = ""
        codeFieldFocused = false
        dismiss()
    }
}
