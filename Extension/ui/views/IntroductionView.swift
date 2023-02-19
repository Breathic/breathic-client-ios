import SwiftUI

func introductionView(geometry: GeometryProxy, store: Store) -> some View {
    Text("Press and hold Session from the Controller to start.")
        .foregroundColor(Color.white)
        .font(.system(size: 12))
        .frame(minWidth: geometry.size.width, maxHeight: .infinity)
        .background(colorize("black"))
}
