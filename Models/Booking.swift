import Foundation

/// Booking models a completed travel reservation in the app.
public struct Booking: Codable, Identifiable, Hashable {
    public let id: String
    public let listingId: String
    public let listingTitle: String
    public let listingImageURL: String
    public let location: String
    public let country: String
    public let checkInDate: Date
    public let checkOutDate: Date
    public let totalPrice: Double
    public let currency: String
    public let currencyIcon: String
    public let bookingDate: Date
    public let paymentMethod: String?
    
    public init(
        id: String = UUID().uuidString,
        listingId: String,
        listingTitle: String,
        listingImageURL: String,
        location: String,
        country: String,
        checkInDate: Date,
        checkOutDate: Date,
        totalPrice: Double,
        currency: String,
        currencyIcon: String,
        bookingDate: Date = Date(),
        paymentMethod: String? = "Credit Card"
    ) {
        self.id = id
        self.listingId = listingId
        self.listingTitle = listingTitle
        self.listingImageURL = listingImageURL
        self.location = location
        self.country = country
        self.checkInDate = checkInDate
        self.checkOutDate = checkOutDate
        self.totalPrice = totalPrice
        self.currency = currency
        self.currencyIcon = currencyIcon
        self.bookingDate = bookingDate
        self.paymentMethod = paymentMethod
    }
}
