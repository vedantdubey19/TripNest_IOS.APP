import SwiftUI

struct BookingHistoryView: View {
    @EnvironmentObject var listViewModel: ListingListViewModel
    
    var body: some View {
        ZStack {
            // Theme dynamic Background
            listViewModel.themeBg
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                if listViewModel.bookings.isEmpty {
                    VStack(spacing: 20) {
                        Spacer(minLength: 120)
                        
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.04))
                                .frame(width: 100, height: 100)
                                .blur(radius: 8)
                            
                            Image(systemName: "suitcase.rolling.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue.opacity(0.5))
                        }
                        
                        Text("No Bookings Found")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(listViewModel.themeText)
                        
                        Text("When you reserve a stay, your booking summary and travel history will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineSpacing(4)
                    }
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(listViewModel.bookings) { booking in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 14) {
                                    // Image Thumbnail
                                    AsyncImage(url: URL(string: booking.listingImageURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.white.opacity(0.05)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(14)
                                    .clipped()
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("\(booking.location), \(booking.country)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            
                                            Spacer()
                                            
                                            // Booking Status Tag
                                            let isUpcoming = booking.checkInDate > Date()
                                            Text(isUpcoming ? "Upcoming" : "Completed")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(isUpcoming ? .blue : .green)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(isUpcoming ? Color.blue.opacity(0.12) : Color.green.opacity(0.12))
                                                .cornerRadius(8)
                                        }
                                        
                                        Text(booking.listingTitle)
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(listViewModel.themeText)
                                            .lineLimit(1)
                                        
                                        Text("\(booking.checkInDate.formatted(date: .abbreviated, time: .omitted)) - \(booking.checkOutDate.formatted(date: .abbreviated, time: .omitted))")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("RESERVATION ID")
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundColor(.gray)
                                        Text(booking.id.prefix(8).uppercased())
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(alignment: .bottom, spacing: 2) {
                                        Text("Total Paid:")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text("\(booking.currencyIcon)\(Int(booking.totalPrice))")
                                            .font(.headline)
                                            .fontWeight(.black)
                                            .foregroundColor(listViewModel.themeText)
                                        Text(booking.currency)
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 2)
                                    }
                                }
                            }
                            .padding(14)
                            .background(listViewModel.themeCardBg)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(listViewModel.themeBorder, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Booking History")
        .navigationBarTitleDisplayModeInline()
    }
}

#if os(iOS)
#Preview {
    let mockListVM = ListingListViewModel()
    mockListVM.bookings = [
        Booking(
            listingId: "1",
            listingTitle: "Taj Mahal View Retreat",
            listingImageURL: "https://images.unsplash.com/photo-1564507592333-c60657eea523?auto=format&fit=crop&w=800&q=80",
            location: "Agra",
            country: "India",
            checkInDate: Date().addingTimeInterval(86400 * 5),
            checkOutDate: Date().addingTimeInterval(86400 * 7),
            totalPrice: 240.0,
            currency: "USD",
            currencyIcon: "$"
        )
    ]
    return NavigationStack {
        BookingHistoryView()
            .environmentObject(mockListVM)
            .preferredColorScheme(.dark)
    }
}
#endif
