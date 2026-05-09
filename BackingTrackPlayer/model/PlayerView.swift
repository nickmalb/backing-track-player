import SwiftUI

struct PlayerView: View {
    var trackPlayer: TrackPlayer

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(trackPlayer.currentTrack.title)
                    .font(.system(size: 48, weight: .bold))
                    .frame(height: geometry.size.height / 3)

                HStack {
                    Button(action: trackPlayer.rewind) {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 80))
                    }

                    Spacer()

                    Button {
                        trackPlayer.isPlaying ? trackPlayer.stop() : trackPlayer.play()
                    } label: {
                        Image(systemName: trackPlayer.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 144))
                    }

                    Spacer()

                    Button(action: trackPlayer.skip) {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 80))
                    }
                }
                .frame(width: geometry.size.width / 2, height: geometry.size.height / 3)

                ProgressView(value: trackPlayer.currentTime, total: max(trackPlayer.duration, 1))
                    .scaleEffect(y: 4)
                    .frame(width: geometry.size.width * 2 / 3, height: geometry.size.height / 3)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
