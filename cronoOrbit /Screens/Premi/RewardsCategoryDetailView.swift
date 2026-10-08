import SwiftUI
#if os(iOS)

struct RewardsCategoryDetailView: View {
    
    @EnvironmentObject var progress: ProgressManager
    
    let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]
    
    var body: some View {
        ZStack {
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
                            
                            let totalBronzi = progress.completedStudyEvents
                            let totalArgenti = totalBronzi / 5
                            let totalArancioni = totalBronzi / 7
                            let totalOri = totalArgenti / 4
                            let totalPlatini = totalArancioni / 4
                            
                            if progress.hasGoldStudy {
                                BadgeItemView(imageName: "PlatinumStudy", title: "Platinum Study", isUnlocked: progress.hasPlatinumStudy,
                                              earnedCount: totalPlatini, progress: progress.platinumStudyProgress)
                            }
                            
                            // 4. L'Oro appare se l'Arancione è sbloccato
                            if progress.hasOrangeStudy {
                                BadgeItemView(imageName: "badgeOroStudy", title: "Gold Study", isUnlocked: progress.hasGoldStudy,
                                              earnedCount: totalOri, progress: progress.goldStudyProgress)
                            }
                            
                            // 3. L'Arancione appare se l'Argento è sbloccato
                            if progress.hasSilverStudy {
                                BadgeItemView(imageName: "OrangeStudy", title: "Orange Study", isUnlocked: progress.hasOrangeStudy,
                                              earnedCount: totalArancioni, progress: progress.orangeStudyProgress)
                            }
                            
                            // 2. L'Argento appare se il Bronzo è sbloccato
                            if progress.hasBronzeStudy {
                                BadgeItemView(imageName: "BadgeArgetoStudy", title: "Argento Study", isUnlocked: progress.hasSilverStudy,
                                              earnedCount: totalArgenti, progress: progress.silverStudyProgress)
                            }
                            
                            // 1. Il Bronzo è sempre visibile
                            BadgeItemView(imageName: "BadgeStudyBronzo", title: "Bronze Study", isUnlocked: progress.hasBronzeStudy,
                                          earnedCount: totalBronzi, progress: progress.bronzeStudyProgress)
                        }

                        .padding(.horizontal)
                    }
                    
                    
                    // --- Sezione FOCUS ---
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Focus")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            if progress.hasGoldFocus {
                                BadgeItemView(imageName: "PlatinumFocus", title: "Platinum Focus", isUnlocked: progress.hasPlatinumFocus, earnedCount: progress.completedFocusEvents, progress: progress.platinumFocusProgress)
                            }
                            if progress.hasOrangeFocus {
                                BadgeItemView(imageName: "FOCUS", title: "Gold Focus", isUnlocked: progress.hasGoldFocus, earnedCount: progress.completedFocusEvents, progress: progress.goldFocusProgress)
                            }
                            if progress.hasSilverFocus {
                                BadgeItemView(imageName: "focusArancione", title: "Orange Focus", isUnlocked: progress.hasOrangeFocus, earnedCount: progress.completedFocusEvents, progress: progress.orangeFocusProgress)
                            }
                            if progress.hasBronzeFocus {
                                BadgeItemView(imageName: "badgeArgentofocus", title: "Argento Focus", isUnlocked: progress.hasSilverFocus, earnedCount: progress.completedFocusEvents, progress: progress.silverFocusProgress)
                            }
                            BadgeItemView(imageName: "badge_bronzo2focus", title: "Bronze Focus", isUnlocked: progress.hasBronzeFocus, earnedCount: progress.completedFocusEvents, progress: progress.bronzeFocusProgress)
                        }
                        .padding(.horizontal)
                    }
                    
                    // --- Sezione SPORT ---
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Sport")
                            .font(.system(size: 34, weight: .bold))
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 24) {
                            
                            if progress.hasGoldSport {
                                BadgeItemView(imageName: "PlatinumSport", title: "Platinum Sport", isUnlocked: progress.hasPlatinumSport, earnedCount: progress.completedSportEvents, progress: progress.platinumSportProgress)
                            }
                            if progress.hasOrangeSport {
                                BadgeItemView(imageName: "badgeSportGold", title: "Gold Sport", isUnlocked: progress.hasGoldSport, earnedCount: progress.completedSportEvents, progress: progress.goldSportProgress)
                            }
                            if progress.hasSilverSport {
                                BadgeItemView(imageName: "arancioneSport", title: "Orange Sport", isUnlocked: progress.hasOrangeSport, earnedCount: progress.completedSportEvents, progress: progress.orangeSportProgress)
                            }
                            if progress.hasBronzeSport {
                                BadgeItemView(imageName: "ArgentoSport", title: "Argento Sport", isUnlocked: progress.hasSilverSport, earnedCount: progress.completedSportEvents, progress: progress.silverSportProgress)
                            }
                            BadgeItemView(imageName: "badge_bronzo2sport", title: "Bronze Sport", isUnlocked: progress.hasBronzeSport, earnedCount: progress.completedSportEvents, progress: progress.bronzeSportProgress)
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


struct BadgeItemView: View {
    var imageName: String
    var title: String
    var isUnlocked: Bool
    var earnedCount: Int
    var progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .grayscale(isUnlocked ? 0.0 : 1.0)
                .opacity(isUnlocked ? 1.0 : 0.6)
            
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // SE LA MEDAGLIA È SBLOCCATA
            if isUnlocked {
                Text("\(earnedCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Color.teal)
                    .clipShape(Capsule())
            }
            // SE È BLOCCATA (Barra di progresso)
            else {
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
#endif

