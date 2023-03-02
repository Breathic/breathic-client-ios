import SwiftUI
import CompactSlider

public struct CustomCompactSliderStyle: CompactSliderStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(
                Color.black
            )
            .background(
                colorize("red").opacity(0.5)
            )
            .accentColor(.orange)
            .compactSliderSecondaryAppearance(
                progressShapeStyle: LinearGradient(
                    colors: [colorize("red"), colorize("red")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                focusedProgressShapeStyle: LinearGradient(
                    colors: [colorize("red"), colorize("red")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                handleColor: colorize("red"),
                scaleColor: colorize("red"),
                secondaryScaleColor: colorize("red")
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .fontWeight(.bold)
    }
}
