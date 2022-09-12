import SwiftUI
import AVFAudio
import AVFoundation

struct ContentView: View {
    @ObservedObject private var store: AppStore = .shared
    
    let player = Player()
    
    func menuButton(
        geometry: GeometryProxy,
        label: String = "",
        value: String = "",
        isWide: Bool = false,
        isTall: Bool = true,
        isActive: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack {
                Spacer(minLength: 4)
                
                if label.count > 0 {
                    titleDetail(text: label, alignment: Alignment.topLeading)
                    .font(.system(size: store.state.ui.primaryTextSize))
                }
                
                if value.count > 0 {
                    Spacer(minLength: 10)
                    
                    Text(value)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                }
                
                Rectangle()
                .fill(isActive ? .white : .black)
                .frame(width: geometry.size.width / 3 - 4, height: 2)
                
                Spacer(minLength: 4)
            }
        }
        .fixedSize()
        .frame(width: geometry.size.width / (isWide ? 1 : 2) - 4, height: geometry.size.height / (isTall ? 2 : 3) - 4)
        .foregroundColor(.white)
        .tint(.black)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: store.state.ui.borderLineWidth)
        )
        .opacity(isEnabled ? 1 : 0.33)
        .disabled(!isEnabled)
    }
        
    func returnToMainDetail(
        geometry: GeometryProxy,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text("⏎")
                .frame(width: 33)
        }
        .frame(height: geometry.size.height / 3)
        .foregroundColor(.white)
        .tint(.black)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
            .stroke(.gray, lineWidth: 1)
        )
    }
    
    func titleDetail(text: String, alignment: Alignment) -> some View {
        Text(text)
        .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    func likesDetail(geometry: GeometryProxy) -> some View {
        ForEach(Array(zip(store.state.likesIds.indices, store.state.likesIds)), id: \.0) { index, like in
            menuButton(
                geometry: geometry,
                value: like,
                isWide: true,
                isTall: false,
                action: {
                    let lastIndex = store.state.playerIndex
                    let wasPlaying = store.state.isAudioPlaying
                    
                    store.state.playerIndex = index
                    player.setLikedPlay(playerIndex: index)
                    
                    player.pause()
                    if !wasPlaying || lastIndex != store.state.playerIndex {
                        player.play()
                    }
                }
            )
             
            Spacer(minLength: 8)
        }
    }

    func mainView(geometry: GeometryProxy) -> some View {
        Group {
            HStack {
                ScrollView(showsIndicators: false) {
                    HStack {
                        menuButton(
                            geometry: geometry,
                            label: store.state.rhythmTypes[store.state.selectedRhythmTypeIndex].unit,
                            value: String(format:"%.1f", store.state.valueByKey(key: store.state.rhythmTypes[store.state.selectedRhythmTypeIndex].key)),
                            action: {
                                store.state.selectedRhythmTypeIndex = store.state.selectedRhythmTypeIndex + 1 < store.state.rhythmTypes.count
                                        ? store.state.selectedRhythmTypeIndex + 1
                                        : 0
                            }
                        )

                        Spacer(minLength: 8)

                        menuButton(
                            geometry: geometry,
                            label: "breath / pace",
                            value: "\(String(format:"%.1f", Double(store.state.selectedInRhythm) / 10)):\(String(format:"%.1f", Double(store.state.selectedOutRhythm) / 10))",
                            action: { store.state.activeSubView = SubView.rhythm }
                        )
                    }

                    Spacer(minLength: 8)

                    HStack {
                        menuButton(
                            geometry: geometry,
                            label: store.state.isAudioPlaying ? "Playing" : "Paused",
                            value: store.state.isAudioPlaying ? "||" : "▶",
                            action: {
                                player.togglePlay()
                            }
                        )

                        Spacer(minLength: 8)

                        menuButton(
                            geometry: geometry,
                            label: "Next",
                            value: "▶|",
                            action: {
                                player.pause()
                                store.state.seeds = player.getAllSeeds(seedInputs: store.state.seedInputs)

                                for (audioIndex, _) in player.audios.enumerated() {
                                    player.flush(audioIndex: audioIndex)
                                    player.next(audioIndex: audioIndex)
                                }

                                player.play()
                            }
                        )
                    }

                    Spacer(minLength: 8)

                    HStack {
                        menuButton(
                            geometry: geometry,
                            label: "Volume",
                            value: String(store.state.selectedVolume),
                            action: {
                                store.state.activeSubView = SubView.volume
                            }
                        )

                        Spacer(minLength: 8)

                    /*
                        menuButton(
                            geometry: geometry,
                            label: store.state.likesIds.contains(String(store.state.seeds[0].rhythms[0].id)) ? "Liked" : "Like",
                            value: store.state.playerIndex > -1 ? "♡" : "♥",
                            isEnabled: store.state.isAudioSessionLoaded,
                            action: {
                                //store.state.playerIndex > -1
                                    //? player.dislike()
                                    //: player.like()
                            }
                        )
                     */

                    }

                    Spacer(minLength: 8)

                    likesDetail(geometry: geometry)
                }
            }
        }
    }

    func rhythmView(geometry: GeometryProxy) -> some View {
        Group {
            HStack {
                returnToMainDetail(
                    geometry: geometry,
                    action: {
                        store.state.activeSubView = SubView.main

                        for (audioIndex, _) in player.audios.enumerated() {
                            player.setChannels(audioIndex: audioIndex)
                        }
                    }
                )
            }
            .font(.system(size: store.state.ui.secondaryTextSize))

            HStack {
                Picker("", selection: $store.state.selectedInRhythm) {
                    ForEach(store.state.rhythmRange, id: \.self) {
                        if $0 == store.state.selectedInRhythm {
                            Text(String(format:"%.1f", Double($0) / 10))
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                        }
                        else {
                            Text(String(format:"%.1f", Double($0) / 10))
                            .font(.system(size: 12))
                        }
                    }
                }
                .padding(.horizontal, store.state.ui.horizontalPadding)
                .padding(.vertical, store.state.ui.verticalPadding)
                .frame(width: geometry.size.width * store.state.ui.width, height: geometry.size.height * store.state.ui.height)
                .clipped()
                .onChange(of: store.state.selectedInRhythm) { value in
                    store.state.selectedInRhythm = value
                    store.state.selectedOutRhythm = value
                }
                
                Picker("", selection: $store.state.selectedOutRhythm) {
                    ForEach(store.state.rhythmRange, id: \.self) {
                        if $0 == store.state.selectedOutRhythm {
                            Text(String(format:"%.1f", Double($0) / 10))
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                        }
                        else {
                            Text(String(format:"%.1f", Double($0) / 10))
                            .font(.system(size: 12))
                        }
                    }
                }
                .padding(.horizontal, store.state.ui.horizontalPadding)
                .padding(.vertical, store.state.ui.verticalPadding)
                .frame(width: geometry.size.width * store.state.ui.width, height: geometry.size.height * store.state.ui.height)
                .clipped()
                .onChange(of: store.state.selectedOutRhythm) { value in
                    store.state.selectedOutRhythm = value
                }
            }
            .font(.system(size: store.state.ui.secondaryTextSize))
        }
    }

    func volumeView(geometry: GeometryProxy) -> some View {
        Group {
            HStack {
                returnToMainDetail(
                    geometry: geometry,
                    action: { store.state.activeSubView = SubView.main }
                )
            }
            .font(.system(size: store.state.ui.secondaryTextSize))

            Picker("", selection: $store.state.selectedVolume) {
                ForEach(Array(0...100), id: \.self) {
                    if $0 == store.state.selectedVolume {
                        Text(String($0))
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                    }
                    else {
                        Text(String($0))
                        .font(.system(size: 12))
                    }
                }
            }
            .padding(.horizontal, store.state.ui.horizontalPadding)
            .padding(.vertical, store.state.ui.verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
            .clipped()
            .font(.system(size: store.state.ui.secondaryTextSize))
        }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack() {
                switch(store.state.activeSubView) {
                    case SubView.main:
                        mainView(geometry: geometry)
                    
                    case SubView.rhythm:
                        rhythmView(geometry: geometry)
                    
                    case SubView.volume:
                        volumeView(geometry: geometry)
                }
            }
            .font(.system(size: store.state.ui.secondaryTextSize))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
