import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isPlaying = false
    @State private var isCarrozzeriaOn = false
    @State private var volume: Double = 0.7

    var body: some View {
        ZStack {
            // To'q qora / Yandex Music uslubidagi fon
            Color.black.ignoresSafeArea()

            VBoxLayout(spacing: 25) {
                // Sarlavha
                Text("CARROZZERIA PLAYER")
                .font(.system(size: 18, weight: .bold))
                .tracking(2)
                .foregroundColor(.white)

                // Albom muqovasi (Simulyatsiya)
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.gray.opacity(0.3), .purple.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 250, height: 250)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.8))
                }
                .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 10)

                // Track nomi
                VStack(spacing: 5) {
                    Text("Konsert Zali Trangi")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Text("iPhone 13 Pro Max Audio")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                // Carrozzeria Reverb tugmasi
                Button(action: {
                    isCarrozzeriaOn.toggle()
                }) {
                    HStack {
                        Image(systemName: isCarrozzeriaOn ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        Text(isCarrozzeriaOn ? "Carrozzeria: YOQILGAN (Reverb Active)" : "Carrozzeria: O'CHIRILGAN")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isCarrozzeriaOn ? Color.purple : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)

                // Boshqaruv tugmalari (Play/Pause)
                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                    }

                    Button(action: {}) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
