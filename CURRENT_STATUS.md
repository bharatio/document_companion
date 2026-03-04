# Current Status

> See [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for the full roadmap and honest assessment of what works and what doesn't.

## Working Features (v1.0.0)

| Feature | Status | Notes |
|---------|--------|-------|
| Camera capture | Working | Manual shutter, `ResolutionPreset.ultraHigh` |
| Manual 4-corner crop | Working | Drag handles to adjust crop area |
| Edge detection | **Not working** | MethodChannel has no native handler. Always returns `null` |
| Perspective correction | **Not working** | Falls back to rectangular bounding-box crop |
| Image filters | Partial | Gray works. "Eco" is identical to Gray. No B&W threshold, no enhance |
| Folder management | Working | Create, rename, delete, tags, search, sort, date filters |
| Image management | Working | Save to folders, grid/list view, viewer with zoom/pan |
| PDF — create from images | Working | Multi-page PDF generation |
| PDF — merge | Working | Combine multiple PDFs |
| PDF — split | Working | Extract page ranges |
| PDF — compress | Working | Low/Medium/High quality presets |
| PDF — import | Working | File picker, import to folders |
| PDF — to Word | Working | Text extraction + .docx generation |
| Batch operations | Working | Multi-select, batch delete/move/convert |
| Recent documents | Working | Tracking + quick access widget |
| Dark mode | Working | Theme toggle in settings |
| Ads | Working | Banner, interstitial, rewarded (Google Mobile Ads) |
| OCR | **Not implemented** | UI labels only, no ML Kit dependency |
| Auto-capture | **Not implemented** | — |
| Real-time contour overlay | **Not implemented** | Camera shows raw feed only |
| Tests | **Placeholder only** | Single counter-app test, not testing actual app |

## Known Bugs

See Phase 0 in [DEVELOPMENT_ROADMAP.md](DEVELOPMENT_ROADMAP.md) for the complete bug list.

Critical issues:
- `deleteCurrentImage()` missing WHERE clause — can delete all images
- `FolderBloc.updateFolder` `firstWhere` without `orElse` — crashes if folder not found
- StreamControllers never disposed — memory leaks
- Database named `"test.db"` in production

## Next Priority

**Phase 0** — Fix bugs and technical debt, then **Phase 1** — Make the scanner actually work.

---

*Last updated: 2026-03-04*
