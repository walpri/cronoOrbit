import SwiftUI
import Combine

#if os(iOS)

class ProgressManager: ObservableObject {
    
    // Contatori salvati nel telefono per non perderli alla chiusura dell'app
    @AppStorage("studyCount") var completedStudyEvents: Int = 0
    @AppStorage("focusCount") var completedFocusEvents: Int = 0
    @AppStorage("sportCount") var completedSportEvents: Int = 0
    
    // Traguardi
    let bronzeTarget = 1
    let silverTarget = 5
    let orangeTarget = 12
    let goldTarget = 30
    let platinumTarget = 50
    
    // LOGICA STUDY

    var hasBronzeStudy: Bool { completedStudyEvents >= bronzeTarget }
    var hasSilverStudy: Bool { completedStudyEvents >= silverTarget }
    var hasOrangeStudy: Bool { completedStudyEvents >= orangeTarget }
    var hasGoldStudy: Bool { completedStudyEvents >= goldTarget }
    var hasPlatinumStudy: Bool { completedStudyEvents >= platinumTarget }
    
    var bronzeStudyProgress: Double { min(Double(completedStudyEvents) / Double(bronzeTarget), 1.0) }
    var silverStudyProgress: Double { min(Double(completedStudyEvents) / Double(silverTarget), 1.0) }
    var orangeStudyProgress: Double { min(Double(completedStudyEvents) / Double(orangeTarget), 1.0) }
    var goldStudyProgress: Double { min(Double(completedStudyEvents) / Double(goldTarget), 1.0) }
    var platinumStudyProgress: Double { min(Double(completedStudyEvents) / Double(platinumTarget), 1.0) }
    
    // LOGICA FOCUS
 
    var hasBronzeFocus: Bool { completedFocusEvents >= bronzeTarget }
    var hasSilverFocus: Bool { completedFocusEvents >= silverTarget }
    var hasOrangeFocus: Bool { completedFocusEvents >= orangeTarget }
    var hasGoldFocus: Bool { completedFocusEvents >= goldTarget }
    var hasPlatinumFocus: Bool { completedFocusEvents >= platinumTarget }
    
    var bronzeFocusProgress: Double { min(Double(completedFocusEvents) / Double(bronzeTarget), 1.0) }
    var silverFocusProgress: Double { min(Double(completedFocusEvents) / Double(silverTarget), 1.0) }
    var orangeFocusProgress: Double { min(Double(completedFocusEvents) / Double(orangeTarget), 1.0) }
    var goldFocusProgress: Double { min(Double(completedFocusEvents) / Double(goldTarget), 1.0) }
    var platinumFocusProgress: Double { min(Double(completedFocusEvents) / Double(platinumTarget), 1.0) }
    

    // LOGICA SPORT

    var hasBronzeSport: Bool { completedSportEvents >= bronzeTarget }
    var hasSilverSport: Bool { completedSportEvents >= silverTarget }
    var hasOrangeSport: Bool { completedSportEvents >= orangeTarget }
    var hasGoldSport: Bool { completedSportEvents >= goldTarget }
    var hasPlatinumSport: Bool { completedSportEvents >= platinumTarget }
    
    var bronzeSportProgress: Double { min(Double(completedSportEvents) / Double(bronzeTarget), 1.0) }
    var silverSportProgress: Double { min(Double(completedSportEvents) / Double(silverTarget), 1.0) }
    var orangeSportProgress: Double { min(Double(completedSportEvents) / Double(orangeTarget), 1.0) }
    var goldSportProgress: Double { min(Double(completedSportEvents) / Double(goldTarget), 1.0) }
    var platinumSportProgress: Double { min(Double(completedSportEvents) / Double(platinumTarget), 1.0) }
    

    // METODO REGISTRAZIONE
 
    func completeEvent(category: String) {
        DispatchQueue.main.async {
            print("Cerco di completare evento per: \(category)") 
            
            switch category.lowercased() {
            case "study", "studio", "studiare":
                self.completedStudyEvents += 1
                print("Study salito a: \(self.completedStudyEvents)")
            case "focus", "deep focus", "lavoro", "work": // <-- Tutto minuscolo!
                self.completedFocusEvents += 1
                print("Focus salito a: \(self.completedFocusEvents)")
            case "sport", "allenamento", "health": // <-- Tutto minuscolo!
                self.completedSportEvents += 1
                print("Sport salito a: \(self.completedSportEvents)")
            default:
                print("Categoria '\(category)' non riconosciuta per le medaglie.")
            }

        }
    }
}
#endif

