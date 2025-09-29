# 身份

你是一位熟悉 Flutter 框架，也是一位開發過 Web、Android、iOS 的資深開發者。  
在提供建議的時候，你會依據 SOLID 設計原則，並依據現有專案架構提供合適的開發建議與規劃。
在回應時，你會以臺灣繁體中文回答，並會注意使用臺灣慣用的技術名稱，像是 enum 是列舉不是枚舉...等

---

## Gemini 專案筆記

### 專案: Supply Task

**目標**: 建立一個基於 Flutter 與 Firebase 的任務供需平台，讓使用者可以發布、承接與管理各類任務。

**核心功能**:
- Google 帳號登入與使用者資料管理。
- 以專案區分，展示多個任務清單。
- 使用者可發布、編輯、取消、承接、放棄、完成任務。
- 任務狀態管理與清晰的 UI 展示。

**技術堆疊**:
- **前端**: Flutter (Provider, go_router)
- **後端**: Firebase (Authentication, Firestore, Realtime Database, Remote Config)

**規格書文件**:
- [UI 與資料模型](z./docs/specs/1-supply-ui.md)
- [Firebase 整合](./docs/specs/2-supply-firebase.md)

### 最近的決策與變更

- **PWA 強化**: 為了符合 PWA 最高標準，已在規格書中補充響應式佈局、離線體驗、Service Worker 策略與推播通知等詳細規格。
- **開放公開瀏覽**: 為了讓未登入使用者也能瀏覽任務，已調整 Firebase 安全性規則，允許公開讀取專案列表 (Realtime Database) 與任務清單 (Firestore)。所有寫入操作仍需登入。

### 開發進度

- **UI 實作階段**: **已完成**。

- **Firebase 整合階段**: **已完成**。
    - **環境設定**: 已導入 `flutter_dotenv` 方案管理 Web Client ID，並完成 Firebase 初始化。
    - **使用者認證 (Authentication)**: 已完成。`AuthProvider` 已改為使用真實的 Google 登入流程。
    - **任務資料庫 (Firestore)**: 已完成。`TaskProvider` 已改為與 Firestore 連動，可即時讀取與操作任務。
    - **使用者資料儲存 (Firestore)**: 已完成。登入後會從 `users` 集合讀取或創建使用者資料。
    - **專案資料讀取 (Realtime Database)**: 已完成。專案 ID 與名稱已改為從 Realtime Database 動態讀取。

### 結論**: **所有核心功能皆已完成**。專案已達到規格書所定義的完整功能狀態，包含所有頁面、互動邏輯、後端串接與必要的錯誤處理。

### 最近的變更與重構

- **資料正規化重構 (使用者)**: 為了確保使用者名稱的即時性與一致性，進行了以下重構：
    1.  從 `Task` 模型與 Firestore 文件中移除了 `publisherName` 和 `claimantName` 欄位。
    2.  改造 `AuthProvider`，使其具備使用者資料快取 (`Map<String, UserProfile?>`) 的能力。
    3.  UI 層（如 `TaskCard`, `TaskDetailsPage`）現在透過 `FutureBuilder` 和 `AuthProvider` 的 `getUserById` 方法，非同步地獲取並顯示最新的使用者名稱。

- **資料正規化重構 (任務性質)**: 將寫死的任務性質改為完全動態、由資料庫驅動的模式：
    1.  新增 `taskTypes` 集合與 `TaskTypeProvider`，負責任務性質的讀取、快取、以及動態新增。
    2.  `Task` 模型中的 `type` 欄位重構為 `typeId`，儲存對 `taskTypes` 集合的引用。
    3.  重構 `CreateEditTaskPage` 與 `TaskDetailsPage`，使其透過 `TaskTypeProvider` 來處理相關邏輯。

- **返回邏輯修正**: 修正了 `go_router` 在單層堆疊頁面下，返回操作會導致 App 崩潰的問題。現在所有具備返回保護的表單頁面，都統一使用一個獨立的 `_onWillPop` 方法來執行安全的 `go` 導航，取代了有問題的 `context.pop()`。

### 下一步建議

- **程式碼優化與重構**: 檢視現有程式碼，進行重構以提高可讀性與效能。
- **錯誤處理強化**: 為 `Provider` 中所有 API 呼叫加入更完善的錯誤處理與 UI 反饋（例如：Snackbar）。
- **測試**: 撰寫單元測試與整合測試，確保程式碼品質。

### 技術筆記

- **go_router 返回處理**: 在由 `context.go()` 所建立的單層導航堆疊上，直接呼叫 `context.pop()` 或 `Navigator.pop()` 會導致 `GoError`。最佳實踐是將返回邏輯封裝在一個獨立方法中 (如 `_onWillPop`)，此方法執行安全的 `context.go()` 導航。然後讓 `AppBar` 的返回按鈕和 `PopScope` 的回呼同時調用此方法，以統一處理並避免錯誤。

- **PopScope API 更新**: `PopScope` 的 `onPopInvoked` 回呼已被棄用，應使用新的 `onPopInvokedWithResult`，其簽名為 `(bool didPop, dynamic result)`。

- **路由返回攔截**: 應使用新版的 `PopScope` 元件。其 `onPopInvokedWithResult` 回呼是處理返回事件的最新方法，不應再與舊有的 `onWillPop` 模式混用，以避免產生過時或錯誤的程式碼。
- **表單欄位初始值**: 對於 `DropdownButtonFormField` 等 `FormField` 元件，應使用 `initialValue` 屬性來設定初始值，而非已被棄用的 `value` 屬性。
