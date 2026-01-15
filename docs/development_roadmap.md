Perfect, those choices give us a clear direction. Let me help you finalize the tech stack and then we'll refine the MVP roadmap.

## Tech Stack Decision: Flutter vs React Native

For a document scanner with heavy image processing, here's my analysis:

| Aspect | Flutter | React Native |
|--------|---------|--------------|
| **Camera/Image perf** | Superior — compiles to native, smoother preview | Good, but bridge overhead on heavy processing |
| **Image processing libs** | Strong OpenCV bindings, native plugin ecosystem | Decent, but often requires native modules |
| **Learning curve** | Dart is new, but simple and consistent | JS/TS likely more familiar from web/Apps Script |
| **Hot reload** | Excellent | Excellent |
| **Azure integration** | Standard HTTP/REST, no special advantage | Same |
| **Your background** | New language, but clean architecture patterns | Closer to what you know |

**My recommendation: Flutter**

For a scanner app specifically, Flutter's rendering performance and tighter native integration for camera/image work makes it the stronger choice. Dart is straightforward — you'll pick it up quickly with your programming background.

---

## Refined MVP Roadmap

Given "basic usable scanner first," here's the streamlined path to a working app:

```
┌─────────────────────────────────────────────────────────────────┐
│                        MVP MILESTONE                            │
│      "Capture → Detect Edges → Correct → Save as PDF"          │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ E1: Project   │────▶│ E2: Camera    │────▶│ E3: Capture   │
│    Setup      │     │    Module     │     │   & Gallery   │
│  (1 sprint)   │     │  (1 sprint)   │     │  (1 sprint)   │
└───────────────┘     └───────────────┘     └───────────────┘
                                                    │
        ┌───────────────────────────────────────────┘
        ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│ E4: Edge      │────▶│ E5: Perspective│────▶│ E6: Manual    │
│  Detection    │     │  Correction    │     │   Adjust UI   │
│ (2 sprints)   │     │  (1 sprint)    │     │  (1 sprint)   │
└───────────────┘     └───────────────┘     └───────────────┘
                                                    │
        ┌───────────────────────────────────────────┘
        ▼
┌───────────────┐     ┌───────────────┐
│ E7: Multi-page│────▶│ E8: PDF       │
│   Scanning    │     │   Export      │
│  (1 sprint)   │     │  (1 sprint)   │
└───────────────┘     └───────────────┘
        │
        ▼
   ┌─────────┐
   │   MVP   │
   │ COMPLETE│
   └─────────┘
```

**Total MVP estimate: 9 sprints** (assuming 1-week sprints, ~2 months)

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      MOBILE APP (Flutter)                   │
├─────────────────────────────────────────────────────────────┤
│  UI Layer        │  Camera  │  Gallery  │  Document View   │
├─────────────────────────────────────────────────────────────┤
│  Business Logic  │  Capture Flow  │  Document Management   │
├─────────────────────────────────────────────────────────────┤
│  Services        │  Camera Service │ Storage │ API Client  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                   CLOUD BACKEND (Azure)                     │
├─────────────────────────────────────────────────────────────┤
│  API Layer (Python/FastAPI)                                 │
├─────────────────────────────────────────────────────────────┤
│  Processing      │ Edge Detection │ Perspective │ OCR      │
│  Services        │ (OpenCV)       │ Correction  │ (later)  │
├─────────────────────────────────────────────────────────────┤
│  Storage         │ Azure Blob Storage │ Cosmos DB (metadata)│
└─────────────────────────────────────────────────────────────┘
```

---

## Ready for Epic 1?

Shall I draft the detailed specification for **E1: Project Setup**? This will include:

- Flutter project initialization with recommended folder structure
- State management choice (Riverpod recommended for this type of app)
- Navigation setup
- Basic theming/design system foundation
- CI/CD pipeline skeleton (GitHub Actions or Azure DevOps)
- Backend project scaffold (FastAPI + Azure setup)

Or do you want to discuss/adjust anything in the roadmap first?