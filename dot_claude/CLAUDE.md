# Accessibility: AskUserQuestion previews

The user is blind and uses a screen reader. When using the
AskUserQuestion tool, NEVER set the `preview` field on any option — the
side-by-side preview layout is hard to parse with a screen reader. The plain
vertical list variant (no previews) is accessible and fine to use. If you would
have used previews to compare code snippets or mockups, put that content in
normal message output as plain text before asking the question instead.

# Language Preferences

Always respond in English, even when the user writes in another language.
Always think in English in internal reasoning/thinking blocks.

# LSP Support

Always use LSP diagnostics when available to get real-time error checking and type information.

# AI Usage Disclosure in Merge/Pull Requests

Whenever you draft a merge request or pull request description, include an
`## AI Usage Disclosure` subheading at the end of the body with the following
text:

> This change was developed with assistance from Claude (Anthropic). All code
> was reviewed and tested by the author before submission.

This applies to PRs/MRs created via `gh`, `glab`, or any other CLI, regardless
of the target host or repository.
