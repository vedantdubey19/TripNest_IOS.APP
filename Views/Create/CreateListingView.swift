import SwiftUI
import PhotosUI

@MainActor
struct CreateListingView: View {
    // Optional listing passed when editing
    var editingListing: Listing? = nil
    
    @EnvironmentObject var listViewModel: ListingListViewModel
    @EnvironmentObject var detailViewModel: ListingDetailViewModel // Only present when editing
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CreateListingViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil
    
    private var isEditMode: Bool {
        editingListing != nil
    }
    
    var body: some View {
        let selectedImageData = viewModel.selectedImageData
        let currentImageUrl = viewModel.currentImageUrl
        let isLoading = viewModel.isLoading
        let isFormValid = viewModel.isFormValid
        let errorMessage = viewModel.errorMessage
        
        NavigationStack {
            ZStack {
                // Background dark colors
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Image Picker Box Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Listing Image")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack {
                                    #if os(macOS)
                                    let maybeImage = (selectedImageData).flatMap { NSImage(data: $0) }.map { Image(nsImage: $0) }
                                    #else
                                    let maybeImage = (selectedImageData).flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) }
                                    #endif
                                    
                                    if let image = maybeImage {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 200)
                                            .cornerRadius(16)
                                            .clipped()
                                    } else if let existingUrl = currentImageUrl {
                                        // Display current image when editing
                                        AsyncImage(url: URL(string: existingUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 200)
                                                .cornerRadius(16)
                                                .clipped()
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    } else {
                                        // Placeholder for selecting image
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 36))
                                                .foregroundColor(.blue)
                                            
                                            Text("Tap to select listing photo")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                        .background(Color.white.opacity(0.03))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [6]))
                                        )
                                    }
                                }
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        viewModel.selectedImageData = data
                                    }
                                }
                            }
                        }
                        
                        // Text form fields
                        VStack(spacing: 18) {
                            // Title field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Title")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                TextField("", text: $viewModel.title, prompt: Text("e.g. Cozy Forest Cabin"))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                            }
                            
                            // Description field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                TextField("", text: $viewModel.description, prompt: Text("Describe the unique amenities of this stay..."), axis: .vertical)
                                    .lineLimit(3...6)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                            }
                            
                            // Price field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Price per Night ($)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                TextField("", text: $viewModel.priceString, prompt: Text("e.g. 150"))
                                    .foregroundColor(.white)
                                    #if os(iOS)
                                    .keyboardType(.decimalPad)
                                    #endif
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                            }
                            
                            // Location field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("City / Location")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                TextField("", text: $viewModel.location, prompt: Text("e.g. Seattle, WA"))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                            }
                            
                            // Country field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Country")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                TextField("", text: $viewModel.country, prompt: Text("e.g. USA"))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
                
                // Loading Overlay
                if isLoading {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    ProgressView("Uploading content...")
                        .tint(.blue)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                }
            }
            .navigationTitle(isEditMode ? "Edit Stay" : "List Your Nest")
            .navigationBarTitleDisplayModeInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.submitListing(isEditing: isEditMode, editListingId: editingListing?.id)
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(isFormValid ? .blue : .gray)
                    .disabled(!isFormValid || isLoading)
                }
            }
            .onAppear {
                if let listing = editingListing {
                    viewModel.setupForEditing(listing)
                }
            }
            .onChange(of: viewModel.isSuccess) { _, success in
                if success {
                    Task {
                        // Refresh appropriate view model feeds
                        if isEditMode {
                            // If in detail view, trigger reload
                            if let id = editingListing?.id {
                                await detailViewModel.fetchListingDetails(id: id)
                            }
                        }
                        // Refresh home listing grid
                        await listViewModel.fetchListings()
                        dismiss()
                    }
                }
            }
            .alert("Submission Failed", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred while saving your listing.")
            }
        }
    }
}

#if os(iOS)
#Preview {
    CreateListingView()
        .environmentObject(ListingListViewModel())
        .preferredColorScheme(.dark)
}
#endif
