import SwiftUI
#if os(iOS)

struct RewardsView: View {
    @Environment(EventStore.self) private var store
    
    // Layout a due colonne per la griglia dei badge
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 15)) { ctx in
                content(now: ctx.date)
            }
        }
    }

    
    private func content(now: Date) -> some View {
        ZStack {
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Titolo
                    Text("Rewards")
                        .font(.system(size: 34, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                    NavigationLink(destination: MedalDetailView()){
                        
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
                                Image("badge_studyLegend")
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
                        .padding()
                        .glass(24)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                    
                   
                    
                    // Griglia dei Premi (Study, Sport, Deep Focus)
                    LazyVGrid(columns: columns, spacing: 16) {
                      
                        NavigationLink(destination: RewardsCategoryDetailView()) {
                            // Card Study
                            RewardCardView(
                                category: "STUDY",
                                imageName: "BadgeArgetoStudy",
                                title: "Obiettivo Study",
                                progress: Medal.study.progress(in: store.events, now: now)
                            )
                        }.buttonStyle(.plain)
                        
                        NavigationLink(destination: RewardsCategoryDetailView()) {
                            // Card Sport
                            RewardCardView(
                                category: "SPORT",
                                imageName: "badgeSportGold",
                                title: "Obiettivo Sport",
                                progress: Medal.sport.progress(in: store.events, now: now)
                            )
                        }.buttonStyle(.plain)
                        
                        NavigationLink(destination: RewardsCategoryDetailView()) {
                            // Card Deep Focus
                            RewardCardView(
                                category: "DEEP FOCUS",
                                imageName: "focusArancione", // Asset Arancione/Bronzo
                                title: "Obiettivo Deep\nFocus",
                                progress: Medal.deepFocus.progress(in: store.events, now: now)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
          
                }
            } .background(AppBackground())
              
        }
    }
}

// COMPONENTE RIUTILIZZABILE PER LE CARD DEI PREMI
struct RewardCardView: View {
    var category: String
    var imageName: String
    var title: String
    var progress: MedalProgress
    
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
            
           
            if progress.isProvisional {
                Label("In attesa di conferma", systemImage: "hourglass")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glass(24)
    }
}

// Anteprima per Xcode
struct RewardsView_Previews: PreviewProvider {
    static var previews: some View {
        RewardsView().environment(EventStore())
    }
}

#endif
