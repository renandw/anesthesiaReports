//
//  SyncState.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//

import Foundation
import SwiftData

enum SyncScope: String {
    case user
    //outras pra vir
}

@Model
final class SyncState {

    @Attribute(.unique) var scopeRawValue: String

    var lastSyncAt: Date?
    var lastStatusChangedAt: Date?

    var scope: SyncScope {
        get { SyncScope(rawValue: scopeRawValue)! }
        set { scopeRawValue = newValue.rawValue }
    }

    init(
        scope: SyncScope,
        lastSyncAt: Date? = nil,
        lastStatusChangedAt: Date? = nil
    ) {
        self.scopeRawValue = scope.rawValue
        self.lastSyncAt = lastSyncAt
        self.lastStatusChangedAt = lastStatusChangedAt
    }
}
