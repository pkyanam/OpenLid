import SwiftUI

/// Renders an agent's brand icon from the asset catalog, dimmed when the agent is idle.
/// Icons authored as template images tint to the label color; colored brand logos keep
/// their color and simply fade when idle.
struct AgentIconView: View {
    let iconName: String
    let isWorking: Bool
    var size: CGFloat = 16

    var body: some View {
        Image(iconName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(isWorking ? Color.primary : Color.secondary)
            .opacity(isWorking ? 1.0 : 0.5)
    }
}

/// Small rounded "pill" button used for the Pause quick actions (30 min / 1 hour).
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.22 : 0.12))
            )
            .contentShape(Rectangle())
    }
}

/// A full-width menu-style row (used for Settings… / Quit) with a trailing shortcut hint.
struct MenuActionRow: View {
    let title: String
    let shortcut: String
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(shortcut).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovering ? Color.accentColor.opacity(0.85) : .clear)
            )
            .foregroundStyle(hovering ? Color.white : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
