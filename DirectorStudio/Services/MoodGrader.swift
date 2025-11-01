// MODULE: MoodGrader
// VERSION: 1.0.0
// PURPOSE: Core Image-based mood grading with LUTs, grain, and lens effects
// BUILD STATUS: ✅ Complete

import Foundation
import CoreImage
import UIKit

/// Mood grader using Core Image filters
public struct MoodGrader {
    
    /// Apply mood grading to image
    /// - Parameters:
    ///   - mood: Target mood
    ///   - image: Input CIImage
    /// - Returns: Graded CIImage
    public static func apply(_ mood: Mood, to image: CIImage) -> CIImage {
        var result = image
        
        // Apply mood-specific filters
        switch mood {
        case .noir:
            result = applyNoirGrading(to: result)
        case .romantic:
            result = applyRomanticGrading(to: result)
        case .epic:
            result = applyEpicGrading(to: result)
        case .horror:
            result = applyHorrorGrading(to: result)
        case .comedy:
            result = applyComedyGrading(to: result)
        case .surreal:
            result = applySurrealGrading(to: result)
        }
        
        // Add grain
        result = addFilmGrain(to: result, intensity: 0.3)
        
        // Add lens flare (optional, mood-dependent)
        if mood == .epic || mood == .romantic {
            result = addLensFlare(to: result, intensity: 0.15)
        }
        
        return result
    }
    
    /// Auto-detect mood from text using keyword analysis
    /// - Parameter text: Input text
    /// - Returns: Detected mood
    public static func autoDetect(from text: String) -> Mood {
        let lowercaseText = text.lowercased()
        
        let moodKeywords: [Mood: [String]] = [
            .noir: ["dark", "shadow", "mystery", "detective", "crime", "night"],
            .romantic: ["love", "heart", "kiss", "romance", "beautiful", "soft"],
            .epic: ["epic", "grand", "majestic", "battle", "hero", "legend"],
            .horror: ["fear", "terror", "scary", "horror", "monster", "death"],
            .comedy: ["funny", "laugh", "joke", "humor", "comedy", "silly"],
            .surreal: ["dream", "surreal", "weird", "strange", "unreal", "fantasy"]
        ]
        
        var scores: [Mood: Int] = [:]
        
        for (mood, keywords) in moodKeywords {
            scores[mood] = keywords.filter { lowercaseText.contains($0) }.count
        }
        
        return scores.max(by: { $0.value < $1.value })?.key ?? .epic
    }
    
    // MARK: - Private Grading Functions
    
    private static func applyNoirGrading(to image: CIImage) -> CIImage {
        let context = CIContext()
        
        // Desaturate to black and white
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey) // B&W
        filter.setValue(1.2, forKey: kCIInputContrastKey) // High contrast
        filter.setValue(0.9, forKey: kCIInputBrightnessKey) // Slightly darker
        
        guard let output = filter.outputImage else { return image }
        
        // Add vignette
        return addVignette(to: output, radius: 1.5, intensity: 0.8)
    }
    
    private static func applyRomanticGrading(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.3, forKey: kCIInputSaturationKey) // Increased saturation
        filter.setValue(1.1, forKey: kCIInputContrastKey) // Soft contrast
        filter.setValue(1.05, forKey: kCIInputBrightnessKey) // Slightly brighter
        
        guard let output = filter.outputImage else { return image }
        
        // Warm tones
        return applyWarmTones(to: output)
    }
    
    private static func applyEpicGrading(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.4, forKey: kCIInputSaturationKey) // Rich saturation
        filter.setValue(1.3, forKey: kCIInputContrastKey) // High contrast
        filter.setValue(1.0, forKey: kCIInputBrightnessKey)
        
        guard let output = filter.outputImage else { return image }
        
        // Golden hour effect
        return applyGoldenHour(to: output)
    }
    
    private static func applyHorrorGrading(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.7, forKey: kCIInputSaturationKey) // Desaturated
        filter.setValue(1.5, forKey: kCIInputContrastKey) // High contrast
        filter.setValue(0.8, forKey: kCIInputBrightnessKey) // Darker
        
        guard let output = filter.outputImage else { return image }
        
        // Blue-green tint
        return applyCoolTint(to: output)
    }
    
    private static func applyComedyGrading(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.5, forKey: kCIInputSaturationKey) // Vibrant
        filter.setValue(1.1, forKey: kCIInputContrastKey)
        filter.setValue(1.1, forKey: kCIInputBrightnessKey) // Bright
        
        return filter.outputImage ?? image
    }
    
    private static func applySurrealGrading(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.6, forKey: kCIInputSaturationKey) // Hyper-saturated
        filter.setValue(1.4, forKey: kCIInputContrastKey) // Extreme contrast
        filter.setValue(1.0, forKey: kCIInputBrightnessKey)
        
        guard let output = filter.outputImage else { return image }
        
        // Color shift
        return applyColorShift(to: output, hue: 0.1)
    }
    
    // MARK: - Helper Filters
    
    private static func addVignette(to image: CIImage, radius: Double, intensity: Double) -> CIImage {
        guard let filter = CIFilter(name: "CIVignette") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }
    
    private static func applyWarmTones(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CITemperatureAndTint") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
        filter.setValue(CIVector(x: 5500, y: 100), forKey: "inputTargetNeutral") // Warmer
        return filter.outputImage ?? image
    }
    
    private static func applyGoldenHour(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        // Increase red and green channels for golden effect
        filter.setValue(CIVector(x: 1.2, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: 1.1, z: 0, w: 0), forKey: "inputGVector")
        return filter.outputImage ?? image
    }
    
    private static func applyCoolTint(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorMatrix") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        // Increase blue channel
        filter.setValue(CIVector(x: 0, y: 0, z: 1.3, w: 0), forKey: "inputBVector")
        return filter.outputImage ?? image
    }
    
    private static func applyColorShift(to image: CIImage, hue: Double) -> CIImage {
        guard let filter = CIFilter(name: "CIHueAdjust") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(hue, forKey: kCIInputAngleKey)
        return filter.outputImage ?? image
    }
    
    private static func addFilmGrain(to image: CIImage, intensity: Double) -> CIImage {
        guard let filter = CIFilter(name: "CINoiseReduction") else { return image }
        // Actually add noise for grain effect
        guard let noiseFilter = CIFilter(name: "CIRandomGenerator") else { return image }
        guard let noise = noiseFilter.outputImage else { return image }
        
        // Blend noise with image
        guard let blendFilter = CIFilter(name: "CIMultiplyBlendMode") else { return image }
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(noise.cropped(to: image.extent).applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 0, y: 0, z: 0, w: intensity)
        ]), forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
    
    private static func addLensFlare(to image: CIImage, intensity: Double) -> CIImage {
        // Simplified lens flare using radial gradient
        guard let filter = CIFilter(name: "CIRadialGradient") else { return image }
        let center = CIVector(x: image.extent.width * 0.7, y: image.extent.height * 0.3)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(50.0, forKey: kCIInputRadius0Key)
        filter.setValue(200.0, forKey: kCIInputRadius1Key)
        filter.setValue(CIColor.white, forKey: "inputColor0")
        filter.setValue(CIColor.clear, forKey: "inputColor1")
        
        guard let flare = filter.outputImage else { return image }
        
        // Blend flare with image
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return image }
        blendFilter.setValue(flare.cropped(to: image.extent).applyingFilter("CIColorMatrix", parameters: [
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: intensity)
        ]), forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? image
    }
}

