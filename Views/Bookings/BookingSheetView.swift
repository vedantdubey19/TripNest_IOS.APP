import SwiftUI

struct BookingSheetView: View {
    let listing: Listing
    
    @EnvironmentObject var listViewModel: ListingListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var checkInDate = Date()
    @State private var checkOutDate = Date().addingTimeInterval(86400 * 2) // Default 2 nights
    @State private var selectedCurrency = "USD"
    @State private var bookingConfirmed = false
    
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
                        VStack(alignment: .leading, spacing: 22) {
                            
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
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Proceed to Book
                    Button(action: {
                        listViewModel.addBooking(
                            listing: listing,
                            checkIn: checkInDate,
                            checkOut: checkOutDate,
                            totalPrice: totalAmount,
                            currency: activeCurrency.id,
                            currencyIcon: activeCurrency.icon
                        )
                        withAnimation(.spring()) {
                            bookingConfirmed = true
                        }
                    }) {
                        Text("Confirm Reservation")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
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
