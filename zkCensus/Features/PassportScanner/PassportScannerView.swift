import SwiftUI
import UIKit
import AVFoundation

struct PassportScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var scanner = PassportScannerService()
    @StateObject private var zkProofService = ZKProofService.shared

    @State private var scanMode: ScanMode = .camera
    @State private var scannedPassport: PassportData?
    @State private var selectedCensus: CensusMetadata?
    @State private var generatedProof: CensusProof?
    @State private var showCensusSelection = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentStep: ScanStep = .selectMode
    @State private var showCamera = false
    @State private var capturedImage: UIImage?

    enum ScanMode {
        case camera
        case nfc
    }

    enum ScanStep {
        case selectMode
        case scanning
        case selectCensus
        case generatingProof
        case submittingProof
        case complete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Indicator
                ProgressStepView(currentStep: currentStep)
                    .padding()

                // Main Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch currentStep {
                        case .selectMode:
                            scanModeSelectionView
                        case .scanning:
                            scanningView
                        case .selectCensus:
                            censusSelectionView
                        case .generatingProof:
                            proofGenerationView
                        case .submittingProof:
                            proofSubmissionView
                        case .complete:
                            completionView
                        }
                    }
                    .padding()
                }

                // Action Button
                if currentStep != .complete {
                    actionButton
                        .padding()
                }
            }
            .navigationTitle("Scan Passport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        cleanup()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.black)
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
                .ignoresSafeArea()
        }
        .onChange(of: capturedImage) { newImage in
            if let image = newImage {
                processCapturedImage(image)
            }
        }
    }

    // MARK: - Scan Mode Selection

    private var scanModeSelectionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("How would you like to scan?")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 16) {
                ScanModeCard(
                    title: "Camera (OCR)",
                    description: "Scan the passport photo page with your camera",
                    icon: "camera.fill",
                    isSelected: scanMode == .camera
                ) {
                    scanMode = .camera
                }

                ScanModeCard(
                    title: "NFC Chip",
                    description: "Read passport chip for enhanced verification",
                    icon: "wave.3.right",
                    isSelected: scanMode == .nfc
                ) {
                    scanMode = .nfc
                }
            }

            InfoBox(
                icon: "shield.fill",
                title: "Privacy First",
                message: "All scanning happens on your device. Passport data is never transmitted.",
                color: .green
            )
        }
    }

    // MARK: - Scanning View

    private var scanningView: some View {
        VStack(spacing: 24) {
            if scanMode == .camera {
                cameraView
            } else {
                nfcInstructionsView
            }

            if scanner.isScanning {
                VStack(spacing: 12) {
                    ProgressView(value: scanner.scanProgress)
                        .progressViewStyle(LinearProgressViewStyle())

                    Text(scanner.scanStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var cameraView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Position passport photo page")
                .font(.headline)

            Text("Make sure the MRZ (machine readable zone) at the bottom is clearly visible")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Placeholder for camera preview
            Rectangle()
                .fill(Color.black)
                .frame(height: 300)
                .cornerRadius(12)
                .overlay(
                    Image(systemName: "viewfinder")
                        .font(.system(size: 100))
                        .foregroundColor(.white.opacity(0.5))
                )
        }
    }

    private var nfcInstructionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Hold passport to phone")
                .font(.headline)

            Text("Place your passport on the back of your iPhone and hold it steady")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Image("nfc_guide") // Placeholder
                .resizable()
                .scaledToFit()
                .frame(height: 200)
        }
    }

    // MARK: - Census Selection

    private var censusSelectionView: some View {
        VStack(spacing: 16) {
            Text("Select Census")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose which census you want to join")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // In production, fetch from API
            CensusSelectorList(selectedCensus: $selectedCensus)
        }
    }

    // MARK: - Proof Generation

    private var proofGenerationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cpu")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Generating Zero-Knowledge Proof")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This may take 30-60 seconds")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                ProgressView(value: zkProofService.proofProgress)
                    .progressViewStyle(LinearProgressViewStyle())

                Text(zkProofService.proofStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            InfoBox(
                icon: "lock.fill",
                title: "Computing on your device",
                message: "Your passport data remains private and is being processed locally",
                color: .blue
            )
        }
    }

    // MARK: - Proof Submission

    private var proofSubmissionView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Submitting Proof")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Signing transaction and sending to blockchain...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Success!")
                .font(.title)
                .fontWeight(.bold)

            Text("Your zero-knowledge proof has been submitted successfully")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let census = selectedCensus {
                VStack(spacing: 8) {
                    Text("Joined Census")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(census.name)
                        .font(.headline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }

            Button {
                cleanup()
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button {
            handleAction()
        } label: {
            HStack {
                if scanner.isScanning || zkProofService.isGeneratingProof {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(actionButtonTitle)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(actionButtonEnabled ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!actionButtonEnabled)
    }

    private var actionButtonTitle: String {
        switch currentStep {
        case .selectMode:
            return "Start Scan"
        case .scanning:
            return scanner.isScanning ? "Scanning..." : "Continue"
        case .selectCensus:
            return "Continue"
        case .generatingProof:
            return "Generating..."
        case .submittingProof:
            return "Submitting..."
        case .complete:
            return "Done"
        }
    }

    private var actionButtonEnabled: Bool {
        switch currentStep {
        case .selectMode:
            return true
        case .scanning:
            return !scanner.isScanning && scannedPassport != nil
        case .selectCensus:
            return selectedCensus != nil
        case .generatingProof, .submittingProof:
            return false
        case .complete:
            return true
        }
    }

    // MARK: - Actions

    private func handleAction() {
        switch currentStep {
        case .selectMode:
            startScan()
        case .scanning:
            currentStep = .selectCensus
        case .selectCensus:
            generateProof()
        case .generatingProof, .submittingProof:
            break
        case .complete:
            cleanup()
            dismiss()
        }
    }

    private func startScan() {
        if scanMode == .camera {
            showCamera = true
        } else {
            // NFC scan
            currentStep = .scanning
            // let nfcData = try await scanner.scanPassportWithNFC(...)
        }
    }

    private func processCapturedImage(_ image: UIImage) {
        currentStep = .scanning
        
        Task {
            do {
                let passport = try await scanner.scanPassportWithOCR(from: image)
                scannedPassport = passport
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func generateProof() {
        guard let passport = scannedPassport,
              let census = selectedCensus else {
            return
        }

        currentStep = .generatingProof

        Task {
            do {
                let secret = KeychainManager.shared.generateAndSaveNullifierSecret()
                let circuitInput = passport.toCircuitInput(
                    censusId: census.id,
                    nullifierSecret: secret
                )

                let proof = try await zkProofService.generateProof(from: circuitInput)
                generatedProof = proof

                await submitProof(proof)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                currentStep = .selectCensus
            }
        }
    }

    private func submitProof(_ proof: CensusProof) async {
        guard let census = selectedCensus else { return }

        currentStep = .submittingProof

        do {
            // Sign with Solana wallet
            let signature = try await SolanaService.shared.signMessage("Submit ZK Proof")

            let request = SubmitProofRequest(
                censusId: census.id,
                proof: proof,
                signature: signature,
                publicKey: SolanaService.shared.walletAddress ?? ""
            )

            _ = try await APIClient.shared.submitProof(request)

            currentStep = .complete
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            currentStep = .selectCensus
        }
    }

    private func cleanup() {
        scanner.clearAllPassportData()
        zkProofService.resetState()
        scannedPassport = nil
        generatedProof = nil
    }
}

// MARK: - Supporting Views

struct ProgressStepView: View {
    let currentStep: PassportScannerView.ScanStep

    var body: some View {
        HStack(spacing: 8) {
            StepIndicator(
                number: 1,
                title: "Scan",
                isActive: currentStep.rawValue >= PassportScannerView.ScanStep.scanning.rawValue
            )

            Divider()
                .frame(width: 30, height: 2)
                .background(Color.gray)

            StepIndicator(
                number: 2,
                title: "Census",
                isActive: currentStep.rawValue >= PassportScannerView.ScanStep.selectCensus.rawValue
            )

            Divider()
                .frame(width: 30, height: 2)
                .background(Color.gray)

            StepIndicator(
                number: 3,
                title: "Proof",
                isActive: currentStep.rawValue >= PassportScannerView.ScanStep.generatingProof.rawValue
            )

            Divider()
                .frame(width: 30, height: 2)
                .background(Color.gray)

            StepIndicator(
                number: 4,
                title: "Submit",
                isActive: currentStep.rawValue >= PassportScannerView.ScanStep.complete.rawValue
            )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

extension PassportScannerView.ScanStep: Comparable {
    var rawValue: Int {
        switch self {
        case .selectMode: return 0
        case .scanning: return 1
        case .selectCensus: return 2
        case .generatingProof: return 3
        case .submittingProof: return 4
        case .complete: return 5
        }
    }

    static func < (lhs: PassportScannerView.ScanStep, rhs: PassportScannerView.ScanStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct StepIndicator: View {
    let number: Int
    let title: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.caption2)
                .foregroundColor(isActive ? .primary : .secondary)
        }
    }
}

struct ScanModeCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct CensusSelectorList: View {
    @Binding var selectedCensus: CensusMetadata?
    @State private var censuses: [CensusMetadata] = []

    var body: some View {
        VStack(spacing: 12) {
            ForEach(censuses) { census in
                Button {
                    selectedCensus = census
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(census.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(census.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        if selectedCensus?.id == census.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(selectedCensus?.id == census.id ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .task {
            await loadCensuses()
        }
    }

    private func loadCensuses() async {
        do {
            let all = try await APIClient.shared.listCensuses()
            censuses = all.filter { $0.active }
        } catch {
            print("Failed to load censuses: \(error)")
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .camera

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    PassportScannerView()
}
