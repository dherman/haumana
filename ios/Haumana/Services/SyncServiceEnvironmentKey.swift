//
//  SyncServiceEnvironmentKey.swift
//  haumana
//
//  Created on 6/18/2025.
//

import SwiftUI

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: SyncService? = nil
}

extension EnvironmentValues {
    var syncService: SyncService? {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}