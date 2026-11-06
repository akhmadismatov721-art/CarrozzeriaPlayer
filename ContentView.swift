import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var isPlaying = false
    @State private var isCarrozzeriaOn = false
    @State private var isCarModeOn = false
    @State private var isImporterPresented = false
    @State private var selectedAudioURL: URL?
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isCarrozzeriaOn ? [.black, .purple.opacity(0.6), .black] : [.black, .gray.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("CARROZZERIA PLAYER")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Telefon xotirasidan musiqa tanlash tugmasi
                    Button(action: {
                        isImporterPresented.toggle()
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        isCarModeOn.toggle()
                    }) {
                        Image(systemName: isCarModeOn ? "car.fill" : "car")
                            .font(.title2)
                            .foregroundColor(isCarModeOn ? .purple : .white)
                    }
                }
                .padding(.horizontal)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: isCarModeOn ? 280 : 220, height: isCarModeOn ? 280 : 220)
                        .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 4, height: isPlaying ? CGFloat.random(in: 15...45) : 10)
                                    .animation(isPlaying ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.1) : .default, value: isPlaying)
                            }
                        }
                        .padding(.top, 10)
                    }
                }

                VStack(spacing: 5) {
                    Text(selectedAudioURL?.lastPathComponent ?? "Carrozzeria Hi-Fi Mix")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(isCarModeOn ? "Avtomobil rejimi Faol" : "iPhone xotirasidan")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Button(action: {
                    isCarrozzeriaOn.toggle()
                }) {
                    HStack {
                        Image(systemName: isCarrozzeriaOn ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        Text(isCarrozzeriaOn ? "Akustika: Carrozzeria YOQILGAN" : "Akustika: Standart")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isCarrozzeriaOn ? Color.purple : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)

                HStack(spacing: isCarModeOn ? 50 : 40) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(isCarModeOn ? .largeTitle : .title)
                            .foregroundColor(.white)
                    }

                    // Play / Pause tugmasi
                    Button(action: {
                        isPlaying.toggle()
                        if let player = player {
                            if isPlaying {
                                player.play()
                            } else {
                                player.pause()
                            }
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: isCarModeOn ? 80 : 64))
                            .foregroundColor(.white)
                    }

                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(isCarModeOn ? .largeTitle : .title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
        // Fayl tanlash oynasini chaqiruvchi modifier
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                
                // Xavfsiz fayl manzilini olish
                if selectedFile.startAccessingSecurityScopedResource() {
                    selectedAudioURL = selectedFile
                    player = AVPlayer(url: selectedFile)
                    player?.play()
                    isPlaying = true
                    selectedFile.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Musiqa ochishda xatolik: \(error.localizedDescription)")
            }
        }
    }
}
