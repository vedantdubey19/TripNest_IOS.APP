import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") && email.contains(".") &&
        password.count >= 6 &&
        password == confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.12, blue: 0.25), Color(red: 0.05, green: 0.05, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative Blur Shapes
            GeometryReader { geo in
                Circle()
                    .fill(Color.indigo.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .position(x: 100, y: 150)
                
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .position(x: geo.size.width - 100, y: geo.size.height - 200)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header title
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Join TripNest to start explore & list stays")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 24)
                    
                    // Registration Card
                    VStack(spacing: 16) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Username")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                TextField("", text: $username, prompt: Text("Your username"))
                                    .foregroundColor(.white)
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("", text: $email, prompt: Text("example@email.com"))
                                    .foregroundColor(.white)
                                    #if os(iOS)
                                    .textInputAutocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    #endif
                                    .autocorrectionDisabled()
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                SecureField("", text: $password, prompt: Text("At least 6 characters"))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Confirm Password")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.rotation")
                                    .foregroundColor(.gray)
                                SecureField("", text: $confirmPassword, prompt: Text("Repeat password"))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match.")
                                    .font(.caption2)
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Register Button
                        Button(action: {
                            Task {
                                await authViewModel.register(username: username, email: email, password: password)
                            }
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 8)
                                }
                                
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: isFormValid ? [.blue, .indigo] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(isFormValid ? .white : .white.opacity(0.5))
                            .cornerRadius(12)
                            .shadow(color: isFormValid ? Color.blue.opacity(0.3) : Color.clear, radius: 10, y: 5)
                        }
                        .disabled(!isFormValid || authViewModel.isLoading)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.04))
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    // Back to Login link
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            Text("Log in here")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .font(.footnote)
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Registration Error", isPresented: $authViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authViewModel.errorMessage ?? "Failed to create account. Please try again.")
        }
    }
}

#if os(iOS)
#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}
#endif
