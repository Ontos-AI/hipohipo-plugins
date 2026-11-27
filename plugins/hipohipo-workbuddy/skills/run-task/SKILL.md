---
name: run-task
description: Carry out a Hipo background task. Use when the first message says this is a Hipo background task and gives a nodeId and runId.
---

This session was started by Hipo to do one task in a chain another session dispatched. No one is watching it.

1. Call `task.read` with the `nodeId` and `runId` from the first message. It returns the brief (goal, context, what is done, open questions, relevant paths, acceptance criteria), the working directory, the dispatching session's `handoffId`, and summaries of the tasks this one waited for.
2. Work from the brief and the upstream summaries. Open the dispatching session with `handoff.read` only when they are not enough.
3. Stay within the brief's goal and acceptance criteria. Do not start other work, dispatch new tasks, or wait for answers.
4. When done, call `task.complete` once with the same ids and a summary of what you produced and where: files, branch, commit. Later tasks read this summary.
5. If you cannot finish, call `task.fail` with the same ids and the reason a person needs to act on. Nothing reruns automatically.
