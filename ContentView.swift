import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// Internetdan qidirish uchun model
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
    
    // Lokal fayl uchun o'zgaruvchilar
    @State private var isImporterPresented = false
    @State private var selectedAudioURL: URL?
    
    // Internet qidiruvi uchun o'zgaruvchilar
    @State private var searchQuery = ""
    @State private var songs: [Song] = []
    @State private var selectedSong: Song?
    
    // Umumiy pleyer
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
                // Yuqori panel: Fayl yuklash va Car Mode
                HStack {
                    Text("CARROZZERIA")
                        .font(.system(size: 16, weight: .bold))
                        .tracking(2)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Telefon xotirasidan ochish
                    Button(action: { isImporterPresented.toggle() }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 5)
                    
                    // Car Mode tugmasi
                    Button(action: { isCarModeOn.toggle() }) {
                        Image(systemName: isCarModeOn ? "car.fill" : "car")
                            .font(.title2)
                            .foregroundColor(isCarModeOn ? .purple : .white)
                    }
                }
                .padding(.horizontal)

                // Internetdan qidirish paneli
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

                // Agar qidiruv natijalari bo'lsa - ro'yxatni ko'rsatish
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
                    .frame(height: 150)
                    .scrollContentBackground(.hidden)
                }

                Spacer()

                // Markaziy vizualizator va albom qismi
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(colors: [.purple.opacity(0.5), .blue.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: isCarModeOn ? 260 : 180, height: isCarModeOn ? 260 : 180)
                        .shadow(color: .purple.opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        
                        // Ekvalayzer animatsiyasi
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white)
                                    .frame(width: 4, height: isPlaying ? CGFloat.random(in: 15...40) : 8)
                                    .animation(isPlaying ? .easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.1) : .default, value: isPlaying)
                            }
                        }
                        .padding(.top, 8)
                    }
                }

                // Trek nomi
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
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(isCarrozzeriaOn ? Color.purple : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Pleyer boshqaruv tugmalari
                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill").font(.title).foregroundColor(.white)
                    }

                    Button(action: {
                        isPlaying.toggle()
                        if let player = player {
                            if isPlaying { player.play() } else { player.pause() }
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                    }

                    Button(action: {}) {
                        Image(systemName: "forward.fill").font(.title).foregroundColor(.white)
                    }
                }

                Spacer()
            }
            .padding()
        }
        // Telefon xotirasidan fayl tanlash oynasi
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

    // Internetdan qidirish funksiyasi
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
                print("Deserializatsiya xatoligi: \(error)")
            }
        }.resume()
    }

    // Onlayn musiqani ijro etish
    func playOnlineSong(song: Song) {
        guard let url = URL(string: song.previewUrl) else { return }
        selectedSong = song
        selectedAudioURL = nil
        player = AVPlayer(url: url)
        player?.play()
        isPlaying = true
    }
}
