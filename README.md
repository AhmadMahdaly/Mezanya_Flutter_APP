# Korassa Flutter App

This folder contains a Flutter mobile foundation for Korassa using:

- SharedPreferences for local persistence.
- Repository Pattern to separate storage from business logic.
- Feature-based structure for scalable development.

## Folder Structure

- `lib/core`: common setup and storage keys.
- `lib/features`: feature-first modules (entities, repositories, presentation).
- `lib/features/app_state/data/repositories/shared_prefs_app_repository.dart`: SharedPreferences implementation of `AppRepository`.

## Run

1. Install Flutter SDK.
2. Open this folder:
   - `cd flutter_app`
3. Install packages:
   - `flutter pub get`
4. Run:
   - `flutter run`
