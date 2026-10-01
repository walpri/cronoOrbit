/*
import SwiftUI

struct RewardsView: View {
    
    // Layout a due colonne per la griglia dei badge
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            // Sfondo chiaro con una sfumatura molto leggera (simile allo screenshot)
          /*  LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.orange.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )*/
           
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Titolo
                    Text("Awards")
                        .font(.system(size: 34, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Card Principale: To be won
                    HStack(spacing: 12) {
                    
                        Image("badgeOroStudy")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To be won")
                                .font(.system(size: 18, weight: .bold))
                                
                            
                            Text("\"The next milestone\nis just waiting for your energy\"")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .italic()
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: -30){
                            
                            // Immagine dei badge disattivati/legend
                            Image("badge_studyLegend") // Sostituisci con l'immagine di gruppo corretta se necessario
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .grayscale(1.0)
                                .fixedSize(horizontal: true, vertical: false)
                              
                            Image("arancioneSport")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .grayscale(1.0)
                                .fixedSize(horizontal: true, vertical: false)
                              
                            Image("FOCUS")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .grayscale(1.0)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                       
                    }
                   // .glassEffect()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    
                    
                    // Griglia dei Premi (Study, Sport, Deep Focus)
                    LazyVGrid(columns: columns, spacing: 16) {
                        
                        // Card Study
                        RewardCardView(
                            category: "STUDY",
                            imageName: "BadgeArgetoStudy", // Asset Argento
                            title: "Obiettivo Study"
                        )
                        
                        // Card Sport
                        RewardCardView(
                            category: "SPORT",
                            imageName: "badgeSportGold", // Asset Oro
                            title: "Obiettivo Sport"
                        )
                        
                        // Card Deep Focus
                        RewardCardView(
                            category: "DEEP FOCUS",
                            imageName: "focusArancione", // Asset Arancione/Bronzo
                            title: "Obiettivo Deep\nFocus"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Spazio extra in basso per non coprire le card con la TabBar custom
                    Spacer().frame(height: 100)
                }
            } .background(AppBackground())
              
        }
    }
}
<<<<<<< Updated upstream
 */
=======

// COMPONENTE RIUTILIZZABILE PER LE CARD DEI PREMI
struct RewardCardView: View {
    var category: String
    var imageName: String
    var title: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Categoria in alto a sinistra
            Text(category)
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Immagine del Badge
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 85)
            
            // Testo in basso
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
}

// Anteprima per Xcode
struct RewardsView_Previews: PreviewProvider {
    static var previews: some View {
        RewardsView()
    }
}

>>>>>>> Stashed changes
