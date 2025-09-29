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
- [UI 與資料模型](./docs/specs/1-supply-ui.md)
- [Firebase 整合](./docs/specs/2-supply-firebase.md)

### 最近的決策與變更

- **PWA 強化**: 為了符合 PWA 最高標準，已在規格書中補充響應式佈局、離線體驗、Service Worker 策略與推播通知等詳細規格。
- **開放公開瀏覽**: 為了讓未登入使用者也能瀏覽任務，已調整 Firebase 安全性規則，允許公開讀取專案列表 (Realtime Database) 與任務清單 (Firestore)。所有寫入操作仍需登入。

### 開發進度

- **UI 實作階段已完成**: 所有頁面、元件、狀態模擬與路由（包含路由守衛）均已根據規格書建構完畢。App 已具備完整的、以模擬數據驅動的互動流程。
- **下一步**: 整合 Firebase 後端服務，將所有模擬數據與操作替換為真實的後端數據。
