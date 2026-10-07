//
//  MedalDetailView.swift
//  cronoOrbit
//
//  Created by san-26 on 06/10/2026.
//

import SwiftUI
#if os(iOS)

// Modello dati per il popup
struct SelectedMedal: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let description: String

}

struct MedalDetailView: View {
    
    let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]
    

    
    // Controlla quale popup aprire
    @State private var medalToShow: SelectedMedal? = nil
    
    var body: some View {
        ZStack {
            // Sfondo
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.orange.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    
                    // --- Sezione STUDY ---
            
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Study")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            // BRONZO STUDY
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Bronze Study", imageName: "BadgeStudyBronzo", description: "Study every day.")
                            }) {
                                SimpleBadgeView(imageName: "BadgeStudyBronzo", title: "Bronze Study")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ARGENTO STUDY
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Argento Study", imageName: "BadgeArgetoStudy", description: "Win 5 bronze medals in a single week.")
                            }) {
                                SimpleBadgeView(imageName: "BadgeArgetoStudy", title: "Argento Study")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ARANCIONE STUDY
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Orange Study", imageName: "arancioneStudy", description: "Win 7 bronze medals in a single week.")
                            }) {
                                SimpleBadgeView(imageName: "arancioneStudy", title: "Orange Study")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ORO STUDY
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Gold Study", imageName: "badgeOroStudy", description: "Win 4 silver medals in a month.")
                            }) {
                                SimpleBadgeView(imageName: "badgeOroStudy", title: "Gold Study")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // PLATINO STUDY
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Platinum Study", imageName: "badge_studyLegend", description: "Earn 4 Orange medals in a month.")
                            }) {
                                SimpleBadgeView(imageName: "badge_studyLegend", title: "Platinum Study")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    
            
                    // --- Sezione FOCUS ---
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Focus")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            // BRONZO FOCUS
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Bronze Focus", imageName: "badge_bronzo2focus", description: "Focus profondo ogni giorno.")
                            }) {
                                SimpleBadgeView(imageName: "badge_bronzo2focus", title: "Bronze Focus")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ARGENTO FOCUS
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Argento Focus", imageName: "badgeArgentofocus", description: "Win 5 bronze medals in a single week.")
                            }) {
                                SimpleBadgeView(imageName: "badgeArgentofocus", title: "Argento Focus")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ARANCIONE FOCUS
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Orange Focus", imageName: "focusArancione", description: "Win 7 bronze medals in a single week.")
                            }) {
                                SimpleBadgeView(imageName: "focusArancione", title: "Orange Focus")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ORO FOCUS
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Gold Focus", imageName: "FOCUS", description: "Win 4 silver medals in a month.")
                            }) {
                                SimpleBadgeView(imageName: "FOCUS", title: "Gold Focus")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // PLATINO FOCUS
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Platinum Focus", imageName: "badge_focusLegend", description: "Earn 4 Orange medals in a month.")
                            }) {
                                SimpleBadgeView(imageName: "badge_focusLegend", title: "Platinum Focus")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    
            
                    // --- Sezione SPORT ---
                    // ==========================================
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sport")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            // BRONZO SPORT
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Bronze Sport", imageName: "badge_bronzo2sport", description: "Record a workout every day.")
                            }) {
                                SimpleBadgeView(imageName: "badge_bronzo2sport", title: "Bronze Sport")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ARGENTO SPORT
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Argento Sport", imageName: "ArgentoSport", description: "Win 5 bronze medals in a single week.")
                            }) {
                                SimpleBadgeView(imageName: "ArgentoSport", title: "Argento Sport")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ARANCIONE SPORT
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Orange Sport", imageName: "arancioneSport", description: "Win 7 bronze medals in a single week.")
                            }) {
                                SimpleBadgeView(imageName: "arancioneSport", title: "Orange Sport")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // ORO SPORT
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Gold Sport", imageName: "badgeSportGold", description: "Win 4 silver medals in a month.")
                            }) {
                                SimpleBadgeView(imageName: "badgeSportGold", title: "Gold Sport")
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // PLATINO SPORT
                            Button(action: {
                                medalToShow = SelectedMedal(title: "Platinum Sport", imageName: "badge_SportLegend 1", description: "Earn 4 Orange medals in a month.")
                            }) {
                                SimpleBadgeView(imageName: "badge_SportLegend 1", title: "Platinum Sport")
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer().frame(height: 50)
                }
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
       .background(AppBackground())
        
        // GESTIONE DEL POP-UP (SHEET)
        .sheet(item: $medalToShow) { medal in
            MedalPopupView(medal: medal)
        }
    }
}


struct SimpleBadgeView: View {
    var imageName: String
    var title: String

    
    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
               
            
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary) // Assicura che il testo non diventi blu
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// VISTA DEL POP-UP

struct MedalPopupView: View {
    var medal: SelectedMedal
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 30) {
            
            // Bottone "X" in alto a destra per chiudere
            HStack {
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .frame(width: 45, height: 45)
                        .font(.system(size: 25))
                        .glassEffect()
                      
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            
            Spacer().frame(height: 10)
            
            // Immagine della medaglia grande
            Image(medal.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
            
            Text(medal.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
            
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Come si ottiene:")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                
                Text(medal.description)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(AppBackground().ignoresSafeArea())
    }
}

struct MedalDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MedalDetailView()
        }
    }
}
#endif

