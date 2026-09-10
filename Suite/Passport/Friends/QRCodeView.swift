import SwiftUI
import CoreImage.CIFilterBuiltins

/// The personal invite QR — amber modules on a near-black field, matching the
/// app's base/accent pair. Rendered from `text` (the invite URL).
struct QRCodeView: View {
    var text: String
    var size: CGFloat = 190

    private static let context = CIContext()

    var body: some View {
        Image(uiImage: render())
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private func render() -> UIImage {
        let generator = CIFilter.qrCodeGenerator()
        generator.message = Data(text.utf8)
        generator.correctionLevel = "M"
        guard let base = generator.outputImage else { return UIImage() }

        let scaled = base.transformed(by: CGAffineTransform(scaleX: 12, y: 12))

        // Amber modules on a near-black field: color0 replaces the QR's black
        // (the modules), color1 its white (the background).
        let tint = CIFilter.falseColor()
        tint.inputImage = scaled
        tint.color0 = CIColor(red: 0.816, green: 0.604, blue: 0.259)   // #D09A42 amber
        tint.color1 = CIColor(red: 0.039, green: 0.039, blue: 0.039)   // #0A0A0A

        guard let output = tint.outputImage,
              let cg = Self.context.createCGImage(output, from: output.extent)
        else { return UIImage() }
        return UIImage(cgImage: cg)
    }
}
