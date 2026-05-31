import SwiftUI
import LocalAuthentication

struct BookingSheetView: View {
    let listing: Listing
    
    @EnvironmentObject var listViewModel: ListingListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var checkInDate = Date()
    @State private var checkOutDate = Date().addingTimeInterval(86400 * 2) // Default 2 nights
    @State private var selectedCurrency = "USD"
    @State private var bookingConfirmed = false
    
    // Payment Options State
    enum PaymentMethod: String, CaseIterable, Identifiable {
        case creditCard = "Credit Card"
        case applePay = "Apple Pay"
        case payPal = "PayPal"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .creditCard: return "creditcard.fill"
            case .applePay: return "apple.logo"
            case .payPal: return "p.circle.fill"
            }
        }
    }
    
    @State private var selectedPaymentMethod: PaymentMethod = .creditCard
    
    // Credit Card Form Fields
    @State private var cardNumber = ""
    @State private var cardName = ""
    @State private var cardExpiry = ""
    @State private var cardCVV = ""
    
    // Simulated Sheet States
    @State private var showApplePaySheet = false
    @State private var showPayPalSheet = false
    @State private var paypalEmail = ""
    @State private var paypalPassword = ""
    @State private var isPaypalLoggingIn = false
    
    // Biometric Scanner Animation
    @State private var applePayScanning = false
    @State private var applePayAuthenticated = false
    
    // Secure Processing States
    @State private var isProcessingPayment = false
    @State private var currentProcessingStep = ""
    
    // Currency conversions relative to USD base
    private let currencies = [
        CurrencyOption(id: "USD", name: "US Dollar", icon: "$", rate: 1.0),
        CurrencyOption(id: "EUR", name: "Euro", icon: "€", rate: 0.92),
        CurrencyOption(id: "INR", name: "Indian Rupee", icon: "₹", rate: 83.0),
        CurrencyOption(id: "GBP", name: "British Pound", icon: "£", rate: 0.79),
        CurrencyOption(id: "JPY", name: "Japanese Yen", icon: "¥", rate: 155.0)
    ]
    
    struct CurrencyOption: Identifiable {
        let id: String
        let name: String
        let icon: String
        let rate: Double
    }
    
    // Computes total night count
    private var nightCount: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: checkInDate)
        let end = calendar.startOfDay(for: checkOutDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, components.day ?? 1)
    }
    
    // Find active currency option
    private var activeCurrency: CurrencyOption {
        currencies.first(where: { $0.id == selectedCurrency }) ?? currencies[0]
    }
    
    // Computes final converted price
    private var totalAmount: Double {
        let rawTotal = listing.price * Double(nightCount)
        return rawTotal * activeCurrency.rate
    }
    
    // Card formatting helpers
    private func formatCardNumber(_ value: String) {
        let clean = value.filter { $0.isNumber }
        let limited = String(clean.prefix(16))
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        cardNumber = formatted
    }
    
    private func formatExpiry(_ value: String) {
        let clean = value.filter { $0.isNumber }
        let limited = String(clean.prefix(4))
        if limited.count > 2 {
            let month = String(limited.prefix(2))
            let year = String(limited.suffix(limited.count - 2))
            cardExpiry = "\(month)/\(year)"
        } else {
            cardExpiry = limited
        }
    }
    
    private func formatCVV(_ value: String) {
        let clean = value.filter { $0.isNumber }
        cardCVV = String(clean.prefix(4))
    }
    
    // Credit card validator
    private var isCreditCardValid: Bool {
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        let cleanExpiry = cardExpiry.replacingOccurrences(of: "/", with: "")
        return cleanNumber.count == 16 &&
               !cardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               cleanExpiry.count == 4 &&
               (cardCVV.count == 3 || cardCVV.count == 4)
    }
    
    // Detects Card Brand based on card number
    private var cardBrand: String {
        guard let first = cardNumber.replacingOccurrences(of: " ", with: "").first else { return "Generic" }
        switch first {
        case "4": return "Visa"
        case "5": return "Mastercard"
        case "3": return "Amex"
        case "6": return "Discover"
        default: return "Generic"
        }
    }
    
    // Visual Brand icon
    private var cardBrandIcon: String {
        switch cardBrand {
        case "Visa": return "creditcard.fill"
        case "Mastercard": return "creditcard.circle.fill"
        case "Amex": return "creditcard.fill"
        default: return "creditcard"
        }
    }
    
    // Live virtual card background gradient based on network type
    private var cardGradient: LinearGradient {
        switch cardBrand {
        case "Visa":
            return LinearGradient(
                colors: [Color(red: 0.1, green: 0.25, blue: 0.6), Color(red: 0.05, green: 0.1, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Mastercard":
            return LinearGradient(
                colors: [Color(red: 0.8, green: 0.35, blue: 0.1), Color(red: 0.45, green: 0.1, blue: 0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Amex":
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.5, blue: 0.6), Color(red: 0.08, green: 0.25, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.2, green: 0.2, blue: 0.28), Color(red: 0.08, green: 0.08, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Run secure transaction verification
    private func triggerPaymentProcessing() {
        isProcessingPayment = true
        
        let steps = [
            "Encrypting transaction details...",
            "Initiating connection with payment network...",
            "Routing request to issuing bank...",
            "Authorized! Finalizing accommodation reservation..."
        ]
        
        var currentDelay: Double = 0.0
        for i in 0..<steps.count {
            let step = steps[i]
            DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentProcessingStep = step
                }
            }
            currentDelay += 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
            // Commit Booking
            listViewModel.addBooking(
                listing: listing,
                checkIn: checkInDate,
                checkOut: checkOutDate,
                totalPrice: totalAmount,
                currency: activeCurrency.id,
                currencyIcon: activeCurrency.icon,
                paymentMethod: selectedPaymentMethod.rawValue
            )
            
            withAnimation(.spring()) {
                isProcessingPayment = false
                bookingConfirmed = true
            }
        }
    }
    
    // Request biometric FaceID/TouchID or device passcode authentication
    private func triggerLocalAuthentication() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            applePayScanning = true
            let reason = "Confirm stay reservation at \(listing.title) via Apple Pay"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    self.applePayScanning = false
                    if success {
                        withAnimation(.spring()) {
                            self.applePayAuthenticated = true
                        }
                        // Dismiss verification sheet and trigger transaction processing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.showApplePaySheet = false
                            self.applePayAuthenticated = false
                            self.triggerPaymentProcessing()
                        }
                    } else {
                        print("Biometric/Device authentication failed: \(authenticationError?.localizedDescription ?? "unknown")")
                    }
                }
            }
        } else {
            // LocalAuthentication unavailable on current system/sim; run automated high-fidelity biometric scan simulation
            print("LocalAuthentication unavailable: \(error?.localizedDescription ?? "unknown")")
            applePayScanning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.applePayScanning = false
                withAnimation(.spring()) {
                    self.applePayAuthenticated = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.showApplePaySheet = false
                    self.applePayAuthenticated = false
                    self.triggerPaymentProcessing()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Theme Dark Background
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            if bookingConfirmed {
                // Success screen
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Success glowing checkmark
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .shadow(color: Color.green.opacity(0.4), radius: 12)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Booking Confirmed!")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Your nest at \(listing.title) is ready for you.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Detailed reservation summary card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Stay Location:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(listing.location), \(listing.country)")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Check-In:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(checkInDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Check-Out:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(checkOutDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Text("Paid via:")
                                .foregroundColor(.gray)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: selectedPaymentMethod.icon)
                                    .foregroundColor(.blue)
                                Text(selectedPaymentMethod.rawValue)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        HStack {
                            Text("Paid Amount:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(activeCurrency.icon)\(Int(totalAmount)) \(activeCurrency.id)")
                                .font(.headline)
                                .fontWeight(.black)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
            } else {
                // Booking Config Interface
                VStack(alignment: .leading, spacing: 0) {
                    // Header title
                    HStack {
                        Text("Book Nest")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            
                            // Date Selection Card
                            VStack(spacing: 16) {
                                DatePicker(
                                    "Check-In Date",
                                    selection: $checkInDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .tint(.blue)
                                .foregroundColor(.white)
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                DatePicker(
                                    "Check-Out Date",
                                    selection: $checkOutDate,
                                    in: checkInDate.addingTimeInterval(86400)...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .tint(.blue)
                                .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                            )
                            
                            // Currency Option segment
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Payment Currency")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(currencies) { currency in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.25)) {
                                                    selectedCurrency = currency.id
                                                }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text(currency.icon)
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(selectedCurrency == currency.id ? .white : .blue)
                                                    Text(currency.id)
                                                        .fontWeight(.bold)
                                                        .font(.footnote)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedCurrency == currency.id ?
                                                    LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                                    LinearGradient(colors: [Color.white.opacity(0.04)], startPoint: .leading, endPoint: .trailing)
                                                )
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedCurrency == currency.id ? Color.blue.opacity(0.3) : Color.white.opacity(0.04), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Pricing Detail Summary Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Pricing Summary")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("\(activeCurrency.icon)\(Int(listing.price * activeCurrency.rate)) / night")
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Text("x \(nightCount) nights")
                                            .foregroundColor(.white)
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    HStack {
                                        Text("Total Amount")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(activeCurrency.icon)\(Int(totalAmount)) \(activeCurrency.id)")
                                            .font(.title3)
                                            .fontWeight(.black)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            
                            // Payment Options selector Segment
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select Payment Method")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    ForEach(PaymentMethod.allCases) { method in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedPaymentMethod = method
                                            }
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: method.icon)
                                                    .font(.title2)
                                                    .foregroundColor(selectedPaymentMethod == method ? .white : .blue)
                                                Text(method.rawValue)
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                selectedPaymentMethod == method ?
                                                LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                                LinearGradient(colors: [Color.white.opacity(0.03)], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(selectedPaymentMethod == method ? Color.blue.opacity(0.4) : Color.white.opacity(0.04), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Contextual Payment Option form
                            switch selectedPaymentMethod {
                            case .creditCard:
                                VStack(alignment: .leading, spacing: 16) {
                                    // Visual card display mockup
                                    VStack(alignment: .leading, spacing: 20) {
                                        HStack {
                                            Text(cardBrand)
                                                .font(.headline)
                                                .italic()
                                                .foregroundColor(.white.opacity(0.8))
                                            Spacer()
                                            Image(systemName: cardBrandIcon)
                                                .font(.title)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(cardNumber.isEmpty ? "•••• •••• •••• ••••" : cardNumber)
                                            .font(.system(.title3, design: .monospaced))
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("CARDHOLDER")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white.opacity(0.5))
                                                Text(cardName.isEmpty ? "YOUR NAME" : cardName.uppercased())
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("EXPIRES")
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.white.opacity(0.5))
                                                Text(cardExpiry.isEmpty ? "MM/YY" : cardExpiry)
                                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .frame(height: 180)
                                    .background(cardGradient)
                                    .cornerRadius(18)
                                    .shadow(color: Color.blue.opacity(0.1), radius: 10, y: 5)
                                    
                                    // Card Inputs
                                    VStack(spacing: 12) {
                                        TextField("Cardholder Name", text: $cardName)
                                            .padding()
                                            .background(Color.white.opacity(0.02))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                        
                                        TextField("Card Number", text: $cardNumber)
                                            .numberPadKeyboard()
                                            .onChange(of: cardNumber) { _, newValue in
                                                formatCardNumber(newValue)
                                            }
                                            .padding()
                                            .background(Color.white.opacity(0.02))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                        
                                        HStack(spacing: 12) {
                                            TextField("Expiry (MM/YY)", text: $cardExpiry)
                                                .numberPadKeyboard()
                                                .onChange(of: cardExpiry) { _, newValue in
                                                    formatExpiry(newValue)
                                                }
                                                .padding()
                                                .background(Color.white.opacity(0.02))
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                            
                                            SecureField("CVV", text: $cardCVV)
                                                .numberPadKeyboard()
                                                .onChange(of: cardCVV) { _, newValue in
                                                    formatCVV(newValue)
                                                }
                                                .padding()
                                                .background(Color.white.opacity(0.02))
                                                .foregroundColor(.white)
                                                .cornerRadius(12)
                                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
                                        }
                                    }
                                }
                                
                            case .applePay:
                                VStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.02))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                            )
                                        
                                        VStack(spacing: 14) {
                                            Image(systemName: "apple.logo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                            
                                            Text("Apple Pay Express Booking")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text("Pay swiftly using your default Apple Wallet cards securely with biometrics validation.")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 24)
                                        }
                                        .padding(.vertical, 24)
                                    }
                                    
                                    Button(action: {
                                        showApplePaySheet = true
                                        // Wait briefly for slide animation, then prompt biometric verification
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            triggerLocalAuthentication()
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "apple.logo")
                                                .font(.title3)
                                            Text("Pay with Pay")
                                                .font(.system(.headline, design: .rounded))
                                                .fontWeight(.bold)
                                        }
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: Color.black.opacity(0.3), radius: 6)
                                    }
                                }
                                
                            case .payPal:
                                VStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.02))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                            )
                                        
                                        VStack(spacing: 12) {
                                            Image(systemName: "p.circle.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(Color(red: 0.0, green: 0.45, blue: 0.74))
                                            
                                            Text("PayPal Checkout")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text("Authorize stay checkout by logging into your secure PayPal digital wallet.")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 24)
                                        }
                                        .padding(.vertical, 24)
                                    }
                                    
                                    Button(action: { showPayPalSheet = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "p.circle.fill")
                                                .foregroundColor(Color(red: 0.0, green: 0.45, blue: 0.74))
                                            Text("PayPal")
                                                .font(.system(.headline, design: .rounded))
                                                .fontWeight(.black)
                                                .italic()
                                                .foregroundColor(Color(red: 0.0, green: 0.18, blue: 0.43))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color(red: 1.0, green: 0.77, blue: 0.19))
                                        .cornerRadius(14)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    
                    Spacer()
                    
                    // Final confirmation booking button (Only shown/enabled for credit card form or general backup confirm)
                    if selectedPaymentMethod == .creditCard {
                        Button(action: {
                            triggerPaymentProcessing()
                        }) {
                            Text("Confirm Reservation")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isCreditCardValid ?
                                    AnyView(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)) :
                                    AnyView(Color.gray.opacity(0.2))
                                )
                                .cornerRadius(14)
                                .shadow(color: isCreditCardValid ? Color.blue.opacity(0.3) : Color.clear, radius: 10, y: 5)
                        }
                        .disabled(!isCreditCardValid)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            // Fullscreen Processing secure spinner overlay
            if isProcessingPayment {
                ZStack {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(2.0)
                            .padding(.bottom, 12)
                        
                        Text("Processing Stay Payment")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(currentProcessingStep)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(height: 20)
                            .padding(.horizontal, 40)
                    }
                }
                .transition(.opacity)
            }
            
            // Apple Pay simulated bottom sheet popup
            if showApplePaySheet {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showApplePaySheet = false
                        }
                    
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.headline)
                            Text("Pay")
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: { showApplePaySheet = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Summary info
                        VStack(spacing: 12) {
                            HStack {
                                Text("STAY")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(listing.title)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            
                            HStack {
                                Text("CARD")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.blue)
                                Text("Apple Card (•••• 1024)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("CONTACT")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("buyer@tripnest.com")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("TOTAL AMOUNT")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(activeCurrency.icon)\(Int(totalAmount)) \(activeCurrency.id)")
                                    .font(.title3)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Simulated Biometrics (Face ID) Scanner
                        VStack(spacing: 14) {
                            if applePayAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 54))
                                    .foregroundColor(.green)
                                    .scaleEffect(1.2)
                                Text("Done")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 54))
                                    .foregroundColor(.blue)
                                    .opacity(applePayScanning ? 0.3 : 1.0)
                                    .scaleEffect(applePayScanning ? 0.9 : 1.1)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: applePayScanning)
                                
                                Text("Double-click to Pay with Face ID")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 12)
                        
                        // Trigger Face ID Verification / Fallback retry
                        Button(action: {
                            triggerLocalAuthentication()
                        }) {
                            Text(applePayScanning ? "Authenticating..." : "Use Face ID / Passcode")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 24)
                    }
                    .background(
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                            .ignoresSafeArea()
                    )
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
            
            // PayPal simulated WebView sheet popup
            if showPayPalSheet {
                ZStack {
                    Color.black.opacity(0.8)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // PayPal sandbox frame
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.footnote)
                                    .foregroundColor(.green)
                                Text("paypal.com/checkout")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Spacer()
                                Button(action: { showPayPalSheet = false }) {
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            
                            VStack(spacing: 20) {
                                Image(systemName: "p.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(red: 0.0, green: 0.45, blue: 0.74))
                                
                                Text("Log in to PayPal Sandbox")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Text("Amount due: \(activeCurrency.icon)\(Int(totalAmount)) \(activeCurrency.id)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                VStack(spacing: 12) {
                                    TextField("Email Address", text: $paypalEmail)
                                        .padding()
                                        .background(Color.black.opacity(0.05))
                                        .cornerRadius(10)
                                        .foregroundColor(.black)
                                    
                                    SecureField("Password", text: $paypalPassword)
                                        .padding()
                                        .background(Color.black.opacity(0.05))
                                        .cornerRadius(10)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal)
                                
                                Button(action: {
                                    isPaypalLoggingIn = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        isPaypalLoggingIn = false
                                        showPayPalSheet = false
                                        triggerPaymentProcessing()
                                    }
                                }) {
                                    HStack {
                                        if isPaypalLoggingIn {
                                            ProgressView()
                                                .tint(.white)
                                                .padding(.trailing, 8)
                                        }
                                        Text("Log In & Authorize Payment")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(red: 0.0, green: 0.18, blue: 0.43))
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .disabled(paypalEmail.isEmpty || paypalPassword.isEmpty || isPaypalLoggingIn)
                            }
                            .padding(.vertical, 32)
                            .background(Color.white)
                        }
                        .cornerRadius(20)
                        .shadow(radius: 12)
                        .padding(.horizontal, 24)
                    }
                }
                .transition(.opacity)
            }
        }
    }
}

#if os(iOS)
#Preview {
    let mockListVM = ListingListViewModel()
    return BookingSheetView(
        listing: Listing(
            id: "1",
            title: "Taj Mahal View Retreat",
            description: "Agra, India stay.",
            price: 120.0,
            location: "Agra",
            country: "India",
            image: Listing.ListingImage(url: "", filename: ""),
            owner: User(id: "1", username: "Host", email: ""),
            reviews: []
        )
    )
    .environmentObject(mockListVM)
    .preferredColorScheme(.dark)
}
#endif

extension View {
    @ViewBuilder
    func numberPadKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }
}

