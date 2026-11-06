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
    
    // Takrorlash va Shuffle rejimlari uchun o'zgaruvchilar
    @State private var isLoopEnabled = false
    @State private var isShuffleEnabled = false
    
    // Lokal va internet musiqalari uchun
    @State private var isImporterPresented = false
    @State private var selectedAudioURL: URL?
    @State private var searchQuery = ""
    @State private var songs: [Song] = []
    @State private var selectedSong: Song?
    
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isCarrozzeriaOn ? [.black, .purple.opacity(0.6), .black] : [.black, .gray.opacity(0.3), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 15) {
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
                    .frame(height: 140)
                    .scrollContentBackground(.hidden)
                }

                Spacer()

                // Markaziy vizualizator
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: isCarModeOn ? 240 : 160, height: isCarModeOn ? 240 : 160)
                        .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 45))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 4, height: isPlaying ? CGFloat.random(in: 12...35) : 8)
                                    .animation(isPlaying ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.1) : .default, value: isPlaying)
                            }
                        }
                        .padding(.top, 8)
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

                // Asosiy pleyer boshqaruv tugmalari (Shuffle va Loop qo'shilgan)
                HStack(spacing: 25) {
                    // Shuffle tugmasi
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

                    // Loop (Takrorlash) tugmasi
                    Button(action: { isLoopEnabled.toggle() }) {
                        Image(systemName: isLoopEnabled ? "repeat.1" : "repeat")
                            .font(.title3)
                            .foregroundColor(isLoopEnabled ? .purple : .gray)
                    }
                }
                .padding(.top, 5)

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
                    player = AVPlayer(url: selectedFile)
                    player?.play()
                    isPlaying = true
                    selectedFile.stopAccessingSecurityScopedResource()
                }
            } catch {
                print("Xatolik: \(error.localizedDescription)")
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
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
    }
}
