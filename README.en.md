# ⛩️  miko

[日本語](./README.md) | English

<img src="./logos/miko.png" width="200px">

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill set for Business-Rules-Driven Development. "Business-Rules-Driven Development" is not an established industry term — it is the development methodology defined by miko.

The name comes from *miko* (巫女), the shrine maiden who mediates between gods and people at a Shinto shrine. In the same spirit, miko builds a foundation where Nushi-sama (主さま — that's you) and AI share domain knowledge.

## ⛩️  Philosophy

### What is a business rule?

A business rule states **what is true in this business** — not how the system behaves.

It is easy to confuse with neighboring concepts, so here is the distinction:

| | Business rule | Specification | Business logic |
|---|---|---|---|
| **Question** | "What is true?" | "How does it behave?" | "How is it computed?" |
| **Example** | An unpaid order cannot be shipped | Pressing Cancel shows a confirmation dialog | Total = price × quantity − discount |
| **When the implementation changes** | Unchanged (it is a business decision) | May change (it is a means of realization) | May change (it is a computation procedure) |
| **Where it lives** | `business_rules.md` | Functional Specification in a proposal / spec.md | Code |

**The tiebreaker question:** "If the implementation technology or UI changed, would this statement still hold?" — Yes means business rule; No means specification.

### Why business rules — what we learned from SDD

After trying SDD (Specification-Driven Development), we found that overly detailed specifications end up almost one-to-one with the implementation, and wither away once the implementation lands. Code alone, on the other hand, never tells you *why*. Business rules sit at just the right level of abstraction to solve both problems.

| Layer | Human understanding | AI understanding | Value after implementation |
|---|---|---|---|
| SDD spec | Too detailed | Good | None (just read the code) |
| Business rules | Just right | Good | **Yes (the "why" that code cannot express)** |
| Code | Good | Must re-read every time | The code itself |

### Capabilities and features

miko organizes documents by **capability**, not by feature.

- **Capability** = a large unit of business responsibility, such as "order management", "inventory management", or "notification delivery"
- **Feature** = an individual operation such as "order cancellation" or "stock allocation" — a part of a capability

Organizing by capability gathers related business rules in one place, which makes it much easier to keep the rules consistent with each other.

### Other design decisions

- **speckit is a surveying tool** — speckit artifacts are disposable. For heavy changes, we use speckit as a device to make Claude read the codebase deeply. Day-to-day implementation goes through `/miko.quick_impl`, without speckit
- **Division of labor between documents** — the rules themselves (conclusions) go in `business_rules.md`; why they were decided (history) goes in proposals

## 🌿 Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) is installed
- (Optional) The [speckit](https://github.com/github/spec-kit) skills — needed only if you use the full flow (`/miko.speckit.*`). Not required for the standard `/miko.quick_impl` flow

## ✨ Installation

Run the following at your project root.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/install.sh)
```

The skill files are placed under `.claude/skills/`.

The installer asks you to choose an output language (日本語 / English). Your choice is saved to `.miko/config`, and miko's conversation and generated documents are unified in that language. To skip the prompt, set an environment variable:

```bash
MIKO_LANG=en bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/install.sh)
```

After installation, set up your project:

```bash
/miko.setup
```

This surveys your codebase and generates `miko/system_high_level_design.md` — the guide every miko skill consults when exploring your code.

### Upgrading

To update an existing miko installation to the latest version, run the following at your project root.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/studyplus/miko/main/upgrade.sh)
```

Besides updating the skill files, this automatically runs any migrations needed for the documents under `miko/` (business rules, high-level designs, etc.).

### Protecting custom skills

If you have created your own skills named `miko.*`, you can **protect** them from being removed during upgrades. List the skill names in `.miko/protected_skills`, one per line:

```
# .miko/protected_skills
miko.my-custom-skill
miko.another-skill
```

Protected skills are excluded from upgrades — never removed or overwritten.

### Usage

Whenever you are unsure what to do, ask `/miko.miko`. It answers anything from "how do I use this?" to "should this go into the business rules?".

```bash
/miko.miko
```


## 🎍 Document structure

miko manages documents per capability under the `miko/` directory.

```
miko/
├── system_high_level_design.md       # System-wide architecture + code exploration guide
├── glossary.md                       # Glossary
└── <capability>/
    ├── business_rules.md             # Domain decision criteria (the protagonist)
    ├── high_level_design.md          # Structure and overview of the capability
    ├── harae.md                      # Findings from adversarial verification
    └── proposals/
        └── YYYY-MM-DD-<title>.md     # Change proposals and their history
```

| File | Role | Maintenance |
|---|---|---|
| `system_high_level_design.md` | System-wide architecture, including the code exploration guide | Generated by `/miko.setup`, kept current by `/miko.catchup_system_hld` |
| `glossary.md` | Term definitions (organized in per-capability sections) | Maintained by miko |
| `business_rules.md` | Domain decision criteria. Records the "why" that cannot be read from code | Maintained by miko |
| `high_level_design.md` | Structure and overview of the capability | Maintained by miko |
| `harae.md` | Findings from adversarial verification, with status tracking | Generated by `/miko.new_harae`, updated by `/miko.harae` |
| `proposals/` | Change proposals for the capability and their history | Nushi-sama provides the raw material; written together with miko |

## ⛩️  Skills

### Guide

| Skill | Purpose |
|---|---|
| `/miko.miko [what you want to do]` | Guides you to the right skill and flow for your goal |
| `/miko.version` | Shows the miko version |

### Setup

