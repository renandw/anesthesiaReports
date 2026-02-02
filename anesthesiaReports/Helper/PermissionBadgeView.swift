import SwiftUI

struct PermissionBadgeView: View {
    let permission: PatientPermission
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
    let permission: PatientPermission

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

struct RoleInlineBadgeView: View {
    let role: PatientRole
    let compact: Bool

    init(role: PatientRole, compact: Bool = false) {
        self.role = role
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: role.iconName)
                .font(compact ? .caption2 : .caption)
            if !compact {
                Text(role.displayName)
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(role.color)
        .clipShape(Capsule())
    }
}
