import XCTest

class ElementTree {
    static func capture(app: XCUIApplication) -> String {
        //get the debug hierarchy
        let rawTree = app.debugDescription
        
        //cleanup for agent use
        let lines = rawTree.components(separatedBy: "\n")
        var cleanTree = [String]()
        
        for line in lines {
            // Filter for any elements that the agent could interact with
            if line.contains("Button") ||
               line.contains("StaticText") ||
               line.contains("TextField") ||
               line.contains("SecureTextField") ||
               line.contains("Image") {
                
                // Remove memory addresses to reduce token usage
                let cleanedLine = line.replacingOccurrences(of: "0x[0-9a-fA-F]+", with: "", options: .regularExpression)
                cleanTree.append(cleanedLine)
            }
        }
        
        return cleanTree.joined(separator: "\n")
    }
}
