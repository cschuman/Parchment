#!/usr/bin/env swift

import Cocoa
import Foundation

// Create a simple, clean app icon
func createMarkdownIcon() -> NSImage? {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    
    image.lockFocus()
    
    // Background gradient (blue to purple)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
        NSColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)
    ])
    gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 45)
    
    // Add rounded corner mask
    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 180, yRadius: 180)
    path.addClip()
    
    // Draw markdown "M" symbol
    NSColor.white.set()
    
    // Draw stylized "M" for Markdown
    let mPath = NSBezierPath()
    let centerX = size.width / 2
    let centerY = size.height / 2
    let mWidth: CGFloat = 400
    let mHeight: CGFloat = 300
    
    // Left vertical line
    mPath.move(to: NSPoint(x: centerX - mWidth/2, y: centerY - mHeight/2))
    mPath.line(to: NSPoint(x: centerX - mWidth/2, y: centerY + mHeight/2))
    
    // Left diagonal
    mPath.line(to: NSPoint(x: centerX, y: centerY))
    
    // Right diagonal
    mPath.line(to: NSPoint(x: centerX + mWidth/2, y: centerY + mHeight/2))
    
    // Right vertical line
    mPath.line(to: NSPoint(x: centerX + mWidth/2, y: centerY - mHeight/2))
    
    mPath.lineWidth = 80
    mPath.lineCapStyle = .round
    mPath.lineJoinStyle = .round
    mPath.stroke()
    
    // Add small "d" for down/document
    let dPath = NSBezierPath()
    let dX = centerX + 100
    let dY = centerY - 150
    let dSize: CGFloat = 60
    
    // Circle part of 'd'
    dPath.appendOval(in: NSRect(x: dX - dSize/2, y: dY - dSize/2, width: dSize, height: dSize))
    
    // Vertical line of 'd'
    dPath.move(to: NSPoint(x: dX + dSize/2, y: dY - dSize))
    dPath.line(to: NSPoint(x: dX + dSize/2, y: dY + dSize))
    
    dPath.lineWidth = 20
    dPath.lineCapStyle = .round
    dPath.stroke()
    
    image.unlockFocus()
    
    return image
}

// Create icon sizes for macOS
func createIconSet() {
    guard let baseImage = createMarkdownIcon() else {
        print("Failed to create base icon")
        return
    }
    
    let iconSizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
    
    let iconSetPath = "Parchment.iconset"
    
    // Create iconset directory
    do {
        try FileManager.default.createDirectory(atPath: iconSetPath, withIntermediateDirectories: true)
    } catch {
        print("Failed to create iconset directory: \(error)")
        return
    }
    
    for size in iconSizes {
        let targetSize = NSSize(width: size, height: size)
        let scaledImage = NSImage(size: targetSize)
        
        scaledImage.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: targetSize))
        scaledImage.unlockFocus()
        
        // Save as PNG
        guard let tiffData = scaledImage.tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData),
              let pngData = imageRep.representation(using: .png, properties: [:]) else {
            continue
        }
        
        let filename = "icon_\(size)x\(size).png"
        let filePath = "\(iconSetPath)/\(filename)"
        
        try? pngData.write(to: URL(fileURLWithPath: filePath))
        print("Created \(filename)")
        
        // Also create @2x versions for some sizes
        if size <= 512 {
            let retinaFilename = "icon_\(size/2)x\(size/2)@2x.png"
            let retinaPath = "\(iconSetPath)/\(retinaFilename)"
            try? pngData.write(to: URL(fileURLWithPath: retinaPath))
            print("Created \(retinaFilename)")
        }
    }
    
    print("Icon set created at \(iconSetPath)")
    print("Run: iconutil -c icns \(iconSetPath)")
}

createIconSet()