//
//  FocusModeApp.swift
//  FocusMode
//
//  Created by Andres Diaz on 4/4/26.
//

import SwiftUI

@main
struct FocusModeApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            ContentView()
            #else
            if AppDelegate.hasAccessibilityPermission() && AppDelegate.hasFullDiskAccess() {
                ContentView()
            } else {
                PermissionsView()
            }
            #endif
        }
        .defaultSize(width: 360, height: 560)
        .windowResizability(.contentSize)
    }
}
