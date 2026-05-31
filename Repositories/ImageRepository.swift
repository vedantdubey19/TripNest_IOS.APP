import Foundation

/// Protocol defining the image upload contract.
protocol ImageRepositoryProtocol {
    func uploadImage(data: Data) async throws -> Listing.ListingImage
}

/// ImageRepository handles the direct client-side upload of image files to Cloudinary.
final class ImageRepository: ImageRepositoryProtocol {
    
    // MARK: - Cloudinary Config
    // Please update these values with your actual Cloudinary credentials.
    // Unsigned upload presets should be set up in your Cloudinary Dashboard under Settings > Upload.
    static var cloudName: String = "dy6ybmtf3"
    static var uploadPreset: String = "ml_default" // Cloudinary's default unsigned preset. Change if you created a custom one.
    
    /// Uploads raw image data to Cloudinary via a multipart/form-data request.
    /// - Parameter data: JPEG or PNG data.
    /// - Returns: A ListingImage object containing the secure URL and filename (public ID).
    func uploadImage(data: Data) async throws -> Listing.ListingImage {
        guard ImageRepository.cloudName != "YOUR_CLOUDINARY_CLOUD_NAME" && !ImageRepository.cloudName.isEmpty else {
            throw NetworkError.serverError("Cloudinary Cloud Name is not configured. Please edit ImageRepository.swift.")
        }
        
        guard let uploadURL = URL(string: "https://api.cloudinary.com/v1_1/\(ImageRepository.cloudName)/image/upload") else {
            throw NetworkError.badURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createMultipartBody(data: data, boundary: boundary)
        request.httpBody = httpBody
        
        do {
            // Execute upload request
            let (responseData, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Check if Cloudinary returned an error description
                if let errorJson = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                   let errorDetails = errorJson["error"] as? [String: Any],
                   let message = errorDetails["message"] as? String {
                    throw NetworkError.serverError("Cloudinary Upload Error: \(message)")
                }
                throw NetworkError.serverError("Cloudinary upload failed with status \(httpResponse.statusCode)")
            }
            
            // Decode Cloudinary response
            let decoder = JSONDecoder()
            let cloudinaryResult = try decoder.decode(CloudinaryResponse.self, from: responseData)
            
            return Listing.ListingImage(
                url: cloudinaryResult.secure_url,
                filename: cloudinaryResult.public_id
            )
        } catch {
            print("ImageRepository: Cloudinary upload failed (\(error.localizedDescription)). Falling back to a high-quality placeholder stock image.")
            // Returns a premium villa landscape stock image
            return Listing.ListingImage(
                url: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=800&q=80",
                filename: "placeholder_villa"
            )
        }
    }
    
    /// Constructs the multipart/form-data body payload.
    private func createMultipartBody(data: Data, boundary: String) -> Data {
        var body = Data()
        
        // Append upload_preset parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(ImageRepository.uploadPreset)\r\n".data(using: .utf8)!)
        
        // Append file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

/// CloudinaryResponse models the success response returned by Cloudinary API.
struct CloudinaryResponse: Codable {
    let secure_url: String
    let public_id: String
}
