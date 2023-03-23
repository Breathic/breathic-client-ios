import SwiftUI

func introductionView(geometry: GeometryProxy, store: Store) -> some View {
    Text("Press and hold Session from the Controller to start and to finish.")
        .foregroundColor(Color.white)
        .font(.system(size: 12))
        .frame(minWidth: geometry.size.width, minHeight: geometry.size.height + 8)
        .background(colorize("black"))
}
