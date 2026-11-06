import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct Song: Codable, Identifiable {
    var id: Int { trackId }
    let trackId: Int
    let trackName: String
    let artistName: String
    let previewUrl: String
    let artworkUrl100: String
}

struct SearchResult: Codable {
    let results: [Song]
}

struct ContentView: View {
    @State private var isPlaying = false
    @State private var isCarrozzeriaOn = false
    @State private var isCarModeOn = false
    
    // Takrorlash va Shuffle rejimlari
    @State private var isLoopEnabled = false
    @State private var isShuffleEnabled = false
    
    // Lokal va Internet musiqalari
    @State private var isImporterPresented = false
    @State private var selectedAudioURL: URL?
    @State private var searchQuery = ""
    @State private var songs: [Song] = []
    @State private var selectedSong: Song?
    
    @State private var player: AVPlayer?
    
    // Progress Bar uchun o'zgaruvchilar
    @State private var playbackProgress: Double = 0.0
    @State private var trackDuration: Double = 1.0
    @State private var timeObserverToken: Any?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isCarrozzeriaOn ? [.black, .purple.opacity(0.6), .black] : [.black, .gray.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Yuqori panel
                HStack {
                    Text("CARROZZERIA")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isImporterPresented.toggle() }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 5)
                    
                    Button(action: { isCarModeOn.toggle() }) {
                        Image(systemName: isCarModeOn ? "car.fill" : "car")
                            .font(.title2)
                            .foregroundColor(isCarModeOn ? .purple : .white)
                    }
                }
                .padding(.horizontal)

                // Qidiruv paneli
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Internetdan musiqa qidirish...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .onSubmit {
                            searchMusic(query: searchQuery)
                        }
                }
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)

                // Qidiruv natijalari ro'yxati
                if !songs.isEmpty && !isCarModeOn {
                    List(songs) { song in
                        HStack {
                            AsyncImage(url: URL(string: song.artworkUrl100)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 40, height: 40)
                            .cornerRadius(6)

                            VStack(alignment: .leading) {
                                Text(song.trackName)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(song.artistName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Button(action: { playOnlineSong(song: song) }) {
                                Image(systemName: selectedSong?.id == song.id && isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.title2)
                            }
                        }
                        .listRowBackground(Color.black.opacity(0.5))
                    }
                    .frame(height: 120)
                    .scrollContentBackground(.hidden)
                }

                Spacer()

                // Markaziy vizualizator
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: isCarModeOn ? 220 : 150, height: isCarModeOn ? 220 : 150)
                        .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 4, height: isPlaying ? CGFloat.random(in: 10...30) : 6)
                                    .animation(isPlaying ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.1) : .default, value: isPlaying)
                            }
                        }
                        .padding(.top, 6)
                    }
                }

                // Trek ma'lumotlari
                VStack(spacing: 4) {
                    Text(selectedSong?.trackName ?? selectedAudioURL?.lastPathComponent ?? "Musiqa tanlanmagan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(selectedSong?.artistName ?? (isCarModeOn ? "Avtomobil rejimi Faol" : "Carrozzeria Hi-Fi"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Progress Bar (Slayder va vaqt ko'rsatkichi)
                VStack(spacing: 4) {
                    Slider(value: $playbackProgress, in: 0...trackDuration, onEditingChanged: { editing in
                        if let player = player, !editing {
                            let targetTime = CMTime(seconds: playbackProgress, preferredTimescale: 600)
                            player.seek(to: targetTime)
                        }
                    })
                    .accentColor(.purple)

                    HStack {
                        Text(formatTime(seconds: playbackProgress))
                        Spacer()
                        Text(formatTime(seconds: trackDuration))
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)

                // Carrozzeria Reverb tugmasi
                Button(action: { isCarrozzeriaOn.toggle() }) {
                    HStack {
                        Image(systemName: isCarrozzeriaOn ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        Text(isCarrozzeriaOn ? "Akustika: Carrozzeria YOQILGAN" : "Akustika: Standart")
                            .fontWeight(.medium)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(isCarrozzeriaOn ? Color.purple : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Asosiy pleyer boshqaruv tugmalari
                HStack(spacing: 25) {
                    Button(action: { isShuffleEnabled.toggle() }) {
                        Image(systemName: "shuffle")
                            .font(.title3)
                            .foregroundColor(isShuffleEnabled ? .purple : .gray)
                    }

                    Button(action: {}) {
                        Image(systemName: "backward.fill").font(.title2).foregroundColor(.white)
                    }

                    Button(action: {
                        isPlaying.toggle()
                        if let player = player {
                            if isPlaying { player.play() } else { player.pause() }
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.white)
                    }

                    Button(action: {}) {
                        Image(systemName: "forward.fill").font(.title2).foregroundColor(.white)
                    }

                    Button(action: { isLoopEnabled.toggle() }) {
                        Image(systemName: isLoopEnabled ? "repeat.1" : "repeat")
                            .font(.title3)
                            .foregroundColor(isLoopEnabled ? .purple : .gray)
                    }
                }
                .padding(.top, 2)

                Spacer()
            }
            .padding()
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                if selectedFile.startAccessingSecurityScopedResource() {
                    selectedAudioURL = selectedFile
                    selectedSong = nil
                    setupPlayer(url: selectedFile)
                    selectedFile.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Xatolik: \(error.localizedDescription)")
            }
        }
    }

    // Pleyer sozlash va vaqtni kuzatish
    func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
        
        // Davomiyligini aniqlash
        let asset = AVAsset(url: url)
        Task {
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)
                await MainActor.run {
                    self.trackDuration = seconds.isNaN ? 0.0 : seconds
                }
            } catch {
                print("Duration error: \(error)")
            }
        }

        // Har soniyada vaqtni yangilab borish
        if let observer = timeObserverToken {
            player?.removeTimeObserver(observer)
        }
        
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            let currentSeconds = CMTimeGetSeconds(time)
            if !currentSeconds.isNaN {
                self.playbackProgress = currentSeconds
            }
        }
    }

    func searchMusic(query: String) {
        let formattedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(formattedQuery)&entity=song&limit=5") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let result = try JSONDecoder().decode(SearchResult.self, from: data)
                DispatchQueue.main.async {
                    self.songs = result.results
                }
            } catch {
                print("Xatolik: \(error)")
            }
        }.resume()
    }

    func playOnlineSong(song: Song) {
        guard let url = URL(string: song.previewUrl) else { return }
        selectedSong = song
        selectedAudioURL = nil
        setupPlayer(url: url)
    }

    // Sekundlarni daqiqa va soniyaga o'tkazish formatlovchisi
    func formatTime(seconds: Double) -> String {
        guard !seconds.isNaN else { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
