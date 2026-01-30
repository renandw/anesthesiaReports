import SwiftUI

struct PermissionBadgeView: View {
    let permission: Permission
    let isUpdating: Bool

    var body: some View {
        ZStack {
            Image(systemName: permission.iconName)
                .foregroundStyle(permission.color)
                .font(.title3)

            if isUpdating {
                ProgressView()
                    .scaleEffect(0.6)
            }
        }
    }
}

struct PermissionInlineBadgeView: View {
    let permission: Permission

    var body: some View {
        Text(permission.displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(permission.color)
            .clipShape(Capsule())
    }
}
