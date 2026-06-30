import SwiftUI

struct PrivacyToggleGrid: View {
    @ObservedObject var privacyMonitor: PrivacyMonitorService

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(privacyMonitor.statuses) { status in
                PrivacyToggleCard(status: status) { enabled in
                    privacyMonitor.setEnabled(status.feature, enabled: enabled)
                }
            }
        }
    }
}

private struct PrivacyToggleCard: View {
    let status: PrivacyFeatureStatus
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: status.feature.iconName)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            Text(status.feature.title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
            HStack {
                Text(status.statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(status.isEnabled ? AppTheme.cleanGreen : AppTheme.warningOrange)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { status.isEnabled },
                    set: { onToggle($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
