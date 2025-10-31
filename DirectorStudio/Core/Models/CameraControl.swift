// MODULE: CameraControl
// VERSION: 1.0.0
// PURPOSE: Camera control structures matching official Kling API format
// PRODUCTION-GRADE: Full API conformance, cinematography mapping

import Foundation

/// Camera control type per Kling API
/// Enum values: "simple", "down_back", "forward_up", "right_turn_forward", "left_turn_forward"
public enum CameraControlType: String, Codable {
    case simple = "simple"
    case downBack = "down_back"
    case forwardUp = "forward_up"
    case rightTurnForward = "right_turn_forward"
    case leftTurnForward = "left_turn_forward"
    
    /// Description for UI
    public var displayName: String {
        switch self {
        case .simple: return "Simple Movement"
        case .downBack: return "Pan Down & Zoom Out"
        case .forwardUp: return "Zoom In & Pan Up"
        case .rightTurnForward: return "Rotate Right & Advance"
        case .leftTurnForward: return "Rotate Left & Advance"
        }
    }
}

/// Camera control config matching Kling API format
/// Value range: [-10, 10] for all fields
/// When type is "simple", choose ONE non-zero value; others must be zero
public struct CameraControlConfig: Codable {
    /// Horizontal translation (x-axis): negative = left, positive = right
    public var horizontal: Float?
    
    /// Vertical translation (y-axis): negative = down, positive = up
    public var vertical: Float?
    
    /// Pan rotation (around x-axis): negative = down, positive = up
    public var pan: Float?
    
    /// Tilt rotation (around y-axis): negative = left, positive = right
    public var tilt: Float?
    
    /// Roll rotation (around z-axis): negative = counterclockwise, positive = clockwise
    public var roll: Float?
    
    /// Zoom focal length: negative = narrower (zoom in), positive = wider (zoom out)
    public var zoom: Float?
    
    public init(
        horizontal: Float? = nil,
        vertical: Float? = nil,
        pan: Float? = nil,
        tilt: Float? = nil,
        roll: Float? = nil,
        zoom: Float? = nil
    ) {
        // Clamp values to [-10, 10] range
        self.horizontal = horizontal.map { max(-10, min(10, $0)) }
        self.vertical = vertical.map { max(-10, min(10, $0)) }
        self.pan = pan.map { max(-10, min(10, $0)) }
        self.tilt = tilt.map { max(-10, min(10, $0)) }
        self.roll = roll.map { max(-10, min(10, $0)) }
        self.zoom = zoom.map { max(-10, min(10, $0)) }
    }
    
    /// Check if config is valid for "simple" type (only one non-zero value per API spec)
    /// Note: API might allow multiple values, but spec says "choose one"
    public var isValidForSimple: Bool {
        let values = [horizontal, vertical, pan, tilt, roll, zoom].compactMap { $0 }
        let nonZeroValues = values.filter { abs($0) > 0.01 }
        return nonZeroValues.count <= 1
    }
    
    /// Get the primary (non-zero) value for simple type
    /// If multiple values exist, return the first non-zero one
    public func getPrimaryValue() -> (key: String, value: Float)? {
        if let h = horizontal, abs(h) > 0.01 { return ("horizontal", h) }
        if let v = vertical, abs(v) > 0.01 { return ("vertical", v) }
        if let p = pan, abs(p) > 0.01 { return ("pan", p) }
        if let t = tilt, abs(t) > 0.01 { return ("tilt", t) }
        if let r = roll, abs(r) > 0.01 { return ("roll", r) }
        if let z = zoom, abs(z) > 0.01 { return ("zoom", z) }
        return nil
    }
    
    /// Convert to API JSON format (only include non-nil values)
    public func toAPIDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let h = horizontal { dict["horizontal"] = h }
        if let v = vertical { dict["vertical"] = v }
        if let p = pan { dict["pan"] = p }
        if let t = tilt { dict["tilt"] = t }
        if let r = roll { dict["roll"] = r }
        if let z = zoom { dict["zoom"] = z }
        return dict
    }
}

/// Camera control matching official Kling API format
public struct CameraControl: Codable {
    /// Camera movement type
    public let type: CameraControlType?
    
    /// Camera movement config (required when type is "simple")
    public let config: CameraControlConfig?
    
    public init(type: CameraControlType? = nil, config: CameraControlConfig? = nil) {
        self.type = type
        self.config = config
    }
    
    /// Convert to API JSON format
    public func toAPIDict() -> [String: Any]? {
        guard type != nil || config != nil else { return nil }
        
        var dict: [String: Any] = [:]
        if let type = type {
            dict["type"] = type.rawValue
        }
        if let config = config {
            let configDict = config.toAPIDict()
            if !configDict.isEmpty {
                dict["config"] = configDict
            }
        }
        return dict.isEmpty ? nil : dict
    }
}

// MARK: - Cinematography Mapping

