import Foundation
import SwiftUI

func menuButton(
    geometry: GeometryProxy,
    label: String = "",
    value: String = "",
    unit: String = "",
    index: Int = -1,
    maxIndex: Int = -1,
    valueColor: Color = Color.white,
    isWide: Bool = false,
    isShort: Bool = false,
    isTall: Bool = true,
    isActive: Bool = false,
    isEnabled: Bool = true,
    opacity: Double = 1,
    action: @escaping () -> Void = {}
) -> some View {
    Button(action: action) {
        VStack {
            Spacer(minLength: 4)

            HStack {
                VStack {
                    if label.count > 0 {
                        HStack {
                            Text(label)
                                .font(.system(size: 10))
                        }
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                    }

                    if value.count > 0 {
                        Spacer(minLength: 8)

                        Text(value)
                            .font(.system(size: isTall ? 32 : isShort ? 12 : 14))
                            .fontWeight(.bold)
                            .foregroundColor(valueColor)
                    }

                    if unit.count > 0 {
                        Text(unit)
                            .frame(maxWidth: .infinity, alignment: Alignment.center)
                            .font(.system(size: 8))
                    }
                }

                if maxIndex > 0 {
                    DottedIndicator(index: index, maxIndex: maxIndex, direction: "vertical")
                }
            }
            .frame(alignment: .center)

            Rectangle()
            .fill(isActive ? .white : .black)
            .frame(width: geometry.size.width / 3 - 4, height: 2)

            Spacer(minLength: 4)
        }
    }
    .frame(width: geometry.size.width / (isWide ? 1 : 2) - 4, height: geometry.size.height / 2 - 4)
    .foregroundColor(.white)
    .tint(.black)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(.gray, lineWidth: isEnabled ? 1 : 0)
    )
    .opacity(opacity)
    .disabled(!isEnabled)
}

struct DottedIndicator: View {
    var index: Int
    let maxIndex: Int
    let direction: String

    var body: some View {
        if direction == "horizontal" {
            HStack(spacing: 4) {
                ForEach(0...maxIndex, id: \.self) { index in
                    Circle()
                    .fill(index == self.index ? Color.white : Color.gray)
                    .frame(width: 8, height: 8)
                }
            }
        }
        else if direction == "vertical" {
            VStack(spacing: 1) {
                ForEach(0...maxIndex, id: \.self) { index in
                    Circle()
                    .fill(index <= self.index ? Color.white : Color.gray)
                    .frame(width: 2, height: 2)
                }
            }
            .rotationEffect(.degrees(-180))
        }
    }
}

func secondaryButton(
    text: String,
    color: String,
    action: @escaping () -> Void = {}
)  -> some View {
    Button(action: action) {
        Text(text)
    }
    .font(.system(size: 12))
    .fontWeight(.bold)
    .buttonStyle(.bordered)
    .tint(colorize(color: color))
}
