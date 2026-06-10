# Journal Trend Analyzer
**PRM393 – Mobile Programming | Lab 2**
Student ID: SE180518

## Overview
A Flutter mobile application that retrieves publication data from the [OpenAlex API](https://openalex.org) and provides analytical insights through interactive visualizations and dashboards.

## Features
- **Topic Search** — Search research publications by keyword, sorted by citation count
- **Publication Details** — View title, authors, year, journal, DOI, abstract, citation count
- **Trend Analysis** — Publication trend chart by year, top influential papers, top journals, top authors
- **Research Dashboard** — Summary: total publications, average citations, most active year, top journal, top author, most influential paper
- **Search History** — Quick access to recent searches
- **Load More** — Pagination support

## Tech Stack
- Flutter & Dart
- OpenAlex REST API (no API key required)
- Provider (state management)
- fl_chart (charts)
- shared_preferences (local storage)
- shimmer (loading UI)

## Project Structure
```
lib/
  models/         — Publication, YearCount, JournalCount, AuthorCount, DashboardData
  services/       — OpenAlexService, HistoryService
  state/          — SearchProvider (Provider pattern)
  screens/        — SplashScreen, SearchScreen, PublicationDetailScreen, TrendScreen, DashboardScreen
  widgets/        — LoadingList, EmptyState, ErrorState
  main.dart
```

## How to Run
```bash
flutter pub get
flutter run
```
Requires Android device or emulator (minSdk 21+).

## API Reference
Base URL: `https://api.openalex.org`
- Search works: `GET /works?search=<query>&sort=cited_by_count:desc`
- No authentication required (uses polite pool with mailto param)
