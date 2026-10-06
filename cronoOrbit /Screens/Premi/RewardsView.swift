import SwiftUI
#if os(iOS)

struct RewardsView: View {
    
    // Layout a due colonne per la griglia dei badge
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Titolo
                        Text("Rewards")
                            .font(.system(size: 34, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                       
                        NavigationLink(destination: MedalDetailView()) {
                            HStack(spacing: 12) {
                                Image("badgeOroStudy")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 70, height: 70)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("To be won")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primary)
                                        
                                    Text("\"The next milestone\nis just waiting for your energy\"")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                        .italic()
                                        .fixedSize(horizontal: true, vertical: false)
                                        .multilineTextAlignment(.leading)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: -30) {
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
                            .glass()
                           
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        
                
                        LazyVGrid(columns: columns, spacing: 16) {
                            
                            NavigationLink(destination: RewardsCategoryDetailView()) {
                                RewardCardView(
                                    category: "STUDY",
                                    imageName: "BadgeArgetoStudy",
                                    title: "Obiettivo Study"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: RewardsCategoryDetailView()) {
                                RewardCardView(
                                    category: "SPORT",
                                    imageName: "badgeSportGold",
                                    title: "Obiettivo Sport"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: RewardsCategoryDetailView()) {
                                RewardCardView(
                                    category: "DEEP FOCUS",
                                    imageName: "focusArancione",
                                    title: "Obiettivo Deep\nFocus"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
            
                        Spacer().frame(height: 100)
                         
                    }
                }
                .background(AppBackground())
            }
            .navigationBarHidden(true)
        }
    }
}


struct RewardCardView: View {
    var category: String
    var imageName: String
    var title: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(category)
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 85)
            
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .glass()
    }
}


struct RewardsView_Previews: PreviewProvider {
    static var previews: some View {
        RewardsView()
    }
}
#endif




