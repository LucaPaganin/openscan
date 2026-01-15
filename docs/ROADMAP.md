# OpenScan — Development Roadmap

## Project Vision

A cross-platform mobile document scanner app with book curve flattening capabilities, built with Flutter and a Python/FastAPI backend for heavy processing.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER (On-Device)                      │
├─────────────────────────────────────────────────────────────┤
│  Camera │ Edge Detection │ Perspective │ Filters │ PDF     │
│  Preview│ (real-time)    │ Correction  │ (B&W)   │ Export  │
└────────────────────────────┬────────────────────────────────┘
                             │
                             │ HTTPS (only for heavy tasks)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                 BACKEND (Azure / FastAPI)                   │
├─────────────────────────────────────────────────────────────┤
│           Curve Flattening │ OCR (optional)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Flutter MVP (No Backend Required)

**Goal**: Fully functional document scanner running entirely on-device.

| Epic | Name | Description | Sprints | Dependencies |
|------|------|-------------|---------|--------------|
| E1 | Project Setup | Flutter project, structure, tooling | 1 | — |
| E2 | Camera Module | Camera preview, permissions, capture | 1 | E1 |
| E3 | Local Gallery | Store & display captured images | 1 | E2 |
| E4 | Edge Detection | Real-time document boundary detection | 2 | E2 |
| E5 | Manual Corner Adjust | UI to refine detected corners | 1 | E4 |
| E6 | Perspective Correction | 4-point transform to flatten | 1 | E5 |
| E7 | Image Enhancement | B&W, grayscale, contrast filters | 1 | E6 |
| E8 | Multi-page & PDF | Batch scanning, page order, PDF export | 2 | E7 |

**Phase 1 Total: ~10 sprints (10 weeks)**

```
E1 ──▶ E2 ──▶ E3
              │
              ├──▶ E4 ──▶ E5 ──▶ E6 ──▶ E7 ──▶ E8
              │
         [MVP COMPLETE]
```

### Phase 1 Deliverable

A working app that can:
- ✅ Open camera and capture documents
- ✅ Detect document edges automatically
- ✅ Let user adjust corners manually
- ✅ Correct perspective to flat rectangle
- ✅ Apply enhancement filters
- ✅ Combine multiple pages into PDF
- ✅ Save and browse scanned documents
- ❌ No curve flattening yet (flat documents only)

---

## Phase 2: Backend & Book Scanning

**Goal**: Add curve flattening for book pages via cloud processing.

| Epic | Name | Description | Sprints | Dependencies |
|------|------|-------------|---------|--------------|
| E9 | Backend Setup | FastAPI, Azure deployment, API client | 2 | E8 |
| E10 | Curve Detection | Detect curved text lines on book pages | 2-3 | E9 |
| E11 | Curve Flattening | Dewarp algorithm, API integration | 3-4 | E10 |
| E12 | Auto-Capture | Stability detection, auto-trigger | 1-2 | E11 |

**Phase 2 Total: ~8-11 sprints**

### Phase 2 Deliverable

- ✅ Everything from Phase 1
- ✅ Scan curved book pages
- ✅ Cloud-based dewarp processing
- ✅ Hands-free capture option

---

## Phase 3: Intelligence (Optional)

**Goal**: Add OCR and search capabilities.

| Epic | Name | Description | Sprints | Dependencies |
|------|------|-------------|---------|--------------|
| E13 | OCR Integration | Text extraction via backend | 2 | E11 |
| E14 | Search & Organization | Full-text search, folders, tags | 2 | E13 |

---

## Epic Status Tracker

| Epic | Status | Started | Completed | Notes |
|------|--------|---------|-----------|-------|
| E1 | 🔲 Not Started | — | — | |
| E2 | 🔲 Not Started | — | — | |
| E3 | 🔲 Not Started | — | — | |
| E4 | 🔲 Not Started | — | — | |
| E5 | 🔲 Not Started | — | — | |
| E6 | 🔲 Not Started | — | — | |
| E7 | 🔲 Not Started | — | — | |
| E8 | 🔲 Not Started | — | — | |
| E9 | 🔲 Not Started | — | — | |
| E10 | 🔲 Not Started | — | — | |
| E11 | 🔲 Not Started | — | — | |
| E12 | 🔲 Not Started | — | — | |
| E13 | 🔲 Not Started | — | — | Optional |
| E14 | 🔲 Not Started | — | — | Optional |

**Status Legend**: 🔲 Not Started | 🟡 In Progress | ✅ Complete | ⏸️ Blocked

---

## Technology Stack

### Mobile (Flutter)

| Category | Choice | Notes |
|----------|--------|-------|
| Framework | Flutter 3.19+ | Cross-platform |
| Language | Dart 3.3+ | Null safety enabled |
| State Management | Riverpod 2.x | With code generation |
| Navigation | GoRouter | Declarative routing |
| HTTP Client | Dio | For Phase 2 backend calls |
| Camera | camera package | Official Flutter plugin |
| Image Processing | image package | Pure Dart, on-device |
| Edge Detection | edge_detection / custom | Evaluate options in E4 |
| PDF | pdf + printing packages | Pure Dart |
| Local Storage | drift or isar | SQLite or NoSQL |

### Backend (Phase 2)

| Category | Choice | Notes |
|----------|--------|-------|
| Framework | FastAPI | Python async API |
| Language | Python 3.11+ | Type hints required |
| Image Processing | OpenCV, NumPy | Heavy lifting |
| OCR | Azure AI Vision / Tesseract | Phase 3 |
| Cloud | Azure App Service | Your existing expertise |
| Storage | Azure Blob Storage | For processed images |

---

## Key Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-XX-XX | Flutter over React Native | Better camera/image performance |
| 2025-XX-XX | Flutter-first MVP | Validate mobile skills before backend |
| 2025-XX-XX | On-device edge detection | Real-time feedback, no latency |
| 2025-XX-XX | Backend for curve flattening | Too heavy for mobile |
| 2025-XX-XX | OCR optional (Phase 3) | Core value is scanning, not text |

---

## File Structure

```
openscan/
├── CLAUDE.md                    # Development standards
├── README.md                    # Project overview, setup
├── docs/
│   ├── ROADMAP.md              # This file
│   └── specs/
│       ├── E1-project-setup.md
│       ├── E2-camera-module.md
│       ├── E3-local-gallery.md
│       └── ...
├── mobile/                      # Flutter app
└── backend/                     # FastAPI (Phase 2)
```
