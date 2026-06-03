# AI Agent (browser-use) feature — context & status

Personal demo: browser-use-style AI agent inside firefox-ios. Type goal in address bar
→ agent reads page (perceive) → LLM plans → acts (click/type/navigate). NOT for ship.
Goal = showcase engineering. Branch: `feat/Agentic-browsing`.

## Origin — standalone prototype
First built standalone iOS app `/Users/kartikay/Desktop/testDOMExtraction/` to prove
perceive→LLM→act on a real `WKWebView`. Now porting concepts into firefox-ios using its
existing patterns. Prototype files (source of truth for logic):
- `WebAgentHelper.js` — perception (indexed elements + real visibility + page text)
- `Models.swift` — AgentElement/PageSummary/AgentPageMap + `agentText` serializer
- `WebExtractor.swift` — owns WKWebView, inject JS, `executeAction` (click/type/select/
  scroll/navigate), `typeAndSubmit`
- `AgentLLM.swift` — GroqClient (BYOK) + Apple FoundationModels behind one protocol;
  `AgentDecision{thought,action,index,text,url,answer}`; tolerant JSON parser

Sibling CLI (teaching/oracle, jsdom, no real visibility):
`/Users/kartikay/Desktop/web-agent-demo/`.

## firefox-ios mapping (key insight)
Do NOT port the owned WKWebView. Operate on the **active Tab's** webView as a
service/helper. Mirror existing firefox patterns:
- JS injection = `window.__firefox__.X` modules, glob-bundled by webpack (like
  `Summarizer.js`).
- Swift→JS = `webView.callAsyncJavaScript("return await window.__firefox__...", contentWorld: .defaultClient)`
  then JSONSerialization→JSONDecoder (like `SummarizationChecker.swift`).
- LLM backends = shape like `SummarizerProtocol` (LiteLLM remote + FoundationModels).
- Panel UI = reuse shake-to-summarize visual (page snapshot slides down).

## DONE
**Step 1 — entry point + placeholder toggle**
- Main-menu pill adds "AI Agent" item (icon `Large.summarizer`) between Downloads &
  Passwords. `MainMenuConfigurationUtility.swift`.
- Tap → `MainMenuAction(.aiAgent)` → `MainMenuCoordinator.handleDestination` →
  dispatch `ToolbarAction(.toggleAIAgentMode)`.
- `ToolbarState.isAIAgentMode` Bool (threaded through every reducer copy point +
  `defaultState`). Toggle reducer = `handleToggleAIAgentMode`.
- Placeholder swaps to "Ask AI Agent…" via `AddressToolbarContainerModel` →
  `LocationViewConfiguration.isAIAgentMode`. In AI mode the field shows placeholder even
  with a page loaded (clears URL text). `LocationView.configureURLPlaceholder` +
  `configureURLTextField`.
- Bug fixed: `AddressToolbarContainerModel ==` missing `isAIAgentMode` → placeholder
  only refreshed on focus. Added to `==`.
- Strings: `.AddressToolbar.AIAgentPlaceholder`, `.MainMenu.PanelLinkSection.AIAgent`.

**Step 2 — thoughts peek panel**
- `AIAgentThoughtsViewController` (`Client/Frontend/Browser/AIAgent/`). Child VC over
  BVC. Reuses summarize look: page **snapshot slides DOWN** (~13%) to reveal thoughts;
  red gradient bg (`layerGradientSummary`), light text, X-close, swipe-up dismiss.
- Trigger: `BrowserViewController.didSubmitSearchText` — if `isAIAgentMode`, intercept,
  `presentAIAgentThoughts(prompt:)` instead of navigating. Snapshot cropped like
  `SummarizeCoordinator` (`view.snapshot` + content-area crop).

**Step 3 — Groq key field + real perception (current)**
- Settings → AI Controls: "Groq API Key (BYOK)" SecureField. `AIControlsModel.groqAPIKey`
  + `setGroqAPIKey` → `prefs` (`PrefsKeys.Settings.groqAPIKey`).
  `AIControlsSettingsView.groqAPIKeyCard`.
- Perception JS: `UserScripts/MainFrame/AtDocumentStart/WebAgent.js` →
  `window.__firefox__.WebAgent.extractPage()` returns `{pageText, summary, elements[]}`.
  Stamps `data-agent-id`. **`npm run build`** regenerates
  `Client/Assets/MainFrameAtDocumentStart.js`.
