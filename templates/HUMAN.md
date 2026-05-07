---
description: Default async scratchpad for human-agent conversations
---
# HUMAN

> [!info]- How this works
> Async scratchpad for human-agent conversations.
>
> **Thread lifecycle:**
> - `[!warning]- 👈` — needs human's attention
> - `[!todo]-` — ready for agent action, filing, or implementation
> - `[!question]-` — still being shaped; discussion or decision needed
> - `[!note]-` — regular active thread
> - `[!info]-` — pinned instructions, reference, or status only
> - `[!abstract]-` — parked thought / someday-maybe
> - `[!success]-` — resolved
>
> **Messages:** Start with `**[Name]**`, separated by `> ---` dividers.
>
> **Arrow notation:** `**[Or → agent]**` means Or's words, rewritten by agent.
>
> **Management:** `threads fmt` to format and sort. `threads ls` to list. `threads archive` to move resolved threads out.
>
> **Updating:** If this template changes, diff your file against `threads template HUMAN` and merge what you need. The template is small — manual merge is straightforward.
