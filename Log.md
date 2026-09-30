## 2026-09-24 15:06 — ObservableObject → @Observable
- Converted `LocationManager` and `PhotoCollection` to `@Observable` (dropped `@Published`, Combine).
- `PhotosModel.photoCollection` now observed so album swaps refresh views.
- Simulator build OK; pre-existing `IsolatedConformances` warning unchanged.
- Time: ~10 min
