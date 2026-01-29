//
//  ContentView.swift
//  SpotDrop
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            if authViewModel.isAuthenticated {
                MainView()
                    .environmentObject(authViewModel)
            } else {
                LoginView(viewModel: authViewModel)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await authViewModel.checkAuth()
        }
    }
}

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("SpotDrop")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                .padding()
                .background(Color.card)

                SpotListView()
            }
            .navigationSplitViewColumnWidth(min: 300, ideal: 350)
        } detail: {
            VStack {
                Spacer()
                Image(systemName: "map")
                    .font(.system(size: 64))
                    .foregroundColor(.textSecondary)
                Text("Select a spot to view details")
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Text(authViewModel.user?.username ?? "User")
                    Divider()
                    Button("Logout") {
                        authViewModel.logout()
                    }
                } label: {
                    Image(systemName: "person.circle")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
