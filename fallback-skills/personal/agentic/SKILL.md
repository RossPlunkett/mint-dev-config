---
name: agentic
description: The office's /agentic workflow, and the extended agentic workflow, for splitting work into slices run by implementer and reviewer subagents. Only for the orchestrating agent (the one given the work), never for a subagent.
---

# /agentic: how work gets done here

Work is done in slices, one handoff file each. If you were given work (a card, or a task typed at your desk), you're its orchestrator: you plan, start the subagents that do the slices, relay what changes, check the whole and file its receipts. Start subagents with Pi's subagent tool, in the background (async), so you hear when each one finishes.

## Slices
- A slice is a piece of the work one implementer can finish and commit by itself, described in a handoff file in the repository (temporary-handoffs/<topic>/<nn>-<slice>.md, say).
- Use the handoffs you were given (your card's Handoffs). Split any slice that's too big, and write the handoffs you need yourself: commit them on your branch and list them on your card with office-tasks edit <card> --handoff <path>, once per file (it replaces the list, so give them all).
- Even a small piece of work is one slice, and it's reviewed, unless the card says no review.

## The pipeline
Overlap is the default, including when consecutive slices share files. Only the person's explicit request for extended (one-agent-at-a-time) execution changes this. Card, dispatch and handoff wording such as "through review", "including reviews" or "overrides the sequential default" does not select extended execution. A request for additional parallel pipelines widens concurrency while preserving reviewer/implementer overlap within each pipeline.

The card's "Models for this card (Pi subagent model:effort):" block names the model and effort for its orchestrator, implementers, slice reviewers and final reviewer; pass each explicit choice as the subagent's model argument, in model:effort form. For a role marked harness default, omit both model and effort overrides so the actual agent harness chooses; never pass harness-default as a model ID. Work without a card (a task typed at a desk) uses the TODO defaults from office-tasks models. All model choices come from the user data repository's policy/office.json, read through office-tasks models (or --json), including all four card roles for TODO, BUGS and LINGERING, the station and other policy roles, naming, setup, and their fallbacks; never choose a model from this workflow text. When a subagent fails on a provider error (usage limit, rate limit, auth, outage), relaunch it on its role's fallback; don't retry it on the same model. The person may override any of these models or efforts mid-session: follow the override and record it on the card with office-tasks edit <card> --implementer|--slice-reviewer|--final-reviewer|--orchestrator model:effort (choose the flag for the role); without a card, follow it for this task.

- Implementers: use the card's implementer model, one at a time, in slice order. Each does its slice, commits only the files it changed, and reports what it did and anything left over. When implementer N finishes, start implementer N+1 and, at the same moment, the reviewer for slice N.
- Reviewers: use the card's slice reviewer model. They run alongside the implementers, and several may be running at once. A reviewer checks its slice against its handoff, fixes the bugs it finds, commits only the files it fixed (git commit -- <paths>), and reports each fix: file:line, what changed and why.
- Everyone works in your checkout, on your branch. Each commits only its own paths; nobody resets, stashes, rebases or switches branches.
- Final review: when the last slice's reviewer has finished, start one reviewer using the card's final reviewer model over the whole scope of the work: the full diff against the card and every handoff, for wholeness (missing pieces, seams between slices, loose ends, docs). It fixes and reports like the slice reviewers, and also makes candidate receipts: screenshots of the result, each showing something different (playwright-cli … screenshot for web work), and a results summary (what it verified and how, test output), reporting their paths.
- Then you, and only you, run the typecheck and the full test suite and fix or delegate what fails. Pick and write the receipts from the final reviewer's candidates and your own results, file them with office-tasks receipt (your card rules give the limits), and finish: office-tasks done on a card.

## Reservations and shared files
Path reservations separate implementers, not reviewers from implementers. Start reviewer N and implementer N+1 together, even when their slices name the same paths. Reviewers fix files while implementers work on them: this overlap deliberately accepts some edit contention for speed. Relay reviewer fixes to running implementers and have them reread the changed files; resolve collisions as they arise rather than requiring path ownership or waiting for review completion.

Before waiting for reviewer N to finish, check: did the person request extended execution? If not, start implementer N+1. Report any genuine dependency that leaves it no work to do; a shared path alone is not such a dependency.

## Extended: one agent at a time
When the person asks for the extended agentic workflow (it spreads the work out, to stay under rate limits), nothing overlaps: implement slice 1, review slice 1, implement slice 2, review slice 2, and so on, then the final review, with only one subagent running at any moment. The models, the slices, the reviews and the final review are as above; each reviewer's fixes go into the next implementer's task instead of being steered into a running one.

## Worktrees: one per card, deleted when done
- The card's orchestrator makes one worktree and branch for the whole card, once, when it starts. Slices, implementers, reviewers and the final reviewer all work in that one checkout, on that one branch. No subagent makes a worktree, not one per slice, not one per reviewer, and none for a sweep or a build.
- Make a second worktree only when the card names it, and record it on the card. It's deleted when the run that needed it ends.
- Done means gone. When the card's work is merged into its target, or the work is discarded with a BUG card filed, the orchestrator removes the worktree and its branch before it finishes the card. A worktree whose card is finished is never left behind, and never kept just in case.
- Remove only what's committed. Before deleting, check the worktree is clean and every commit is merged or filed. If it isn't, stop and report to the person; don't force it.
- Build output (build-*, asan, tsan, instrumented, node_modules a review copied) doesn't outlive the review that made it. Delete it with the review; a rebuild is cheap, a full disk stops every worker.
- Subagents report what they built and where. They don't delete worktrees, and the orchestrator doesn't wait on them to.

## Roles in every message
Each subagent knows only what you tell it. Open every task with "You are <role> for <the work>; I am the orchestrator, who <what you do with its report>", and keep both roles in every steer and reply. Every report and question back to you opens with "I'm <role>; you're the orchestrator, who <…>".

## Relaying
- When a reviewer reports fixes: tell every implementer still running what shifted under it (steer it with a short message: the files, what changed, what that means for its slice); bring every handoff the fixes made stale up to date and commit it; and carry the fixes into the tasks of the subagents you haven't started yet.
- Reviewers report when they finish; mid-run only when a fix changes something a running implementer depends on.
- File the bugs and lingering items subagents report as BUGS / LINGERING cards (office-tasks add --kind bug / --kind lingering), without asking the person.

## Questions
- Subagents ask you, not the person: through contact_supervisor. See what's waiting with subagent_supervisor (action pending) and answer with subagent_supervisor (action reply, replyTo the request's id). Answer every request, even if only to say to go ahead.
- Answer what you can from the handoffs, the card and the code. Never guess at what the person would decide.
- Keep the rest in one queue, oldest first. Put what only the person can decide to them with office-tasks ask --person "…": one question at a time, standing on its own (the work, the slice, where it's got to, the choice and its options, your recommendation). A red lamp lights at your desk until they answer; the answer comes to your terminal as their next message. Relay it to the subagent that asked, in their words, then ask the next one.
- While a question is open, keep the pipeline going wherever it doesn't depend on the answer. A subagent waiting on an answer is working, not stalled.

## Stalled subagents
- When a subagent has gone quiet for a long while with no question open, check it: subagent (action status, view transcript). Nudge it with subagent (action steer) and a short message; if it's stuck, interrupt it and confirm with status that it has stopped before starting a new one. Tell the replacement what the old one had done.
- A subagent that failed because the model provider aborted or the stream broke hasn't failed its task: resume it (subagent action resume) rather than starting a second one on the same files.

## Every subagent's task
Subagents know only what their task says. Give each:
- its role and yours, first (Roles in every message), and that its report and questions open with both;
- the repository folder to work in, and that the repository's own instructions (AGENTS.md, CLAUDE.md) apply;
- every handoff on the card, and its own slice's handoff;
- the overlap and reviewer-fix relay rules above;
- the reported fixes from earlier slices that touch its slice;
- for reviewers: the card's review prompt (under "For your reviewers"), and to fix what they find, commit only their own paths and report each fix;
- for the final reviewer: to make candidate receipts (screenshots, a results summary) and report their paths, never filing them itself;
- to ask you through contact_supervisor what its handoff and the code don't settle, keep working on whatever doesn't depend on the answer, and never guess a decision;
- to report the bugs and lingering items (little things left undone) it finds to you, saying they should be filed as BUGS / LINGERING cards, and never to file cards itself.

If you can't start Pi subagents, do the slices yourself, in order, and review each one before the next.
If you look after the TODO or BUGS board, you don't run this pipeline: you set it up. Split the work into slices where you can, write a handoff for each, push them, and list them on the card. Describe dependencies as implementer order and additional parallel pipelines as additive to the normal reviewer/implementer overlap. Reserve paths between implementers only; reviewer fixes overlap the next implementer's work, including on shared files. Record extended execution only when the person explicitly requested it; otherwise keep this pipeline in the cards, dispatches and handoffs you write.
