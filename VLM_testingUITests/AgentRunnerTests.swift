import XCTest
import Foundation


@MainActor
final class AgentRunnerTests: XCTestCase {
    
    var API_KEY: String {
            let bundle = Bundle(for: type(of: self))
            
            guard let key = bundle.object(forInfoDictionaryKey: "API_KEY") as? String else {
                fatalError("Secret not found in UI Test Bundle")
            }
            return key
        }
    
    //logStep is a function that allows the TestCase to export the current model's reasoning and result as a txt file for review later - it also holds the screenshot the model saw
    
    func logStep(step: Int, screenshot: UIImage, action: AgentAction, hierarchy: String) {
        XCTContext.runActivity(named: "Step \(step): \(action.type)") { activity in
            
            //Attach the Screenshot
            let attachment = XCTAttachment(image: screenshot)
            attachment.lifetime = .keepAlways
            attachment.name = "Screen_Step_\(step)"
            activity.add(attachment)
            
            //Attach Agent Info Text
            let logText = """
            Decision: \(action.type) -> \(action.elementID ?? "nil")
            Reasoning: \(action.reasoning)
            --------------------------------------------------
            Truncation Status: \(action.hasTruncatedText ? "Truncated Text Detected" : "No Truncation")
            Location: \(action.visualDescription ?? "N/A")
            --------------------------------------------------
            Hierarchy Sample:
            \(hierarchy.prefix(500))... (truncated)
            """
            
            //commit
            let textAttachment = XCTAttachment(string: logText)
            textAttachment.name = "VLM_Analysis"
            textAttachment.lifetime = .keepAlways
            activity.add(textAttachment)
        }
    }
    
    // this is the test loop
    // currently, we will try 15 rounds of looping before force exiting to ensure we don't end up in an infinite loop
    func testAgenticFlow() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // add your API Key here
        let apiKey = API_KEY
        let client = GeminiClient(apiKey: apiKey)
        
        let goal = "Try and find any truncated text within this application."
        
        print("Agent has started with goal: \(goal)")
        
        for step in 1...15 {
            print("\n--- Step \(step) ---")
            
            // Find hierarchy for VLM
            let screenshot = XCUIScreen.main.screenshot().image
            let hierarchy = ElementTree.capture(app: app)
            
            // Trigger the gemini client here to send our request over
            let action = try await client.askGemini(screenshot: screenshot, hierarchy: hierarchy, goal: goal)
            print("Current agent reasoning: \(action.reasoning)")
            
            // Log our response from Gemini
            logStep(step: step, screenshot: screenshot, action: action, hierarchy: hierarchy)
            
            // Allow the agent to act
            switch action.type {
            case "tap":
                guard let id = action.elementID else { continue }
                print("Tapping: \(id)")
                
                // Robust tapping logic: Tries Button -> Text -> Image -> Other
                if app.buttons[id].exists { app.buttons[id].tap() }
                else if app.staticTexts[id].exists { app.staticTexts[id].tap() }
                else if app.images[id].exists { app.images[id].tap() }
                else if app.otherElements[id].exists { app.otherElements[id].tap() }
                else {
                    print("Could not find element: \(id)")
                }
                
            case "type":
                guard let text = action.text else { continue }
                app.typeText(text)
                
            case "done":
                print("Goal achieved")
                return
                
            case "fail":
                XCTFail("Agent gave up: \(action.reasoning)")
                return
                
            default:
                break
            }
            
            // Delay to ensure UI has finished animations
            try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        }
        
        XCTFail("Agent timed out after 15 steps")
    }
}
