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
                    .foregroundColor(.accent)

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
                    LoginTextField("Username", text: $username)
                }

                LoginTextField("Email", text: $email)

                LoginTextField("Password", text: $password, isSecure: true)

                if let error = viewModel.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
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
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isRegistering ? "Create Account" : "Login")
                            .fontWeight(.semibold)
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
                    .foregroundColor(.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(40)
        .frame(width: 380)
        .background(Color.card)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct LoginTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textFieldStyle(.plain)
        .padding(14)
        .background(Color.sidebar)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.border, lineWidth: 1)
        )
    }
}

#Preview {
    LoginView(viewModel: AuthViewModel())
        .frame(width: 500, height: 600)
        .background(Color.background)
}
