# INSOMNIAC Project Status Report

Audit date: June 12, 2026  
Engine verified: Godot 4.6.3 stable official (`7d41c59c4`)  
Audit basis: live worktree at commit `ccfb63f` (`v0.05-DPI-suspicion-events`) plus current uncommitted files and changes

## Executive Summary

INSOMNIAC is a working single-room first-person prototype with a tested economy,
crafting, customer-order, reputation, heat, DPI-warning, and save/load backend.
The current playable loop boots cleanly and all 13 smoke tests pass.

The committed history ends at v0.05. The live worktree contains a passing
implementation of paid repeatable-order refresh for v0.06, project documentation
for v0.07, six additional validated order resources, and an unintegrated set of
apartment art-blockout props/materials. These changes are not yet represented by
a later commit/tag. The playable Customer Order Board still contains only the
original three orders, and the new prop scenes are not instanced in the apartment.

## 1. Current Milestone Status

| Milestone | Live-repo status | Evidence |
| --- | --- | --- |
| `v0.01-core-economy-loop` | Implemented and committed | Movement/interactions, inventory, wallet, three recipes, supply buying, selling, and stashing are playable and tested. |
| `v0.02-save-load` | Implemented and committed as a backend | `SaveManager` persists core state to JSON at `user://save_slot_1.json`; no in-game save/load controls or UI exist. |
| `v0.03-customer-orders` | Implemented and committed | Three playable orders support cycling, fulfillment, rewards, completion protection, panel display, and persistence. |
| `v0.04-reputation-heat-foundation` | Implemented and committed | Reputation and 0-100 heat stats receive order rewards, update the HUD, and persist. |
| `v0.05-DPI-suspicion-events` | Implemented and committed; current HEAD | One-time warning events trigger at heat 20, 40, 60, and 80, update HUD status, and persist triggered thresholds. |
| `v0.06-repeatable-orders` | Implemented in the uncommitted live worktree; not formally closed | `F` refreshes completed orders for $50, allowing rewards and heat progression to repeat. The dedicated smoke test passes. Refresh clears all completion flags rather than rotating/generating a new set. |
| `v0.07-project-docs-and-roadmap` | Present but uncommitted/in progress | `PROJECT_STATE.md`, `ROADMAP.md`, `IDEAS.md`, and `AGENT_RULES.md` exist in the live worktree. `PROJECT_STATE.md` still marks v0.06 pending/in progress. |

Additional live-worktree content:

- Six extra order resources and a passing content-validation test exist, but the
  playable board scene still references only the original three orders.
- Twelve prop scenes and associated materials exist for an apartment art
  blockout, but none are instanced into `Apartment.tscn`.

## 2. Current Playable Loop

`Main.tscn` creates `HeatEventManager`, `Apartment`, and `HUD`. Inside the
apartment, the player can:

1. Move with WASD, jump with Space, click to capture the mouse, and press Escape
   to release it.
2. Aim a 4.5-unit interaction ray at the Dream Encoder, Supply Terminal, Sell
   Terminal, Stash Box, or Customer Order Board.
3. Start with enough ingredients to craft several Lucids, use `R` to select a
   recipe/offer/order, and use `E` to act.
4. Encode Beach Loop, Fast Life, or Penthouse over a two-second timer.
5. Sell all carried Lucids for money, buy more ingredients, deposit all carried
   Lucids into the stash, or fulfill one of three customer orders.
6. Gain money, reputation, and heat from orders. DPI warning messages appear as
   heat crosses 20/40/60/80.
7. After at least one order is completed, use `F` at the order board to pay $50
   and clear all completed-order flags so orders can be fulfilled again.

Important playable limitations:

- The wallet starts at $0; the initial ingredient inventory is the bootstrap.
- The stash is deposit-only; there is no withdrawal interaction.
- Save/load exists only as a backend/API and smoke-test path, not as a player-facing action.
- Heat can be reduced by API, but no current playable interaction reduces it.
- DPI events are warnings only; there is no raid or other consequence.

## 3. Current Systems

