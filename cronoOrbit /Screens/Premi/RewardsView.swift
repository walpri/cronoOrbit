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
        // si aggiorna ogni 15 secondi: lo stato provvisorio può scadere anche senza altre modifiche
        TimelineView(.periodic(from: .now, by: 15)) { ctx in
            content(now: ctx.date)
        }
    }
    
    private func content(now: Date) -> some View {
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
                    .padding()
                    .glass(24)
                    .padding(.horizontal)
                    
                    
                    // Medaglie annullate: un impegno non è stato confermato entro 15 minuti
                    ForEach(store.medalAlerts) { alert in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                            Text("Medaglia \(alert.medalName) annullata: «\(alert.eventTitle)» non è stata confermata entro 15 minuti.")
                                .font(.footnote)
                            Spacer(minLength: 0)
                            Button { store.dismissMedalAlert(alert.id) } label: { Image(systemName: "xmark") }
                                .buttonStyle(.plain)
                        }
                        .padding(14)
                        .glass(20)
                        .padding(.horizontal)
                    }
                    
                    // Griglia dei Premi (Study, Sport, Deep Focus)
                    LazyVGrid(columns: columns, spacing: 16) {
                        
                        // Card Study
                        RewardCardView(
                            category: "STUDY",
                            imageName: "BadgeArgetoStudy", // Asset Argento
                            title: "Obiettivo Study",
                            progress: Medal.study.progress(in: store.events, now: now)
                        )
                        
                        // Card Sport
                        RewardCardView(
                            category: "SPORT",
                            imageName: "badgeSportGold", // Asset Oro
                            title: "Obiettivo Sport",
                            progress: Medal.sport.progress(in: store.events, now: now)
                        )
                        
                        // Card Deep Focus
                        RewardCardView(
                            category: "DEEP FOCUS",
                            imageName: "focusArancione", // Asset Arancione/Bronzo
                            title: "Obiettivo Deep\nFocus",
                            progress: Medal.deepFocus.progress(in: store.events, now: now)
                        )
                    }
                    .padding(.horizontal)
                    
                    Text("Conferma ogni impegno entro 15 minuti dalla fine: altrimenti non conta per le medaglie.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    // Spazio extra in basso per non coprire le card con la TabBar custom
                    Spacer().frame(height: 100)
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
                .grayscale(progress.isWon ? 0 : 1)          // bloccata finché non è vinta
                .opacity(progress.isWon ? 1 : 0.55)
            
            // Testo in basso
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            // Avanzamento: impegni confermati su quelli richiesti
            Text(verbatim: "\(min(progress.total, progress.goal))/\(progress.goal)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
            
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
