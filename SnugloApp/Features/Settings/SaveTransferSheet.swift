import SwiftUI

// MARK: — SaveTransferSheet
// Backup / restore the local save via a portable code. Self-contained: copy or
// share the export code, paste one in to restore. Single-palette, localized.

struct SaveTransferSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var exportCode = ""
    @State private var importText = ""
    @State private var showRestoredAlert = false
    @State private var showInvalidAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {

                    // — Export —
                    sectionCard {
                        Label("transfer.backup.title", systemImage: "arrow.up.doc.fill")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onSurface)
                        Text("transfer.backup.desc")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        Text(verbatim: exportCode)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .lineLimit(4)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceContainerLow,
                                        in: RoundedRectangle(cornerRadius: AppRadius.block))
                            .textSelection(.enabled)
                            // Don't let VoiceOver spell out the whole base64 blob.
                            .accessibilityLabel(Text("transfer.backup.title"))

                        HStack(spacing: AppSpacing.sm) {
                            Button {
                                UIPasteboard.general.string = exportCode
                                HapticService.shared.notify(.success)
                            } label: {
                                Label("transfer.copy", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GameButtonStyle(variant: .primary, compact: true))

                            if !exportCode.isEmpty {
                                ShareLink(item: exportCode) {
                                    Label("transfer.share", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GameButtonStyle(variant: .muted, compact: true))
                            }
                        }
                    }

                    // — Import —
                    sectionCard {
                        Label("transfer.restore.title", systemImage: "arrow.down.doc.fill")
                            .font(AppTypography.headlineSmall)
                            .foregroundStyle(AppColors.onSurface)
                        Text("transfer.restore.desc")
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        TextEditor(text: $importText)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(height: 96)
                            .scrollContentBackground(.hidden)
                            .padding(AppSpacing.xs)
                            .background(AppColors.surfaceContainerLow,
                                        in: RoundedRectangle(cornerRadius: AppRadius.block))

                        Button {
                            handleRestore()
                        } label: {
                            Label("transfer.restore.action", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GameButtonStyle(variant: .primary, compact: true))
                        .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Text("transfer.note")
                        .font(AppTypography.labelSmall)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("transfer.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.close") { dismiss() }
                }
            }
        }
        .onAppear { exportCode = SaveTransfer.export() ?? "" }
        .alert("transfer.restored.title", isPresented: $showRestoredAlert) {
            Button("common.ok") { dismiss() }
        } message: {
            Text("transfer.restored.message")
        }
        .alert("transfer.invalid.title", isPresented: $showInvalidAlert) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("transfer.invalid.message")
        }
    }

    private func handleRestore() {
        switch SaveTransfer.importCode(importText) {
        case .success:
            HapticService.shared.notify(.success)
            showRestoredAlert = true
        case .invalid:
            HapticService.shared.notify(.error)
            showInvalidAlert = true
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            content()
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceContainerLowest,
                    in: RoundedRectangle(cornerRadius: AppRadius.card))
        .shadowL1()
    }
}