| System | Current behavior |
| --- | --- |
| Player movement/interactions | First-person `CharacterBody3D`; WASD movement, Space jump, mouse look/capture, Escape release, and a forward raycast. `E` calls `interact`, `R` calls `secondary_interact`, and live v0.06 adds `F` calling `refresh_orders` when supported. |
| Inventory | Dictionary-backed item stacks with add, remove, requirement checks, clear, debug text, and save restore. No capacity, categories, equipment, or UI beyond HUD debug text. |
| Wallet | Nonnegative integer balance with add, affordability check, spend, set, signal updates, and save support. Starts at $0. |
| Dream Encoder | Three selectable resource-driven recipes; validates/removes ingredients immediately, waits two seconds, then adds output. Exposes recipe stats, requirements, availability, and progress to MachinePanel. |
| Supply Terminal | Seven selectable offers. Purchases spend wallet money and add ingredient items. |
| Sell Terminal | Sells all carried Beach Loop, Fast Life, and Penthouse items at fixed script prices of $25/$65/$90. Prices duplicate the current Lucid resource values. |
| Stash Box | Deposits all carried recognized Lucids and persists contents. No withdrawal path exists. |
| Customer Order Board | Three playable fixed orders. Supports cycling, fulfillment, one-time completion protection, money/reputation/heat rewards, panel details, and save/load. |
| Order refresh | Live uncommitted v0.06 behavior: after any completion, `F` spends $50 and clears every completion flag. It does not change the order list or selected index. |
| Reputation | Nonnegative integer; currently gained only from order fulfillment. Displayed and persisted. No current spending, gating, or unlock effects. |
| Heat | Integer clamped to 0-100; currently gained from order fulfillment. Displayed and persisted. A reduce API exists but is not used by playable content. |
| DPI heat events | One-time warnings at heat 20/40/60/80: Noticed, Watched, Targeted, and Lockdown Risk. Triggered thresholds persist. |
| Save/load | Version-1 JSON backend at `user://save_slot_1.json`; validates required economy data, supports older saves missing later optional sections, and rejects unsupported versions. Not connected to an in-game UI/input. |
| HUD/MachinePanel | HUD shows inventory debug text, money, reputation, heat level, interaction prompt, and status. MachinePanel shows encoder-specific data or generic terminal/order/stash sections. Layout uses fixed 1280x720-oriented offsets with canvas-item stretch. |

## 4. Current Data and Resources

### Lucid Items

| ID | Display name | Clarity | Intensity | Stability | Duration | Heat | Value | Corruption |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `beach_loop` | Beach Loop | 20 | 10 | 80 | 30 | 5 | $25 | 2 |
| `fast_life` | Fast Life | 35 | 55 | 55 | 20 | 18 | $65 | 12 |
| `penthouse` | Penthouse | 50 | 35 | 65 | 35 | 12 | $90 | 8 |

Ingredient/basic items: Blank Cartridge, Beach Fragment, Calm Layer, Speed
Fragment, Hype Layer, Luxury Fragment, and Premium Layer.

### Recipes

| Recipe | Output | Ingredients |
| --- | --- | --- |
| Beach Loop | Beach Loop x1 | Blank Cartridge x1, Beach Fragment x1, Calm Layer x1 |
| Fast Life | Fast Life x1 | Blank Cartridge x1, Speed Fragment x1, Hype Layer x1 |
| Penthouse | Penthouse x1 | Blank Cartridge x1, Luxury Fragment x1, Premium Layer x1 |

### Supply Offers

| Offer | Received item | Amount | Price |
| --- | --- | ---: | ---: |
| Blank Cartridge Pack | Blank Cartridge | 3 | $30 |
| Beach Starter Pack | Beach Fragment | 2 | $20 |
| Calm Layer Pack | Calm Layer | 2 | $20 |
| Speed Fragment | Speed Fragment | 1 | $30 |
| Hype Layer | Hype Layer | 1 | $30 |
| Luxury Fragment | Luxury Fragment | 1 | $45 |
| Premium Layer | Premium Layer | 1 | $45 |

### Customer Orders

