//
//  AppConstants.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation

enum AppConstants {
    static let appVersion = "0.2.0"
    static let appName = "Haumana"
    
    // Practice Settings
    static let practiceHistoryDaysThreshold = 7
    static let recentSessionsLimit = 10
    
    // Practice Selection Weights
    static let priority1Weight = 3  // Favorites not practiced in 7+ days
    static let priority2Weight = 2  // Non-favorites not practiced in 7+ days
    static let priority3Weight = 1  // Recently practiced pieces
    
    // UI Constants
    static let splashScreenDuration: TimeInterval = 3.0
    static let animationDuration: TimeInterval = 0.3
}