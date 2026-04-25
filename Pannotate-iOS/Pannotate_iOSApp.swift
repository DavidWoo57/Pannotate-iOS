//
//  Pannotate_iOSApp.swift
//  Pannotate-iOS
//
//  Created by DavidWoo on 4/24/26.
//

import SwiftUI

@main
struct Pannotate_iOSApp: App {
    @AppStorage("appTheme") private var appThemeRawValue = AppTheme.dark.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(appTheme.colorScheme)
        }
    }

    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRawValue) ?? .system
    }
}
