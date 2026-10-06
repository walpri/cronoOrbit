//
//  RewardsCategoryDetailView.swift
//  cronoOrbit
//
//  Created by san-26 on 06/10/2026.
//
import SwiftUI
#if os(iOS)

struct RewardsCategoryDetailView: View {
    
   
    let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]
 
    
    // STUDY
    @State private var bronziStudy = 0
    @State private var argentiStudy = 0
    @State private var arancioniStudy = 0
    @State private var oriStudy = 0
    @State private var platiniStudy = 0
    
    // FOCUS
    @State private var bronziFocus = 0
    @State private var argentiFocus = 0
    @State private var arancioniFocus = 0
    @State private var oriFocus = 0
    @State private var platiniFocus = 0
    
    // SPORT
    @State private var bronziSport = 0
    @State private var argentiSport = 0
    @State private var arancioniSport = 0
    @State private var oriSport = 0
    @State private var platiniSport = 0
    
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 40) {
                    
                    // --- Sezione STUDY ---
         
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Study")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                          
                          
                            if oriStudy > 0 && platiniStudy == 0 {
                                BadgeItemView(imageName: "badge_studyLegend", title: "Platinum Study", isUnlocked: false, progress: 0.2) // Barra Platino
                            } else if arancioniStudy > 0 && oriStudy == 0 {
                                BadgeItemView(imageName: "badgeOroStudy", title: "Gold Study", isUnlocked: false, progress: 0.5) // Barra Oro
                            } else if argentiStudy > 0 && arancioniStudy == 0 {
                                BadgeItemView(imageName: "arancioneStudy", title: "Orange Study", isUnlocked: false, progress: 0.3) // Barra Arancione
                            } else if bronziStudy > 0 && argentiStudy == 0 {
                                BadgeItemView(imageName: "BadgeArgetoStudy", title: "Argento Study", isUnlocked: false, progress: 0.8) // Barra Argento
                            } else if bronziStudy == 0 {
                                BadgeItemView(imageName: "BadgeStudyBronzo", title: "Bronze Study", isUnlocked: false, progress: 0.6) // Barra Bronzo
                            }
                            
                            // 2. A SEGUIRE: LE MEDAGLIE GIÀ VINTE
                            if platiniStudy > 0 {
                                BadgeItemView(imageName: "badge_studyLegend", title: "Platinum Study", isUnlocked: true, earnedCount: platiniStudy)
                            }
                            if oriStudy > 0 {
                                BadgeItemView(imageName: "badgeOroStudy", title: "Gold Study", isUnlocked: true, earnedCount: oriStudy)
                            }
                            if arancioniStudy > 0 {
                                BadgeItemView(imageName: "arancioneStudy", title: "Orange Study", isUnlocked: true, earnedCount: arancioniStudy)
                            }
                            if argentiStudy > 0 {
                                BadgeItemView(imageName: "BadgeArgetoStudy", title: "Argento Study", isUnlocked: true, earnedCount: argentiStudy)
                            }
                            if bronziStudy > 0 {
                                BadgeItemView(imageName: "BadgeStudyBronzo", title: "Bronze Study", isUnlocked: true, earnedCount: bronziStudy)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
        
                    // --- Sezione FOCUS ---
            
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Focus")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            // 1. PRIMA LINEA: IL PROSSIMO OBIETTIVO (Grigio con barra)
                            if oriFocus > 0 && platiniFocus == 0 {
                                BadgeItemView(imageName: "badge_focusLegend", title: "Platinum Focus", isUnlocked: false, progress: 0.0)
                            } else if arancioniFocus > 0 && oriFocus == 0 {
                                BadgeItemView(imageName: "FOCUS", title: "Gold Focus", isUnlocked: false, progress: 0.0)
                            } else if argentiFocus > 0 && arancioniFocus == 0 {
                                BadgeItemView(imageName: "focusArancione", title: "Orange Focus", isUnlocked: false, progress: 0.0)
                            } else if bronziFocus > 0 && argentiFocus == 0 {
                                BadgeItemView(imageName: "badgeArgentofocus", title: "Argento Focus", isUnlocked: false, progress: 0.0)
                            } else if bronziFocus == 0 {
                                BadgeItemView(imageName: "badge_bronzo2focus", title: "Bronze Focus", isUnlocked: false, progress: 0.3)
                            }
                            
                        //  MEDAGLIE GIÀ VINTE
                            if platiniFocus > 0 {
                                BadgeItemView(imageName: "badge_focusLegend", title: "Platinum Focus", isUnlocked: true, earnedCount: platiniFocus)
                            }
                            if oriFocus > 0 {
                                BadgeItemView(imageName: "FOCUS", title: "Gold Focus", isUnlocked: true, earnedCount: oriFocus)
                            }
                            if arancioniFocus > 0 {
                                BadgeItemView(imageName: "focusArancione", title: "Orange Focus", isUnlocked: true, earnedCount: arancioniFocus)
                            }
                            if argentiFocus > 0 {
                                BadgeItemView(imageName: "badgeArgentofocus", title: "Argento Focus", isUnlocked: true, earnedCount: argentiFocus)
                            }
                            if bronziFocus > 0 {
                                BadgeItemView(imageName: "badge_bronzo2focus", title: "Bronze Focus", isUnlocked: true, earnedCount: bronziFocus)
                            }
                        }
                        .padding(.horizontal)
                    }
                    

                    // --- Sezione SPORT ---
           
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sport")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            // 1. PRIMA LINEA: IL PROSSIMO OBIETTIVO (Grigio con barra)
                            if oriSport > 0 && platiniSport == 0 {
                                BadgeItemView(imageName: "badge_SportLegend 1", title: "Platinum Sport", isUnlocked: false, progress: 0.0)
                            } else if arancioniSport > 0 && oriSport == 0 {
                                BadgeItemView(imageName: "badgeSportGold", title: "Gold Sport", isUnlocked: false, progress: 0.0)
                            } else if argentiSport > 0 && arancioniSport == 0 {
                                BadgeItemView(imageName: "arancioneSport", title: "Orange Sport", isUnlocked: false, progress: 0.0)
                            } else if bronziSport > 0 && argentiSport == 0 {
                                BadgeItemView(imageName: "ArgentoSport", title: "Argento Sport", isUnlocked: false, progress: 0.0)
                            } else if bronziSport == 0 {
                                BadgeItemView(imageName: "badge_bronzo2sport", title: "Bronze Sport", isUnlocked: false, progress: 0.35)
                            }
                            
                     // LE MEDAGLIE GIÀ VINTE
                            if platiniSport > 0 {
                                BadgeItemView(imageName: "badge_SportLegend 1", title: "Platinum Sport", isUnlocked: true, earnedCount: platiniSport)
                            }
                            if oriSport > 0 {
                                BadgeItemView(imageName: "badgeSportGold", title: "Gold Sport", isUnlocked: true, earnedCount: oriSport)
                            }
                            if arancioniSport > 0 {
                                BadgeItemView(imageName: "arancioneSport", title: "Orange Sport", isUnlocked: true, earnedCount: arancioniSport)
                            }
                            if argentiSport > 0 {
                                BadgeItemView(imageName: "ArgentoSport", title: "Argento Sport", isUnlocked: true, earnedCount: argentiSport)
                            }
                            if bronziSport > 0 {
                                BadgeItemView(imageName: "badge_bronzo2sport", title: "Bronze Sport", isUnlocked: true, earnedCount: bronziSport)
                            }
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
    }
}

// COMPONENTE PER IL SINGOLO BADGE
struct BadgeItemView: View {
    var imageName: String
    var title: String
    var isUnlocked: Bool
    var earnedCount: Int = 0
    var progress: Double = 0.0
    
    var body: some View {
        VStack(spacing: 8) {
            
            // Immagine Badge
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .grayscale(isUnlocked ? 0.0 : 1.0)
                .opacity(isUnlocked ? 1.0 : 0.6)
            
            // Titolo
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .multilineTextAlignment(.center)
            
            // Indicatore inferiore: Contatore o Barra
            if isUnlocked {
                // Pill Numerico
                Text("\(earnedCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color.teal)
                    .clipShape(Capsule())
            } else {
                // Barra di progresso
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.teal)
                            .frame(width: max(0, geometry.size.width * min(progress, 1.0)), height: 6)
                    }
                }
                .frame(width: 50, height: 6)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Anteprima per Xcode
struct RewardsCategoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RewardsCategoryDetailView()
        }
    }
}
#endif


