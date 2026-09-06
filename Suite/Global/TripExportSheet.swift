import SwiftUI
import PDFKit

/// Pro export — turns a trip's packing list into a PDF and hands it to the
/// system share sheet (Messages, Mail, Files, Print…).
struct TripExportSheet: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @State private var pdfURL: URL?
    @State private var preview: Image?
    @State private var failed = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    SuiteIconView(icon: .close, size: 18, color: Theme.Palette.textPrimary)
                        .frame(width: 42, height: 42)
                        .overlay(Circle().strokeBorder(Theme.Palette.border))
                }
                .accessibilityLabel("Close")
                Text("Export packing list")
                    .font(.Suite.titleS).tracking(22 * -0.02)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)

            ScrollView {
                Group {
                    if let preview {
                        preview
                            .resizable()
                            .aspectRatio(595.0 / 842.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Palette.border))
                            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                    } else if failed {
                        Text("Couldn't build the PDF.")
                            .font(.Suite.bodyS).foregroundStyle(Theme.Palette.danger)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)
            }

            if let pdfURL {
                ShareLink(item: pdfURL,
                          preview: SharePreview("\(trip.name) — packing list",
                                                image: Image(systemName: "doc.text"))) {
                    Text("Share PDF")
                        .font(.Suite.button)
                        .foregroundStyle(Theme.Palette.onAccent)
                        .frame(maxWidth: .infinity).frame(height: Theme.Size.cta)
                        .background(Theme.Palette.accent, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
        .background(Theme.Palette.ground.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .task { await build() }
    }

    @MainActor
    private func build() async {
        let doc = PackingListDocument.from(trip: trip)
        guard let url = makePackingListPDF(doc, name: "\(trip.name) packing list") else {
            failed = true; return
        }
        pdfURL = url
        if let page = PDFDocument(url: url)?.page(at: 0) {
            let bounds = page.bounds(for: .mediaBox)
            let ui = page.thumbnail(of: CGSize(width: bounds.width * 2, height: bounds.height * 2),
                                    for: .mediaBox)
            preview = Image(uiImage: ui)
        }
    }
}
