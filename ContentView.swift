import SwiftUI
import AVFoundation

// MARK: - Audio Player Controller
class CarrozzeriaPlayer: ObservableObject {
    private var audioEngine = AVAudioEngine()
    private var playerNode = AVAudioPlayerNode()
    private var reverbNode = AVAudioUnitReverb()
    private var eqNode = AVAudioUnitEQ(numberOfBands: 2)
    
    @Published var isPlaying = false
    @Published var isCarrozzeriaActive = false
    @Published var trackTitle = "Musiqa tanlanmagan"

    init() {
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        // Dvigatelga tugunlarni (node) ulash
        audioEngine.attach(playerNode)
        audioEngine.attach(reverbNode)
        audioEngine.attach(eqNode)

        // Carrozzeria (Konsert zali) Reverb sozlamasi
        reverbNode.loadFactoryPreset(.cathedral) // Yoki .largeHall
        reverbNode.wetDryMix = 0 // Boshida effekt o'chirilgan (0%)

        // EQ (Bass va treble akustikasi) sozlamasi
        let bassBand = eqNode.bands[0]
        bassBand.filterType = .lowShelf
        bassBand.frequency = 100
        bassBand.gain = 4.0 // 4dB bass kuchaytirish

        // Zanjirni ulash: Player -> Reverb -> EQ -> MainOutput
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        audioEngine.connect(playerNode, to: reverbNode, format: format)
        audioEngine.connect(reverbNode, to: eqNode, format: format)
        audioEngine.connect(eqNode, to: audioEngine.mainMixerNode, format: format)
    }

    func loadAudio(url: URL) {
        do {
            let file = try AVAudioFile(forReading: url)
            playerNode.stop()
            playerNode.scheduleFile(file, at: nil, completionHandler: nil)
            
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            trackTitle = url.lastPathComponent
        } catch {
            print("Audio faylni yuklashda xatolik: \(error)")
        }
    }

    func togglePlayPause() {
        if isPlaying {
            playerNode.pause()
        } else {
            playerNode.play()
        }
        isPlaying.toggle()
    }

    // TOGGLE: CARROZZERIA / KONSERT ZALI REJIMINI YOQISH-O'CHIRISH
    func toggleCarrozzeria() {
        isCarrozzeriaActive.toggle()
        
        // Animatsiya bilan Reverb va EQ qiymatlarini o'zgartirish
        if isCarrozzeriaActive {
            reverbNode.wetDryMix = 45 // 45% Konsert aks sadosi
        } else {
            reverbNode.wetDryMix = 0  // Oddiy steril ovoz
        }
    }
}

// MARK: - SwiftUI User Interface (Interfeys)
struct ContentView: View {
    @StateObject private var player = CarrozzeriaPlayer()
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Albom muqovasi va musiqa nomi
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(player.isCarrozzeriaActive ? Color.purple.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 250, height: 250)
                
                Image(systemName: "music.note.house.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .foregroundColor(player.isCarrozzeriaActive ? .purple : .gray)
            }

            Text(player.trackTitle)
                .font(.headline)
                .lineLimit(1)
                .padding(.horizontal)

            // --- CARROZZERIA (KONSERT ZALI) TUGMASI ---
            Button(action: {
                withAnimation {
                    player.toggleCarrozzeria()
                }
            }) {
                HStack {
                    Image(systemName: player.isCarrozzeriaActive ? "speaker.wave.3.fill" : "speaker.wave.1")
                    Text(player.isCarrozzeriaActive ? "CARROZZERIA: YOQILGAN" : "CARROZZERIA: O'CHIRILGAN")
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(player.isCarrozzeriaActive ? LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(radius: player.isCarrozzeriaActive ? 10 : 0)
            }
            .padding(.horizontal, 40)

            // Pleyer boshqaruv tugmalari
            HStack(spacing: 40) {
                Button(action: { showFilePicker = true }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title)
                }

                Button(action: { player.togglePlayPause() }) {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                }
            }

            Spacer()
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url):
                player.loadAudio(url: url)
            case .failure(let error):
                print("Fayl tanlashda xato: \(error)")
            }
        }
    }
}
