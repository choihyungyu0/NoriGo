# NoriGo Codex Instructions

## Core behavior

Do not ask follow-up questions during implementation.


Proceed with reasonable assumptions.
When information is missing, choose the safest, most common, MVP-friendly approach.
Do not stop and wait for user confirmation.
Do not ask the user to choose between options.
Make the decision yourself and continue.

Only ask a question when the task requires a real secret value:
- API key
- password
- private token
- paid service credential
- account login information

If a secret is missing, do not stop the whole task.
Create `.env.example` with placeholder values and continue implementing all non-secret parts.

## Flutter project rules

This project is a Flutter mobile app named NoriGo.

NoriGo is an AI travel assistant for Korea.
Main features:
- crowd-aware travel routes
- AI itinerary planning
- real-time cultural guide
- translation
- hidden local spots
- crowd alerts
- queue and wait-time help

Use the existing design language:
- deep purple
- lime green
- bright blue
- white
- soft lavender backgrounds
- rounded cards
- clean mobile UI
- Korean travel illustration mood

## Implementation rules

Before editing:
1. Inspect the folder structure.
2. Find existing screens, widgets, theme files, and assets.
3. Reuse existing components when possible.

When editing:
1. Make direct changes.
2. Avoid unnecessary rewrites.
3. Keep the UI consistent.
4. Prefer simple MVP implementation.
5. Do not introduce complex architecture unless needed.

After editing:
1. List changed files.
2. Explain assumptions made.
3. Mention any commands to run.
4. Mention any remaining manual setup only if required.