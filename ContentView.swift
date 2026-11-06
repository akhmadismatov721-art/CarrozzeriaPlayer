import SwiftUI
import AVFoundation

struct Song: Codable, Identifiable {
    var id: Int { trackId }
    let trackId: Int
    let trackName: String
    let artistName: String
    let previewUrl: String
    let artworkUrl100: String
}

struct ContentView: View {
    @State private var searchQuery = ""
    @State private var songs: [Song] = []
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var selectedSong: Song?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                // Qidiruv paneli
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Musiqa yoki ijrochi nomi...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .onSubmit {
                            searchMusic(query: searchQuery)
                        }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal)

                // Topilgan musiqalar ro'yxati
                List(songs) { song in
                    HStack {
                        AsyncImage(url: URL(string: song.artworkUrl100)) { image in
                            image.resizable()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)

                        VStack(alignment: .leading) {
                            Text(song.trackName)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(song.artistName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: {
                            playPreview(song: song)
                        }) {
                            Image(systemName: selectedSong?.id == song.id && isPlaying ? "pause.fill" : "play.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                        }
                    }
                    .listRowBackground(Color.black)
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    // Internetdan musiqa qidirish funksiyasi
    func searchMusic(query: String) {
        let formattedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(formattedQuery)&entity=song&limit=10") else { return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let result = try JSONDecoder().decodeSearchResult(from: data)
                DispatchQueue.main.async {
                    self.songs = result.results
                }
            } catch {
                print("Xatolik: \(error)")
            }
        }.resume()
    }

    // Musiqani onlayn ijro etish
    func playPreview(song: Song) {
        guard let url = URL(string: song.previewUrl) else { return }
        
        if selectedSong?.id == song.id {
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player?.play()
                isPlaying = true
            }
        } else {
            player = AVPlayer(url: url)
            player?.play()
            selectedSong = song
            isPlaying = true
        }
    }
}

struct SearchResult: Codable {
    let results: [Song]
}

extension JSONDecoder {
    func decodeSearchResult(from data: Data) throws -> SearchResult {
        return try self.decode(SearchResult.self, from: data)
    }
}