| Skill | Purpose |
|---|---|
| `/miko.setup [overview]` | Introduces miko to your project. Surveys the codebase and generates `miko/system_high_level_design.md` |
| `/miko.catchup_system_hld` | Brings `system_high_level_design.md` up to date with the codebase. Detects and fixes directory-structure drift |

### Document authoring

| Skill | Purpose |
|---|---|
| `/miko.new_cap <capability> [overview]` | Interactively creates business_rules.md and high_level_design.md for a new capability, drawing on existing code where available |
| `/miko.catchup <capability>` | Reconciles existing business_rules.md and high_level_design.md against the full codebase |
| `/miko.quick_catchup <capability> [diff]` | Creates a proposal from a code change (git diff / PR) and updates the BR/HLD. For after emergency fixes, etc. |
| `/miko.propose <capability> [raw material]` | Interactively creates a change proposal |
| `/miko.split_proposal <proposal>` | Splits a proposal into an umbrella (parent) + sub-proposals by phase |
| `/miko.new_harae <capability>` | First adversarial verification of the business rules. Generates harae.md from scratch |
| `/miko.harae <capability> [proposal]` | Reviews and extends an existing harae.md. With a proposal, records the findings inside the proposal |

### Implementation (standard flow)

| Skill | Purpose |
|---|---|
| `/miko.quick_impl <proposal \| capability \| change instruction>` | The standard flow: implements changes directly, without speckit. Accepts change instructions without a proposal (refactoring, etc.). Changes to BR text require a proposal. Heavy changes beyond its scope are routed to the full flow |

### Implementation (full flow — speckit extensions, for heavy changes)

Available only when speckit is installed.

| Skill | Purpose |
|---|---|
| `/miko.speckit.specify <proposal_path>` | Generates spec.md from a proposal |
| `/miko.speckit.clarify` | Interactively clarifies open questions in spec.md (optional) |
| `/miko.speckit.plan [feature_dir]` | Generates an implementation plan + test design (test_design.md). Argument optional |
| `/miko.speckit.tasks [feature_dir]` | Generates a task list in vertical-slice order. Argument optional |
| `/miko.speckit.analyze` | Consistency check across documents (optional) |
| `/miko.speckit.implement [feature_dir]` | Implements with per-phase checkpoints + self-review. Argument optional |

## 🌿 Development flow

### Initial setup (when introducing miko to a project)

```
/miko.setup
  → Surveys the codebase and generates miko/system_high_level_design.md
```

### Defining a new capability

```
/miko.new_cap <capability>
  → Interactively creates business_rules.md + high_level_design.md

/miko.new_harae <capability>
  → Adversarially probes the defined rules for contradictions and gaps. Generates harae.md

→ After fixing the findings, re-verification with /miko.harae <capability> is recommended
```

### Changing an existing capability

**Proposal phase** (build team consensus)

```
/miko.propose <capability> <raw material>
  → Creates the proposal

/miko.harae <capability> <proposal>
  → Adversarially verifies the rule set as it would be after the proposal. Findings are recorded in the proposal

# Optional
/miko.split_proposal <proposal>
  → For large changes only, splits into umbrella (parent) + subs by phase
```

**Implementation phase (standard: quick_impl)**

```
/miko.quick_impl <capability>
  → Implements directly, without speckit (for single-intent changes within the existing structure)
  → Afterwards, business_rules.md + high_level_design.md + harae.md are updated automatically
  → If the change exceeds this scope, you are guided to the full flow
```

**Implementation phase (full flow: speckit — for heavy changes)**

When a change involves multiple intents, requires exploration to pin down its impact, or moves the processing structure significantly, proceed with the speckit flow. If the proposal was split, run it for each sub-proposal.

```
/miko.speckit.specify <capability>
  → Generates spec.md

# Optional
/miko.speckit.clarify
  → Clarifies open questions

/miko.speckit.plan
  → Implementation plan + test design

/miko.speckit.tasks
  → Generates the task list

# Optional
/miko.speckit.analyze
  → Final pre-implementation check

/miko.speckit.implement
  → Implements (self-review + /simplify per feature)
  → After the final phase, business_rules.md + high_level_design.md + harae.md are updated automatically
```

### Refactoring without a proposal

Changes that do not alter business-rule text (renames, moves, redistributing responsibilities, etc.) can be implemented by passing the instruction directly to `/miko.quick_impl`, without a proposal.

```
/miko.quick_impl <change instruction>
  → Afterwards, affected implementation mappings are updated across all capabilities
  → If a BR text change turns out to be needed, you are guided to /miko.propose
  → If the change exceeds the scope (single intent, clear impact, mechanical or local), you are guided to the full flow
```

### Catching documents up with the code

```
# Bring system_high_level_design.md up to date
/miko.catchup_system_hld
  → Detects directory-structure drift and updates system_high_level_design.md

# Full scan (reconcile the whole capability)
/miko.catchup <capability>
  → Reconciles BR/HLD against the full codebase, detecting and applying differences

# Diff-based (apply a specific code change only)
/miko.quick_catchup <capability>
  → Creates a proposal from the current branch's diff + updates the BR/HLD

/miko.quick_catchup <capability> #8250
  → Creates a proposal from the PR's diff + updates the BR/HLD
```

## 🌾 Quality improvement during implementation

`/miko.quick_impl` (after implementing) and `/miko.speckit.implement` (per feature) automatically run the following self-reviews:

1. **Self-review** -- checks responsibility placement, naming, and framework conventions
2. **/simplify** -- checks for duplication, quality, and efficiency

`/miko.speckit.implement` additionally performs cross-feature refactoring in its final phase.