- Swift: `AIAgentModels.swift` (Codable map + `agentText`), `WebAgentPerception.swift`
  (`extract(on:)` mirrors SummarizationChecker, 4× settle-retry).
- Panel now shows REAL data: title, element counts (total/visible/typeable/clickable),
  prompt. Replaced mock thoughts.

**Step 4 — LLM + action loop (current)**
- `AgentLLM.swift` / `GroqClient`: Groq BYOK, `parseDecision`, compact step history in prompt.
- `AIAgentService.swift`: perceive→decide→act loop; skips extraction on internal/home URLs;
  navigate/search delegated to `BrowserViewController` on captured `Tab`.
- `WebAgentActor.swift` + `WebAgent.js` `doAction`: click/type/select/scroll/typeSubmit.
- Panel shows live thought line; snapshot card refreshed each step (live web view not exposed).

## NOT DONE (next)
- ❌ FoundationModels backend.
- ❌ Keychain for Groq key (prefs prototype; Settings key field is `#if DEBUG` only).
- ❌ Feature flag / ship-quality gating for menu entry and agent mode.

## Gotchas (hard-won)
- `callAsyncJavaScript` wraps source in async fn → needs top-level `return`, NO IIFE.
  Bundled `window.__firefox__` modules avoid this (call `return await ...`).
- **JS edit → `npm run build`** (webpack) or stale bundle. Swift-only edits don't.
- `isTrusted` ceiling: synthetic click/value works for search/links; FAILS payment/
  OAuth/file-picker (WebKit can't synth trusted gestures).
- Re-extract after action races page settle → retry on non-dict result.
- Viewport filter: only on-screen elements "visible"; below-fold dropped (scroll
  reveals). `summary.belowFoldCount` notes them.
- New Swift files under `Frontend/Browser/` need pbxproj entry (NOT a synced root).
  Use the `xcodeproj` ruby gem to add (target = Client). `.js` is glob-bundled, no
  project entry.
- Build: scheme `Fennec`, sim iPhone 17 (project at `firefox-ios/firefox-ios/Client.xcodeproj`).

## Key files
| Area | File |
|---|---|
| menu item | `Client/Frontend/Browser/MainMenu/MainMenuConfigurationUtility.swift` |
| menu→toolbar | `Client/Frontend/Browser/MainMenu/MainMenuCoordinator.swift` |
| toolbar state | `Client/Frontend/Browser/Toolbars/Redux/ToolbarState.swift`, `ToolbarAction.swift` |
| placeholder | `Client/Frontend/Browser/Toolbars/Models/AddressToolbarContainerModel.swift`; `BrowserKit/.../LocationView/LocationView.swift`, `LocationViewState.swift` |
| panel | `Client/Frontend/Browser/AIAgent/AIAgentThoughtsViewController.swift` |
| service / LLM | `AIAgentService.swift`, `AgentLLM.swift`, `WebAgentActor.swift` |
| trigger | `BrowserViewController.swift` (`didSubmitSearchText`, `presentAIAgentThoughts`) |
| perception JS | `UserScripts/MainFrame/AtDocumentStart/WebAgent.js` → webpack → `MainFrameAtDocumentStart.js` |
| perception Swift | `AIAgentModels.swift`, `WebAgentPerception.swift` |
| key field (DEBUG) | `AIControlsModel.swift`, `AIControlsSettingsView.swift` |
| tests | `firefox-ios-tests/.../AIAgent/AIAgentServiceTests.swift` |
| prefs key | `BrowserKit/Sources/Shared/Prefs.swift` (`PrefsKeys.Settings.groqAPIKey`) |

## Templates to copy (firefox already has)
- `BrowserKit/Sources/SummarizeKit/Backend/SummarizationChecker.swift` — JS-call+decode
- `.../SummarizerProtocol.swift`, `LLM/LiteLLMSummarizer.swift`, `AppleIntelligence/
  FoundationModelsSummarizer.swift` — LLM backend shape
- `.../SummarizerService.swift` — orchestrator (extract→llm) = agent-step shape
- `UserScripts/MainFrame/AtDocumentStart/Summarizer.js` — `window.__firefox__` register
