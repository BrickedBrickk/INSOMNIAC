# INSOMNIAC Project State

INSOMNIAC is a Godot 4.6.3 prototype focused on producing and selling fictional
dream cartridges called Lucids while managing money, reputation, and DPI heat.

## Current Core Loop

Buy supplies -> craft Lucids -> fulfill/sell orders -> earn money/reputation/heat
-> refresh orders -> trigger DPI warnings.

## Milestones

| Milestone | Status | Summary |
| --- | --- | --- |
| v0.01-core-economy-loop | Complete | Added supplies, Lucid crafting, inventory, selling, stashing, and money flow. |
| v0.02-save-load | Complete | Added persistence for core player and world progress. |
| v0.03-customer-orders | Complete | Added customer orders, fulfillment rewards, and order persistence. |
| v0.04-reputation-heat-foundation | Complete | Added player reputation and heat stats with HUD display and persistence. |
| v0.05-DPI-suspicion-events | Complete | Added one-time DPI warning events at escalating heat thresholds. |
| v0.06-repeatable-orders | Pending / in progress | Expand orders into a renewable gameplay loop without removing current progression. |

## Current Scope

- One playable apartment containing the current crafting and economy interactions.
- Lucid recipes, supplies, inventory, wallet, stash, selling, and customer orders.
- Reputation and heat progression.
- DPI suspicion warnings at heat thresholds.
- Save/load persistence for implemented progression systems.

Combat, raids, territories, vehicles, employees, and expanded locations are not
part of the current playable scope.
