# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SportApp is a SwiftUI-based iOS application for displaying and managing sports events. The app features a sophisticated caching system, API integration, and a modern iOS interface with support for filtering, searching, and detailed event views.

## Architecture

### Core Architecture Pattern
- **MVVM Pattern**: Uses `@ObservableObject` classes as ViewModels (`EventsDataManager`) with SwiftUI Views
- **Singleton Services**: `ApiService.shared` and `SportsEventsCache.shared` for centralized data management
- **Cache-First Strategy**: Implements intelligent caching with instant cache loading followed by background API updates

### Key Components

#### Data Layer
- **`ApiService`** (`ApiService.swift:8`): Main API service with multiple loading strategies (cache-first, API-first, cache-only, API-only)
- **`SportsEventsCache`** (`SportsEventsCache.swift:6`): Persistent disk-based caching system with 1-hour validity
- **`EventsDataManager`** (`EventsDataManager.swift:10`): MVVM ViewModel that orchestrates between UI, cache, and API

#### Models (`Models/SportModels.swift`)
- **`SportEvent`**: Main event model with comprehensive fields including location, dates, registration info
- **`Sport`**: Sport category with icon mapping
- **`City`**: Location information
- **`EventFile`**: Associated event documents/files

#### UI Architecture
- **`ContentView`**: Main container with TabView for navigation
- **`MainContentView`**: Smart content switcher (loading/error/events list)
- **View Components**: Modular UI components in `Views/` directory
  - `HeaderView`: Search and filter interface
  - `EventCardView`: Event list item display
  - `LoadingView`/`ErrorView`: State management views

### Caching Strategy

The app implements a sophisticated 4-strategy caching system:

1. **Cache-First** (Default): Load from cache immediately, update in background
2. **API-First**: Try API first, fallback to cache if API fails
3. **Cache-Only**: Offline mode using only cached data
4. **API-Only**: Force fresh data from API

Cache validity is 1 hour (`SportsEventsCache.swift:15`), stored in app's Caches directory.

### API Integration

- **Base URL**: Configured in `ApiService.swift:11` (currently `http://192.168.0.136:8000`)
- **Image Base URL**: `http://192.168.0.136:9000/uploads` for event photos
- **Date Format**: ISO 8601 format (`yyyy-MM-dd'T'HH:mm:ss`)
- **Timeout**: 10s for requests, 20s for resources
- **Error Handling**: Comprehensive error types with user-friendly messages

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project SportApp.xcodeproj -scheme SportApp -configuration Debug build

# Build for release
xcodebuild -project SportApp.xcodeproj -scheme SportApp -configuration Release build

# Run tests
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests
xcodebuild test -project SportApp.xcodeproj -scheme SportApp -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:SportAppUITests
```

### Opening in Xcode
```bash
open SportApp.xcodeproj
```

## Key Features

### Smart Data Loading
- Instant app startup with cached data
- Background refresh for up-to-date information
- Offline capability with fallback to cached events
- Pull-to-refresh for manual updates

### Event Management
- Comprehensive event details including registration info, location, contacts
- Photo gallery support with optimized image loading
- File attachments for event documents
- Date-based filtering and search functionality

### UI/UX
- Dark theme with custom styling
- Tab-based navigation (Events/Calendar)
- Search and filter capabilities
- Error states with retry options
- Loading states with progress indicators

## Common Patterns

### Adding New API Endpoints
1. Add method to `ApiService` class
2. Update error handling in `APIError` enum if needed
3. Update `EventsDataManager` to call new endpoint
4. Add corresponding UI state management

### Creating New Views
- Follow existing pattern in `Views/` directory
- Use `@ObservedObject` for data dependencies
- Implement proper error and loading states
- Follow existing dark theme styling

### Working with Cache
- Use `SportsEventsCache.shared` for persistence
- Events automatically cached via `ApiService.fetchAndCacheEvents()`
- Check cache status with `getCacheStatus()`
- Clear cache with `clearCache()` for debugging

## API Configuration

To change API endpoints, update:
- `baseURL` in `ApiService.swift:11`
- Image base URL in `SportModels.swift:137`

The app expects the API to return arrays of `SportEvent` objects matching the model structure defined in `SportModels.swift`.