//
//  CollageEngine.swift
//  CollageMaker
//
//  Phase E: Collage creation algorithm (exact parity with Python version)
//

import AppKit
import CoreGraphics

enum CollageError: Error {
    case noImages
    case invalidImagePath
    case imageLoadFailed(String)
    case canvasCreationFailed
    case saveFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .noImages:
            return "No images provided"
        case .invalidImagePath:
            return "Invalid image path"
        case .imageLoadFailed(let path):
            return "Failed to load image: \(path)"
        case .canvasCreationFailed:
            return "Failed to create canvas"
        case .saveFailed(let reason):
            return "Failed to save collage: \(reason)"
        }
    }
}

class CollageEngine {
    
    // MARK: - Constants (matching Python version)
    private static let targetHeight: CGFloat = 600
    private static let padding: CGFloat = 10
    private static let jpegQuality: CGFloat = 0.95
    
    // MARK: - Main Function
    static func createCollage(
        imagePaths: [URL],
        outputPath: URL,
        imagesPerRow: Int?
    ) throws {
        
        guard !imagePaths.isEmpty else {
            throw CollageError.noImages
        }
        
        // Step 1: Load and resize all images to height 600
        let resizedImages = try loadAndResizeImages(paths: imagePaths)
        
        // Step 2: Calculate grid dimensions
        let actualImagesPerRow: Int
        if let perRow = imagesPerRow {
            actualImagesPerRow = perRow
        } else {
            // Auto: ceil(sqrt(count))
            actualImagesPerRow = Int(ceil(sqrt(Double(resizedImages.count))))
        }
        
        let rows = Int(ceil(Double(resizedImages.count) / Double(actualImagesPerRow)))
        
        // Step 3: Find max width
        let maxWidth = resizedImages.map { $0.size.width }.max() ?? 0
        
        // Step 4: Calculate canvas size
        let canvasWidth = maxWidth * CGFloat(actualImagesPerRow) + padding * CGFloat(actualImagesPerRow + 1)
        let canvasHeight = targetHeight * CGFloat(rows) + padding * CGFloat(rows + 1)
        
        // Step 5: Create white canvas
        guard let context = createWhiteCanvas(width: canvasWidth, height: canvasHeight) else {
            throw CollageError.canvasCreationFailed
        }
        
        // Step 6: Paste images at computed positions
        for (idx, image) in resizedImages.enumerated() {
            let row = idx / actualImagesPerRow
            let col = idx % actualImagesPerRow
            
            let x = CGFloat(col) * maxWidth + padding * CGFloat(col + 1)
            let y = CGFloat(row) * targetHeight + padding * CGFloat(row + 1)
            
            // Important: CoreGraphics uses bottom-left origin, so flip Y
            let flippedY = canvasHeight - y - targetHeight
            
            let rect = CGRect(x: x, y: flippedY, width: image.size.width, height: image.size.height)
            
            if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                context.draw(cgImage, in: rect)
            }
        }
        
        // Step 7: Save to file
        try saveCanvas(context: context, outputPath: outputPath, width: Int(canvasWidth), height: Int(canvasHeight))
    }
    
    // MARK: - Helper Functions
    
    private static func loadAndResizeImages(paths: [URL]) throws -> [NSImage] {
        var resizedImages: [NSImage] = []
        
        for path in paths {
            guard let image = NSImage(contentsOf: path) else {
                throw CollageError.imageLoadFailed(path.lastPathComponent)
            }
            
            // Get original size
            let originalSize = image.size
            guard originalSize.height > 0 else {
                throw CollageError.imageLoadFailed(path.lastPathComponent)
            }
            
            // Calculate new width maintaining aspect ratio
            let aspectRatio = originalSize.width / originalSize.height
            let newWidth = targetHeight * aspectRatio
            
            // Create resized image
            let newSize = NSSize(width: newWidth, height: targetHeight)
            let resized = NSImage(size: newSize)
            
            resized.lockFocus()
            image.draw(
                in: NSRect(origin: .zero, size: newSize),
                from: NSRect(origin: .zero, size: originalSize),
                operation: .copy,
                fraction: 1.0
            )
            resized.unlockFocus()
            
            resizedImages.append(resized)
        }
        
        return resizedImages
    }
    
    private static func createWhiteCanvas(width: CGFloat, height: CGFloat) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // Fill with white background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context
    }
    
    private static func saveCanvas(context: CGContext, outputPath: URL, width: Int, height: Int) throws {
        guard let image = context.makeImage() else {
            throw CollageError.saveFailed("Failed to create CGImage from context")
        }
        
        // Determine file type from extension
        let ext = outputPath.pathExtension.lowercased()
        let fileType: CFString
        let properties: [CFString: Any]
        
        if ext == "png" {
            fileType = kUTTypePNG
            properties = [:]
        } else {
            // Default to JPEG with quality 0.95 (matching Python)
            fileType = kUTTypeJPEG
            properties = [kCGImageDestinationLossyCompressionQuality: jpegQuality]
        }
        
        // Create destination
        guard let destination = CGImageDestinationCreateWithURL(
            outputPath as CFURL,
            fileType,
            1,
            nil
        ) else {
            throw CollageError.saveFailed("Failed to create image destination")
        }
        
        // Add image with properties
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        
        // Write to file
        guard CGImageDestinationFinalize(destination) else {
            throw CollageError.saveFailed("Failed to finalize image")
        }
    }
}