extension CameraControl {
    /// Parse prompt text and extract camera control automatically
    /// Detects keywords like "zoom in", "drone shot", "close-up", "pan left", etc.
    public static func fromPrompt(_ prompt: String) -> CameraControl? {
        let lower = prompt.lowercased()
        
        // ZOOM OPERATIONS (highest priority - most explicit)
        if lower.contains("zoom in") || lower.contains("zooming in") || lower.contains("push in") || lower.contains("pushing in") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(zoom: -7.0) // Strong zoom in
            )
        }
        
        if lower.contains("zoom out") || lower.contains("zooming out") || lower.contains("pull out") || lower.contains("pulling out") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(zoom: 7.0) // Strong zoom out
            )
        }
        
        // CLOSE-UP / EXTREME CLOSE-UP (zoom in)
        if lower.contains("close-up") || lower.contains("close up") || lower.contains("extreme close") || lower.contains("macro") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(zoom: -8.0) // Very strong zoom in for close-up
            )
        }
        
        // WIDE SHOT / ESTABLISHING SHOT (zoom out)
        if lower.contains("wide shot") || lower.contains("wide angle") || lower.contains("establishing shot") || lower.contains("wide view") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(zoom: 6.0) // Zoom out for wide
            )
        }
        
        // DRONE SHOT / AERIAL SHOT 
        // Using simple type with zoom out (per API spec: simple type requires ONE non-zero value)
        if lower.contains("drone") || lower.contains("aerial") || lower.contains("overhead") || lower.contains("bird's eye") || lower.contains("birds eye") {
            // Use simple zoom out for aerial/drone shots (most compatible)
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(zoom: 8.0) // Zoom out for wide aerial view
            )
        }
        
        // PAN LEFT/RIGHT
        if lower.contains("pan left") || lower.contains("pans left") || lower.contains("track left") || lower.contains("moves left") || lower.contains("sweeps left") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(horizontal: -6.0) // Pan left
            )
        }
        
        if lower.contains("pan right") || lower.contains("pans right") || lower.contains("track right") || lower.contains("moves right") || lower.contains("sweeps right") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(horizontal: 6.0) // Pan right
            )
        }
        
        // TILT UP/DOWN
        if lower.contains("tilt up") || lower.contains("tilts up") || lower.contains("look up") || lower.contains("raises") || lower.contains("angles up") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(pan: 6.0) // Tilt up
            )
        }
        
        if lower.contains("tilt down") || lower.contains("tilts down") || lower.contains("look down") || lower.contains("lowers") || lower.contains("angles down") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(pan: -6.0) // Tilt down
            )
        }
        
        // DOLLY FORWARD / PUSH IN (different from zoom - camera moves forward)
        if lower.contains("dolly forward") || lower.contains("dollies forward") || lower.contains("camera pushes forward") || lower.contains("advances") {
            return CameraControl(
                type: .forwardUp,
                config: nil // Forward movement
            )
        }
        
        // DOLLY BACK / PULL BACK
        if lower.contains("dolly back") || lower.contains("dollies back") || lower.contains("camera pulls back") || lower.contains("retreats") || lower.contains("recedes") {
            return CameraControl(
                type: .downBack,
                config: nil // Backward movement with pan down
            )
        }
        
        // CIRCULAR / ORBITING MOVEMENT (combine pan and tilt)
        if lower.contains("orbits") || lower.contains("circles") || lower.contains("rotates around") {
            return CameraControl(
                type: .rightTurnForward, // Rotate right and advance
                config: nil
            )
        }
        
        // CRANE SHOT / RISING SHOT (vertical up)
        if lower.contains("crane up") || lower.contains("rises") || lower.contains("lifts up") || lower.contains("ascends") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(vertical: 7.0) // Move up
            )
        }
        
        // DESCENDING SHOT (vertical down)
        if lower.contains("descends") || lower.contains("drops") || lower.contains("falls") || lower.contains("lowers") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(vertical: -7.0) // Move down
            )
        }
        
        // HANDHELD / SHAKY CAM (subtle roll)
        if lower.contains("handheld") || lower.contains("shaky") || lower.contains("unstable") {
            return CameraControl(
                type: .simple,
                config: CameraControlConfig(roll: 2.0) // Subtle roll for handheld feel
            )
        }
        
        // Default: no camera control (let model intelligently match based on prompt)
        return nil
    }
    
    /// Create camera control from CinematicTaxonomy camera movement string
    /// Maps common cinematography terms to Kling API camera_control format
    public static func fromCinematicMovement(_ movement: String) -> CameraControl? {
        return fromPrompt(movement) // Reuse prompt parsing logic
    }
    
    /// Create camera control from FilmTake cameraDirection string
    public static func fromCameraDirection(_ direction: String?) -> CameraControl? {
        guard let direction = direction else { return nil }
        return fromPrompt(direction) // Use prompt parsing for better detection
    }
}

