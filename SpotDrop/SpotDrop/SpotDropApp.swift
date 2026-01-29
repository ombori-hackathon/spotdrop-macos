//
//  SpotDropApp.swift
//  SpotDrop
//

import SwiftUI

@main
struct SpotDropApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