| Order | Customer | Request | Payout | Reputation | Heat | Playable board |
| --- | --- | --- | ---: | ---: | ---: | --- |
| Quiet Night | Milo | Beach Loop x1 | $40 | +2 | +1 | Yes |
| Fast Fix | Vex | Fast Life x1 | $90 | +3 | +4 | Yes |
| Penthouse Trial | June | Penthouse x1 | $130 | +5 | +3 | Yes |
| Study Break | Nia | Beach Loop x1 | $45 | +2 | +1 | No; resource only |
| Late Shift | Rowan | Beach Loop x2 | $85 | +3 | +2 | No; resource only |
| Street Blur | Kade | Fast Life x1 | $95 | +3 | +5 | No; resource only |
| Afterparty | Vex | Fast Life x2 | $175 | +5 | +8 | No; resource only |
| Glass Room | June | Penthouse x1 | $140 | +5 | +4 | No; resource only |
| Private Floor | Vale | Penthouse x2 | $260 | +8 | +7 | No; resource only |

### Save Data Fields

- `save_version`
- `wallet.money`
- `inventory`: item ID to amount dictionary
- `player_stats.reputation`, `player_stats.heat`
- `heat_events.triggered_thresholds`
- `stash_boxes[]`: `node_path`, `contents`
- `dream_encoders[]`: `node_path`, `selected_recipe_index`
- `supply_terminals[]`: `node_path`, `selected_offer_index`
- `customer_order_boards[]`: `node_path`, `selected_order_index`, `completed_orders`
- `player_position.x`, `player_position.y`, `player_position.z`

Not saved: player rotation/look direction, an active encoder job, HUD/status text,
or any explicit refresh counter/history.

## 5. Tests

All tests were run sequentially with Godot 4.6.3 because save-related tests
share `user://save_slot_1.json`.

| Smoke test | Result |
| --- | --- |
| `customer_order_board_integration_smoke_test.gd` | PASS |
| `customer_order_board_smoke_test.gd` | PASS |
| `customer_order_save_smoke_test.gd` | PASS |
| `economy_smoke_test.gd` | PASS |
| `heat_events_backend_smoke_test.gd` | PASS |
| `heat_events_integration_smoke_test.gd` | PASS |
| `more_orders_content_smoke_test.gd` | PASS |
| `repeatable_orders_smoke_test.gd` | PASS |
| `reputation_heat_save_hud_smoke_test.gd` | PASS |
| `reputation_heat_stats_smoke_test.gd` | PASS |
| `save_system_smoke_test.gd` | PASS |
| `supply_terminal_smoke_test.gd` | PASS |
| `vertical_slice_smoke_test.gd` | PASS |

The save-system test intentionally writes invalid JSON to verify safe failure. Its
expected warning appeared, the test passed, and it removed the test save.

## 6. Main Scene Boot

`res://scenes/main/Main.tscn` booted headlessly for five frames/iterations with
Godot 4.6.3 and exited with code 0. No project warning or error appeared.

An initial sandboxed launch crashed because Godot could not open its external
`user://logs` path. The unrestricted rerun passed, so this was an audit
environment restriction rather than a project boot failure.

## 7. Web-Readiness Check

| Check | Status |
| --- | --- |
| Godot 4.6.3 | Confirmed by project feature metadata and runtime executable. |
| GDScript only | Confirmed for project source; no `.cs` files or C# project files found. |
| Compatibility renderer | Confirmed: desktop and mobile rendering methods are `gl_compatibility`. |
| Web export preset | Present; exports all resources with extension support and thread support disabled. |
| No native plugins | Confirmed; no GDExtension/native plugin configuration or project native binaries found. |
| No threads | Confirmed by source scan and Web preset `variant/thread_support=false`. |
| Desktop-only assumptions | No obvious desktop-only API use beyond keyboard/mouse-oriented controls. Runtime file access is limited to the web-supported `user://` save path. |

The repository appears web-friendly, but this audit did not generate or run a
Web export because doing so would create files outside the allowed report-only
change. Browser behavior and the configured Jolt Physics option should still be
validated in an actual Web export before release.

## 8. Risk List

