//
//  AppConstants.swift
//  haumana
//
//  Created on 6/3/2025.
//

import Foundation
import SwiftUI

enum AppConstants {
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
    
    // Category Colors
    static let oliColor = Color.blue
    static let meleColor = Color.purple
    
    // AWS Configuration
    static let apiEndpoint = "https://vageu42qbg.execute-api.us-west-2.amazonaws.com/prod"
}