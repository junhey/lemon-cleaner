import SwiftUI

struct TabHeader: View {
    @Binding var selectedTab: PopupTab

    var body: some View {
        HStack(spacing: 24) {
            ForEach(PopupTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.title)
                            .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.lemonAccent : .clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
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
