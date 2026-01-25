@Model
final class SyncState {

    @Attribute(.unique) var scope: String // ex: "user"

    var lastSyncAt: Date?
    var lastStatusChangedAt: Date?

    init(scope: String,
         lastSyncAt: Date? = nil,
         lastStatusChangedAt: Date? = nil) {
        self.scope = scope
        self.lastSyncAt = lastSyncAt
        self.lastStatusChangedAt = lastStatusChangedAt
    }
}