1. **Uncommitted live baseline:** committed history stops at v0.05, while v0.06,
   v0.07, extra orders, and art-blockout assets are uncommitted. This is the
   largest immediate coordination and loss risk.
2. **`scripts/save/save_manager.gd`:** broad shared dependency with versioned
   schema, reflective/group-based discovery, and node-path identity. Load applies
   some sections before all later sections are validated, so malformed saves can
   partially mutate state before returning failure.
3. **`scripts/world/customer_order_board.gd`,
   `scripts/player/interaction_controller.gd`, and `project.godot`:** the live
   repeatable-order change spans all three. Parallel edits can easily break input,
   panel behavior, or refresh semantics.
4. **`scenes/world/CustomerOrderBoard.tscn`:** still wires only three of nine
   valid order resources. The new content is tested as files but is not playable.
5. **`scripts/core/game.gd` and `scenes/main/Main.tscn`:** startup wiring depends
   on fixed scene paths and recursively connects status sources. Hierarchy changes
   can break HUD/stats/event integration.
6. **`scenes/apartment/Apartment.tscn`:** integration tests depend on current
   machine positions and raycast reach. Art-blockout integration can accidentally
   obstruct movement or interactions.
7. **HUD/MachinePanel layout:** fixed pixel offsets are tuned to 1280x720. Canvas
   stretch helps, but browser aspect ratios and small viewports remain unverified.
8. **Data duplication:** sell prices are hardcoded in `sell_terminal.gd` instead
   of read from Lucid resources, creating drift risk.
9. **Progression endpoints:** repeatable orders can drive heat to 100, but there
   is no playable heat reduction or consequence beyond one-time warnings.
10. **Stash usability:** depositing removes all carried Lucids with no withdrawal,
    which can strand value from the active loop.
11. **Content quality:** `afterparty.tres` contains a mojibake/corrupted apostrophe
    in its flavor text, indicating an encoding cleanup is needed before that order
    is exposed.
12. **Runtime coverage gap:** all native headless tests pass, but no Web export or
    browser runtime test was performed.

## 9. Recommended Next Milestones

1. **Close v0.06-repeatable-orders:** manually playtest the paid clear-all refresh
   loop, confirm that clear-all behavior and the $50 price are intentional, then
   commit/tag the passing implementation and update milestone status.
2. **Close v0.07-project-docs-and-roadmap:** reconcile the docs with the live
   implementation, record the unintegrated order/art content accurately, and
   commit the documentation baseline.
3. **v0.08-apartment-art-blockout integration:** instance the existing prop scenes
   into `Apartment.tscn` in a small visual pass while preserving navigation,
   interaction sightlines, Compatibility rendering, and Main boot.

The six extra validated orders can then form a focused v0.09 content integration
after the current baseline and apartment layout are stable.

## 10. Same-Live-Repo Agent Advice

Safe parallel work, with explicit file ownership:

- Read-only audits and smoke-test runs, except save-related smoke tests must run
  sequentially because they share one `user://` save slot.
- Independent new order `.tres` resources or independent content-validation tests.
- Independent new prop scenes/materials that do not edit `Apartment.tscn`.
- Separate documentation files, provided no agent rewrites another agent's file.

Single-agent-only or tightly serialized work:

- Save schema or `save_manager.gd`.
- `project.godot`, input actions, or export settings.
- `Main.tscn`, `Apartment.tscn`, `PlayerDesktopRig.tscn`, or shared UI scenes.
- `game.gd`, `interaction_controller.gd`, `customer_order_board.gd`, and
  `CustomerOrderBoard.tscn`.
- Any milestone that changes multiple shared systems, scene paths, or persistence
  behavior.

## Audit Summary

- Files changed by this audit: `PROJECT_STATUS_REPORT.md` only.
- Tests run: 13 smoke tests plus direct headless `Main.tscn` boot.
- Test results: 13 PASS, 0 FAIL.
- Main scene boot: PASS under Godot 4.6.3, exit code 0.
- Recommended next update: close and commit/tag `v0.06-repeatable-orders` after a
  manual playtest of the paid clear-all refresh behavior.
