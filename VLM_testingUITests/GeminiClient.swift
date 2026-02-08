import Foundation
import UIKit

struct AgentAction: Codable {
    let type: String
    let elementID: String?
    let text: String?
    let reasoning: String
    let hasTruncatedText: Bool
    let visualDescription: String?
}

class GeminiClient {
    private let apiKey: String
    private let modelName = "gemini-3-flash-preview" // this could be subsituted with gemini 3 pro for better performance but flash is much quicker and is good at detecting truncated text
    
    init(apiKey: String) { self.apiKey = apiKey }
    
    func askGemini(screenshot: UIImage, hierarchy: String, goal: String) async throws -> AgentAction {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Resize/Encode Image
        let resizedImage = resize(image: screenshot)
        let imageData = resizedImage.jpegData(compressionQuality: 0.6)?.base64EncodedString() ?? ""
        
        // Construct the Prompt
        let prompt = """
            You are an iOS UI Test Agent.
            GOAL: \(goal)
            
            INSTRUCTIONS:
            1. VISUAL CHECK: Look closely at the screenshot. Is there any trunated text?
            2. HIERARCHY CHECK: Review the provided UI elements.
            3. DECISION: Determine the next step to achieve the goal.
            
            Return STRICT JSON only (no markdown):
            {
              "hasTruncatedText": true/false,
              "visualDescription": "Briefly describe where the truncated text is",
              "type": "tap"|"type"|"done"|"fail",
              "elementID": "string_id_from_hierarchy",
              "text": "string_to_type",
              "reasoning": "Explain why you chose this action"
            }
            
            UI HIERARCHY:
            \(hierarchy)
            """
        
        //console output for debugging
        
        print("\n-------- Outgoing request to Gemini --------")
        print("Image Size: \(imageData.count / 1024)KB)")
        print("Prompt: \n\(prompt)")
        print("---------------------------------------------------\n")
        // ---------------------------------------------------------

        let jsonBody: [String: Any] = [
            "contents": [[
                "role": "user",
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": imageData]]
                ]
            ]],
            "generationConfig": ["response_mime_type": "application/json"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
                
                // 1. Send Request
                let (data, _) = try await URLSession.shared.data(for: request)
                
                if let rawJSON = String(data: data, encoding: .utf8) {
                    print("\n-------- Gemini's Response --------")
                    print(rawJSON)
                    print("---------------------------------------------------\n")
                }

                
                // 2. Define Response Structure
                struct GeminiResponse: Decodable {
                    struct Candidate: Decodable {
                        struct Content: Decodable {
                            struct Part: Decodable { let text: String }
                            let parts: [Part]
                        }
                        let content: Content
                    }
                    let candidates: [Candidate]?
                    //err handling
                    struct APIError: Decodable {
                        let code: Int
                        let message: String
                    }
                    let error: APIError?
                }
        
        
        //Decode here
                // API Errors handled here
                let decoded: GeminiResponse
                do {
                    decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                } catch {
                    print("Error while decoding JSON: \(error)")
                    throw error
                }

                // Extract a good JSON
                guard let jsonString = decoded.candidates?.first?.content.parts.first?.text else {
                    // If candidates is nil - check if we got an API error
                    if let apiError = decoded.error {
                         throw NSError(domain: "GeminiAPI", code: apiError.code, userInfo: [NSLocalizedDescriptionKey: apiError.message])
                    }
                    throw NSError(domain: "Agent", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response text found in candidates"])
                }
                
                // Convert our response to an action
                guard let actionData = jsonString.data(using: .utf8) else {
                     throw NSError(domain: "Agent", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not convert response text to data"])
                }
                
                let action = try JSONDecoder().decode(AgentAction.self, from: actionData)
                    
                // Execute action
                if action.hasTruncatedText {
                    print("\n Truncated Text has been detected.")
                    print("Location: \(action.visualDescription ?? "Unknown")\n")
                } else {
                    print("No Truncation Detected.")
                }
                    
                return action
    }
    
    private func resize(image: UIImage) -> UIImage {
        let size = image.size
        let maxDim: CGFloat = 1024
        if size.width <= maxDim && size.height <= maxDim { return image }
        let scale = maxDim / max(size.width, size.height)
        return UIGraphicsImageRenderer(size: CGSize(width: size.width * scale, height: size.height * scale)).image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: size.width * scale, height: size.height * scale)))
        }
    }
}
