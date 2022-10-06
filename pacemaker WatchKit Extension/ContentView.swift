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

    func pacemakerView(geometry: GeometryProxy) -> some View {
        Group {
            HStack {
                menuButton(
                    geometry: geometry,
                    label: store.state.rhythmTypes[store.state.selectedRhythmTypeIndex].unit,
                    value: String(format:"%.2f", store.state.valueByKey(key: store.state.rhythmTypes[store.state.selectedRhythmTypeIndex].key)),
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
                    action: { store.state.activeSubView = "Rhythm" }
                )
            }

            Spacer(minLength: 8)

            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Volume",
                    value: String(store.state.selectedVolume),
                    action: {
                        store.state.activeSubView = "Volume"
                    }
                )

                Spacer(minLength: 8)

                menuButton(
                    geometry: geometry,
                    label: store.state.isAudioPlaying ? "Started" : "Stopped",
                    value: store.state.isAudioPlaying ? "■" : "▶",
                    action: {
                        player.togglePlay()
                    }
                )
            }
        }
    }

    func progressView(geometry: GeometryProxy) -> some View {
        Group {
            Text("progress")
        }
    }

    func rhythmView(geometry: GeometryProxy) -> some View {
        Group {
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
        let toolbarAction = store.state.activeSubView == "Pacemaker"
            ? "Progress"
            : "Pacemaker"

        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    switch(store.state.activeSubView) {
                        case "Pacemaker":
                            pacemakerView(geometry: geometry)

                        case "Progress":
                            progressView(geometry: geometry)

                        case "Rhythm":
                            rhythmView(geometry: geometry)

                        case "Volume":
                            volumeView(geometry: geometry)

                        default:
                            pacemakerView(geometry: geometry)
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))
            }
        }.toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(
                    action: { store.state.activeSubView = toolbarAction },
                    label: { Text("←   " + store.state.activeSubView) }
                )
            }
        })
    }
}
