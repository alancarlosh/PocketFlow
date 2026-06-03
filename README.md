# PocketFlow CRM

PocketFlow CRM is an iOS application built with SwiftUI that combines personal finance tracking with a lightweight CRM workflow. The project is designed around a practical business scenario: a freelancer, consultant, sales advisor, or independent professional needs to record income and expenses, associate them with clients, and prepare selected financial activity for synchronization with Salesforce.

## Project Overview

The current version provides the foundation for a finance-focused CRM app. It includes a SwiftUI dashboard, transaction models, client relationships, financial summary calculations, and a mock Salesforce synchronization service. The architecture is intentionally simple and modular, making it easy to review, extend, and test.

## Core Features

- Financial dashboard with income, expense, and balance summary.
- Transaction list with expense/income classification.
- Client association for CRM-style financial tracking.
- Sync status per transaction.
- Mock Salesforce sync service to model future API integration.
- Unit tests for financial calculations and sync behavior.

## Tech Stack

- Swift 6
- SwiftUI
- MVVM
- Combine / ObservableObject
- XCTest
- Xcode project structure

## Architecture

The project follows a lightweight MVVM structure:

- `Models`: Domain entities such as `Transaction`, `Client`, and sync-related enums.
- `Views`: SwiftUI screens and reusable UI components.
- `ViewModels`: UI state, user actions, and coordination between views and services.
- `Services`: Business logic and external integration boundaries.
- `Tests`: Unit tests for core behavior.

This separation keeps the UI independent from business logic and prepares the project for future persistence, networking, and authentication layers.

## Salesforce Integration Approach

The app currently uses `SalesforceSyncServiceMock` to simulate synchronization without requiring real Salesforce credentials. This keeps the project safe to run and review while preserving a clear integration boundary.

A production-ready Salesforce implementation would include:

- OAuth 2.0 authentication.
- Secure token storage in Keychain.
- REST API communication with Salesforce.
- Mapping local clients to Salesforce `Account` or `Contact` records.
- Mapping financial records to a Salesforce custom object.
- Error handling, retry policies, and offline sync state.

## Current Status

This repository contains the initial iOS scaffold and MVP foundation. The app builds successfully for iOS Simulator, and the test target compiles with the current project configuration.

## Quality Practices

- Modular project structure.
- Protocol-based service abstraction for Salesforce sync.
- Unit tests for core financial summary logic.
- Mock service implementation for deterministic testing.
- No real credentials or tokens stored in the repository.

## Getting Started

1. Clone the repository.
2. Open `PocketFlow.xcodeproj` in Xcode.
3. Select the `PocketFlow` scheme.
4. Run the app on an iOS Simulator.

## Roadmap

- Add transaction creation and editing forms.
- Add client detail screens and client-level financial summaries.
- Introduce SwiftData or Core Data for local persistence.
- Add filtering by date, category, client, and sync status.
- Implement a real Salesforce API client.
- Add OAuth login flow and secure token handling.
- Expand unit and UI test coverage.

## Purpose

PocketFlow CRM was created as a portfolio project to demonstrate iOS development fundamentals, SwiftUI UI composition, MVVM architecture, business-domain modeling, testable service boundaries, and preparation for third-party CRM integration.

