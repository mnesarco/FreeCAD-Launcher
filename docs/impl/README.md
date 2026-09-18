# Implementation Plan — How To Work In This Repo

This directory is the **durable working memory** for the v2 rewrite. Work happens in many
sessions, possibly with different agents. Nothing important may live only in a chat: tasks,
status, and decisions must be written here.

Product truth lives in [`../spec/`](../spec/). This directory tracks execution against it.

## Files

| File | Purpose | Update frequency |
|---|---|---|
| [STATUS.md](STATUS.md) | Live snapshot: current milestone, next action, blockers, session log | Every session (start + end) |
| [TASKS.md](TASKS.md) | Task breakdown per milestone with acceptance criteria and status | As tasks start/finish |
| [DECISIONS.md](DECISIONS.md) | Append-only decision log (D-###). Never edit accepted entries | Whenever a decision is made |
| [VERIFICATION.md](VERIFICATION.md) | Commands, test matrices, and manual smoke checks | When verification changes |

## Session protocol

### 1. Start of session (always, in this order)

1. `git status`, `git log --oneline -5`, confirm the branch.
2. Read `docs/impl/STATUS.md` — current milestone, next action, blockers.
3. Read the current milestone section in `docs/impl/TASKS.md`.
4. Read `docs/impl/DECISIONS.md` (entries are short; read all).
5. Read only the spec sections referenced by the task (do not re-read the whole spec).
6. Restate to the user: the task, its acceptance criteria, and what will change.
7. Mark the task(s) `WIP` in `TASKS.md` and mirror them in `STATUS.md`.

### 2. Rules during work

- Work on **one milestone at a time**, only on planned tasks. If the user asks for something
  unplanned, add it to `TASKS.md` (with acceptance criteria) before doing it.
- Any choice affecting architecture, UX, data, distributions, or integrations that is not
  already in the spec or an accepted decision **must be asked about and then recorded** in
  `DECISIONS.md` before implementation.
- Keep the repo green: `flutter analyze` and `flutter test` must pass before ending a session.
- Generate drift code after schema changes; generated files are committed.
- Small, reviewable commits (see conventions below). Never commit secrets.
- If blocked, set the task `BLOCKED` in `TASKS.md`, write the blocker in `STATUS.md`, and ask.

### 3. End of session (always)

1. Run the verification belonging to the milestone (`VERIFICATION.md`).
2. Update task statuses in `TASKS.md`:
   - `DONE` only if the acceptance criteria are met and verified.
   - `WIP`/`BLOCKED` with a one-line note otherwise.
3. Append new decisions to `DECISIONS.md` (decisions are made *during* work, never defer them).
4. Update `STATUS.md`: milestone, in-progress, next action, blockers, and a session-log row
   with date, summary, task IDs, and touched files.
5. Commit (when the user has approved commits) using:

   ```
   <type>(<scope>): <summary> [M#-##]

   types: feat | fix | refactor | docs | test | chore | ci | build
   scope: foundation | builds | profiles | addons | python | macros | bundles | export | ui
   ```

### 4. Context budget

Do not reload everything every session. Minimum viable context = `STATUS.md` + active
milestone tasks + `DECISIONS.md` + the spec section for the task. Load `TASKS.md` backlog and
older decisions only when needed.

## Task IDs and statuses

- IDs: `M<milestone>-<nn>` (e.g. `M2-05`), spikes `S<n>` (e.g. `S1`), backlog `B-<nn>`.
- Statuses: `TODO` · `WIP` · `BLOCKED` · `DONE` · `DROPPED`.
- Effort: `S` (≈ half session), `M` (≈ one session), `L` (multiple sessions; split further if possible).

## Decision discipline

- One decision per entry, numbered increasing, never reused, never edited once `Accepted`.
- To change a decision: add a new entry with `Status: Accepted` and mark the old one
  `Superseded by D-###` in its status line only.
- Every decision includes: date, status, context, decision, consequences, references.
- Answers to spec open questions (OQ-x) must be recorded as decisions and the OQ table in
  `../spec/09-open-questions.md` updated to `Resolved by D-###`.

## Definition of Done (per task)

1. Acceptance criteria in `TASKS.md` met and verified per `VERIFICATION.md`.
2. `flutter analyze` clean and tests green (new logic has tests).
3. Loading / empty / error / offline states handled where UI is involved.
4. No secrets logged; errors mapped to `AppError` with actionable messages.
5. `TASKS.md`, `DECISIONS.md`, `STATUS.md` updated in the same session.
