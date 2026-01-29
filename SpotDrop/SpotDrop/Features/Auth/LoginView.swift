import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isRegistering = false

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("SpotDrop")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)

                Text(isRegistering ? "Create your account" : "Welcome back")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, 16)

            VStack(spacing: 16) {
                if isRegistering {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                }

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button(action: {
                    Task {
                        if isRegistering {
                            await viewModel.register(email: email, password: password, username: username)
                        } else {
                            await viewModel.login(email: email, password: password)
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isRegistering ? "Create Account" : "Login")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.isLoading)
            }

            Button(action: {
                isRegistering.toggle()
                viewModel.error = nil
            }) {
                Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Sign up")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 350)
        .background(Color.card)
        .cornerRadius(16)
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
        .frame(width: 400, height: 500)
        .background(Color.background)
}
