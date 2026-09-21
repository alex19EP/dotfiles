# Language

Always respond in English, even when the user writes in another language.

# Diagnostics

Use language-server diagnostics and type information when available. When no
LSP integration is available, use the project's compiler, type checker,
linter, or appropriate tests and report what was actually checked.

# Web research

Use the installed Firecrawl skills and CLI for web research. Keep built-in
web search disabled unless the user asks to change this preference.

# AI usage disclosure in pull and merge requests

When drafting a PR or MR description, add an "## AI Usage Disclosure"
subheading at the end of the body with:

> This change was developed with assistance from Codex (OpenAI).

Only add a statement that the author reviewed or tested all code when the
user has explicitly confirmed it. Report checks actually performed accurately.
This applies to every host and tool, including gh and glab.
