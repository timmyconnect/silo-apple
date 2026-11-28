import SwiftUI

/// Displays a placeholder when a list or grid has no content.
struct EmptyStateView<Action: View>: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    @ViewBuilder let action: () -> Action

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder action: @escaping () -> Action
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    init(icon: String, title: String, subtitle: String? = nil) where Action == EmptyView {
        self.init(icon: icon, title: title, subtitle: subtitle) { EmptyView() }
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.siloOnSurface.opacity(0.3))

            Text(title)
                .font(.siloSubheadline)
                .foregroundColor(.siloOnSurface)

            if let subtitle {
                Text(subtitle)
                    .font(.siloCaption)
                    .foregroundColor(.siloSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SiloTheme.largePadding)
            }

            action()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
