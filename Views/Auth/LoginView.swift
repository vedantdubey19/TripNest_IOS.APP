import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showRegisterView = false
    
    private var isInputValid: Bool {
        email.contains("@") && email.contains(".") && password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.12, blue: 0.25), Color(red: 0.05, green: 0.05, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating Decorative Blurs
                GeometryReader { geo in
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .position(x: 50, y: 100)
                    
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .position(x: geo.size.width - 50, y: geo.size.height - 150)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Logo & Brand Header
                        VStack(spacing: 12) {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                                .padding(.bottom, 8)
                            
                            Text("TripNest")
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your gateway to unforgettable stays")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 40)
                        
                        // Glassmorphic Card
                        VStack(spacing: 20) {
                            Text("Welcome Back")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 4)
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
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
                            VStack(alignment: .leading, spacing: 8) {
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
                            
                            // Login Button
                            Button(action: {
                                Task {
                                    await authViewModel.login(email: email, password: password)
                                }
                            }) {
                                HStack {
                                    if authViewModel.isLoading {
                                        ProgressView()
                                            .tint(.white)
                                            .padding(.trailing, 8)
                                    }
                                    
                                    Text("Log In")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: isInputValid ? [.blue, .indigo] : [.gray.opacity(0.3), .gray.opacity(0.2)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(isInputValid ? .white : .white.opacity(0.5))
                                .cornerRadius(12)
                                .shadow(color: isInputValid ? Color.blue.opacity(0.3) : Color.clear, radius: 10, y: 5)
                            }
                            .disabled(!isInputValid || authViewModel.isLoading)
                            .scaleEffect(isInputValid ? 1.0 : 0.98)
                            .animation(.easeOut(duration: 0.2), value: isInputValid)
                            
                            // Quick Sign Up Button (For testing and rapid account creation)
                            Button(action: {
                                Task {
                                    let randId = Int.random(in: 100...999)
                                    let randUsername = "Explorer_\(randId)"
                                    let randEmail = "explorer\(randId)@tripnest.com"
                                    await authViewModel.register(username: randUsername, email: randEmail, password: "password123")
                                }
                            }) {
                                HStack {
                                    Text("Quick Sign Up (New User)")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(authViewModel.isLoading)
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
                        
                        // Register Link
                        Button(action: { showRegisterView = true }) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                Text("Register here")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            .font(.footnote)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationDestination(isPresented: $showRegisterView) {
                RegisterView()
            }
            .alert("Authentication Error", isPresented: $authViewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.errorMessage ?? "Failed to log in. Please try again.")
            }
        }
    }
}

#if os(iOS)
#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
#endif
