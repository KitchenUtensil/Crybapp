//
//  cryb_appApp.swift
//  cryb_app
//
//  Created by Ethan Nguyen on 6/19/25.
//

import SwiftUI

@main
struct cryb_appApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var houseService = HouseService()
    @StateObject private var choreService = ChoreService()
    @StateObject private var expenseService = ExpenseService()
    @StateObject private var noteService = NoteService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    DashboardView()
                        .environmentObject(authService)
                        .environmentObject(houseService)
                        .environmentObject(choreService)
                        .environmentObject(expenseService)
                        .environmentObject(noteService)
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
