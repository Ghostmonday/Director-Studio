# 🎬 DirectorStudio

A SwiftUI-based video generation pipeline application for iOS.

## Overview

DirectorStudio is a production-ready video generation app that processes user prompts through a modular pipeline system. The app follows clean architecture principles with protocol-based modules, ensuring maintainability and scalability.

## Features

- **Authentication** - Secure user authentication system
- **Video Generation Pipeline** - Modular processing system with:
  - Segmentation module
  - Continuity module
  - Stitching module
- **Local & Cloud Storage** - Hybrid data persistence
- **Credit System** - User credit management
- **Modern UI** - Clean SwiftUI interface

## Project Structure

```
DirectorStudio/
├── App/                    # App entry and navigation
├── Core/                   # Shared components
│   ├── Models/            # Data models
│   ├── Services/          # Business logic
│   └── UI/                # Shared UI components
├── Features/              # Feature-specific views
├── Pipeline/              # Video processing modules
├── Resources/             # Assets and configuration
└── Tests/                 # Unit tests
```

## Architecture

The app follows a modular architecture:

- **Protocol-Based Design** - All modules conform to `PipelineModule` protocol
- **Clean Separation** - Clear boundaries between UI, business logic, and data
- **Testable** - Each module can be tested independently
- **Scalable** - Easy to add new features and modules

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Clone the repository
2. Open `DirectorStudio.xcodeproj` in Xcode
3. Configure Supabase credentials in `Resources/Secrets.xcconfig`
4. Build and run

## Development

### Module Structure

Each pipeline module follows this pattern:

```swift
struct ModuleName: PipelineModule, ValidatableModule {
    let id: String
    let version: String
    let description: String
    
    func process(_ input: ModuleInput) async -> ModuleResult {
        // Processing logic
    }
    
    func validate() -> ValidationResult {
        // Validation logic
    }
}
```

### Adding a New Module

1. Create a new Swift file in `Pipeline/Modules/`
2. Conform to `PipelineModule` protocol
3. Define input/output types
4. Implement processing logic
5. Add to `PipelineConnector`

## Testing

Run tests with:
```bash
swift test
```

## License

MIT License

