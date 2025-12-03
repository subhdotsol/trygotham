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
    // @State private var selectedCensus: CensusMetadata? // Removed
    // @State private var generatedProof: CensusProof? // Removed
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
        case scanning // Camera/census step
        case proofPreview // Proof step
        case submitting // Submit step
        case complete // NFT received
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
                        case .proofPreview:
                            proofPreviewView
                        case .submitting:
                            submittingView
                        case .complete:
                            nftReceivedView
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
                    Button("Cancel") {
                        Task { @MainActor in
                            cleanup()
                            presentationMode.wrappedValue.dismiss()
                        }
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

    // MARK: - Submitting View

    private var submittingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Submitting Proof On-Chain")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Please wait while we verify your proof and mint your NFT...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - NFT Received View

    private var nftReceivedView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Ghost NFT Image
            Image("gotham_nft")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .cornerRadius(20)
                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 16) {
                Text("NFT Received!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("You have verified your document.")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Text("Now you are a part of Gotham City.")
                    .font(.title3)
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("You are a Ghost now 👻")
                    .font(.title2)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()

            Button {
                Task { @MainActor in
                    cleanup()
                    presentationMode.wrappedValue.dismiss()
                }
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    // MARK: - Proof Preview

    private var proofPreviewView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Passport Scanned Successfully")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Review your proof details below")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Proof Details Card
            VStack(spacing: 20) {
                ProofDetailRow(
                    icon: "person.fill",
                    label: "Public Key",
                    value: "7Xw...39a"
                )

                Divider()

                ProofDetailRow(
                    icon: "calendar",
                    label: "Age Range",
                    value: getAgeRangeString()
                )

                Divider()

                ProofDetailRow(
                    icon: "globe",
                    label: "Region",
                    value: getContinentString()
                )

                Divider()

                ProofDetailRow(
                    icon: "doc.text.fill",
                    label: "Passport Number",
                    value: getMaskedPassportNumber()
                )
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            InfoBox(
                icon: "lock.shield.fill",
                title: "Zero-Knowledge Proof",
                message: "Your sensitive data remains private. Only the proof of eligibility will be submitted on-chain.",
                color: .blue
            )
        }
    }

    private func getAgeRangeString() -> String {
        guard let passport = scannedPassport else { return "18 - 24" }
        let ageRange = passport.ageRange
        return ageRange.displayName
    }

    private func getContinentString() -> String {
        guard let passport = scannedPassport else { return "South America" }
        let continent = passport.continent
        return continent.displayName
    }

    private func getMaskedPassportNumber() -> String {
        guard let passport = scannedPassport else { return "*****************42" }
        let number = passport.documentNumber
        if number.count >= 2 {
            let lastTwo = String(number.suffix(2))
            return String(repeating: "*", count: max(0, number.count - 2)) + lastTwo
        }
        return number
    }

    // MARK: - Census Selection (Removed)
    // MARK: - Proof Generation (Removed)
    // MARK: - Proof Submission (Removed)
    // MARK: - Completion (Removed)

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
        case .proofPreview:
            return "Submit On Chain"
        case .submitting:
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
        case .proofPreview:
            return true
        case .submitting:
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
            currentStep = .proofPreview
        case .proofPreview:
            submitProofOnChain()
        case .submitting:
            break
        case .complete:
            cleanup()
            dismiss()
        }
    }

    private func startScan() {
        currentStep = .scanning
        
        // On simulator, skip camera and show mock data directly
        #if targetEnvironment(simulator)
        // Simulate a brief scanning delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            createMockPassportData()
            currentStep = .proofPreview
        }
        #else
        if scanMode == .camera {
            showCamera = true
        } else {
            // NFC scan
            // let nfcData = try await scanner.scanPassportWithNFC(...)
        }
        #endif
    }
    
    private func createMockPassportData() {
        // Create mock passport data for testing
        scannedPassport = PassportData(
            documentNumber: "AB1234567890142",
            documentType: "P",
            issuingCountry: "BRA",
            surname: "7Xw...39a", // Public Key
            givenNames: "Wallet",
            nationality: "BRA", // Brazil (South America)
            dateOfBirth: Date(timeIntervalSince1970: 1000000000), // ~2001
            sex: "M",
            expiryDate: Date(timeIntervalSinceNow: 365 * 24 * 60 * 60 * 5), // 5 years from now
            personalNumber: nil
        )
    }
    
    private func submitProofOnChain() {
        currentStep = .submitting
        
        Task {
            do {
                // Simulate on-chain submission
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                currentStep = .complete
            } catch {
                errorMessage = "Failed to submit proof: \(error.localizedDescription)"
                showError = true
                currentStep = .proofPreview
            }
        }
    }

    private func processCapturedImage(_ image: UIImage) {
        createMockPassportData()
        showCamera = false
        currentStep = .proofPreview
    }

    // generateProof and submitProof removed as they are replaced by submitProofOnChain

    private func cleanup() {
        scanner.clearAllPassportData()
        zkProofService.resetState()
        scannedPassport = nil
        // generatedProof = nil // Removed
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
                title: "Proof",
                isActive: currentStep.rawValue >= PassportScannerView.ScanStep.proofPreview.rawValue
            )

            Divider()
                .frame(width: 30, height: 2)
                .background(Color.gray)

            StepIndicator(
                number: 3,
                title: "Submit",
                isActive: currentStep.rawValue >= PassportScannerView.ScanStep.submitting.rawValue
            )

            Divider()
                .frame(width: 30, height: 2)
                .background(Color.gray)

            StepIndicator(
                number: 4,
                title: "NFT",
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
        case .proofPreview: return 2
        case .submitting: return 3
        case .complete: return 4
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

// CensusSelectorList removed as it's no longer used

// MARK: - Proof Detail Row

struct ProofDetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
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
