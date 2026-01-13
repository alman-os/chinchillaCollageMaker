//
//  ContentView.swift
//  CollageMaker
//
//  Phase E/F: Complete - Collage creation + Open file prompt
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    // MARK: - State
    @State private var imagePaths: [URL] = []
    @State private var imagesPerRow = "Auto"
    @State private var isBuilding = false
    @State private var isDropTargeted = false
    
    // MARK: - Computed Properties
    private var imageCount: Int {
        imagePaths.count
    }
    
    private var canExport: Bool {
        imageCount > 0 && !isBuilding
    }
    
    private var canClear: Bool {
        imageCount > 0 && !isBuilding
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("📸 Collage Maker")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 30)
                .padding(.bottom, 10)
            
            // Drop Zone
            dropZone
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
            
            // Counter
            counterView
                .padding(.vertical, 15)
            
            // Buttons
            buttonsView
                .padding(.vertical, 20)
            
            // Images per row selector
            imagesPerRowPicker
                .padding(.bottom, 15)
            
            Spacer()
        }
        .frame(width: 500, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert(confirmTitle, isPresented: $showingConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                confirmAction?()
            }
        } message: {
            Text(confirmMessage)
        }
        .alert("Success! 🎉", isPresented: $showingSuccess) {
            Button("Cancel", role: .cancel) { }
            Button("Open File") {
                if let url = successOutputPath {
                    openFile(at: url)
                }
            }
        } message: {
            if let path = successOutputPath?.path {
                Text("Collage created successfully!\n\nSaved to:\n\(path)")
            }
        }
    }
    
    // MARK: - Drop Zone
    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.accentColor.opacity(0.5),
                    lineWidth: 2
                )
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isDropTargeted ? Color.accentColor.opacity(0.15) : Color.accentColor.opacity(0.05))
                )
            
            VStack(spacing: 5) {
                Image(systemName: isDropTargeted ? "arrow.down.doc.fill" : "folder.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                
                Text(isDropTargeted ? "Drop Images Here!" : "Drag & Drop Images Here")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.accentColor)
                
                Text("or click 'Select Images' below")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 25)
        }
        .frame(height: 100)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Counter View
    private var counterView: some View {
        VStack(spacing: 5) {
            Text("\(imageCount)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.accentColor)
            
            Text("images selected")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Buttons View
    private var buttonsView: some View {
        VStack(spacing: 8) {
            // Select Images Button (always enabled)
            Button(action: selectImages) {
                Label("Select Images", systemImage: "folder")
                    .frame(width: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Create & Export Button
            Button(action: createAndExport) {
                Label("Create & Export", systemImage: "sparkles")
                    .frame(width: 200)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
            .disabled(!canExport)
            
            // Clear All Button
            Button(action: clearAll) {
                Label("Clear All", systemImage: "trash")
                    .frame(width: 180)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(!canClear)
        }
    }
    
    // MARK: - Images Per Row Picker
    private var imagesPerRowPicker: some View {
        HStack(spacing: 10) {
            Text("Images per row:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Picker("", selection: $imagesPerRow) {
                Text("Auto").tag("Auto")
                Text("2").tag("2")
                Text("3").tag("3")
                Text("4").tag("4")
                Text("5").tag("5")
                Text("6").tag("6")
            }
            .pickerStyle(.menu)
            .frame(width: 80)
        }
    }
    
    // MARK: - Actions
    private func selectImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.jpeg, .png, .gif, .bmp, .tiff, .heic]
        panel.message = "Select images for collage"
        
        panel.begin { response in
            if response == .OK {
                // Replace existing list (matching Python behavior)
                self.imagePaths = panel.urls
            }
        }
    }
    
    private func createAndExport() {
        guard !imagePaths.isEmpty else {
            showAlert(
                title: "No Images",
                message: "Please select images first!"
            )
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.jpeg, .png]
        panel.nameFieldStringValue = "collage.jpg"
        panel.message = "Save collage as"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                // Set building state
                self.isBuilding = true
                
                // Determine images per row
                let perRow: Int? = self.imagesPerRow == "Auto" ? nil : Int(self.imagesPerRow)
                
                // Create collage in background
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try CollageEngine.createCollage(
                            imagePaths: self.imagePaths,
                            outputPath: url,
                            imagesPerRow: perRow
                        )
                        
                        // Success!
                        DispatchQueue.main.async {
                            self.isBuilding = false
                            self.showSuccessDialog(outputPath: url)
                        }
                        
                    } catch {
                        // Error
                        DispatchQueue.main.async {
                            self.isBuilding = false
                            self.showAlert(
                                title: "Error",
                                message: "Failed to create collage:\n\(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func clearAll() {
        guard !imagePaths.isEmpty else { return }
        
        showConfirmation(
            title: "Clear All Images?",
            message: "Are you sure you want to clear all \(imageCount) selected images?"
        ) { confirmed in
            if confirmed {
                self.imagePaths = []
                self.showAlert(
                    title: "Cleared",
                    message: "All images have been cleared!"
                )
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Filter for file URLs
        let imageProviders = providers.filter { $0.hasItemConformingToTypeIdentifier("public.file-url") }
        
        guard !imageProviders.isEmpty else { return false }
        
        // Process dropped files
        for provider in imageProviders {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
                DispatchQueue.main.async {
                    if let urlData = urlData as? Data,
                       let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                        
                        // Filter for valid image types
                        let validExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "webp"]
                        let fileExtension = url.pathExtension.lowercased()
                        
                        if validExtensions.contains(fileExtension) {
                            // Add to list (extend, not replace - matching Python behavior)
                            if !self.imagePaths.contains(url) {
                                self.imagePaths.append(url)
                            }
                        }
                    }
                }
            }
        }
        
        // Show feedback after all files processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let addedCount = imageProviders.count
            if addedCount > 0 {
                self.showAlert(
                    title: "Images Added",
                    message: "Added \(addedCount) image(s)!\n\nTotal: \(self.imageCount) images"
                )
            }
        }
        
        return true
    }
    
    // MARK: - Alert Helpers
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    @State private var confirmTitle = ""
    @State private var confirmMessage = ""
    @State private var showingConfirm = false
    @State private var confirmAction: (() -> Void)?
    
    @State private var showingSuccess = false
    @State private var successOutputPath: URL?
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    private func showConfirmation(title: String, message: String, action: @escaping (Bool) -> Void) {
        confirmTitle = title
        confirmMessage = message
        confirmAction = { action(true) }
        showingConfirm = true
    }
    
    private func showSuccessDialog(outputPath: URL) {
        successOutputPath = outputPath
        showingSuccess = true
    }
    
    private func openFile(at url: URL) {
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    ContentView()
}
