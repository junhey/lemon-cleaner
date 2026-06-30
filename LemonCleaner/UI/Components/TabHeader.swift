import SwiftUI

struct TabHeader: View {
    @Binding var selectedTab: PopupTab

    var body: some View {
        HStack(spacing: 20) {
            ForEach(PopupTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.title)
                            .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.accent : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }
}

enum PopupTab: String, CaseIterable, Identifiable {
    case freeUp
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .freeUp: return "FreeUp"
        case .system: return "System"
        }
    }
}
