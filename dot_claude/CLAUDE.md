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
