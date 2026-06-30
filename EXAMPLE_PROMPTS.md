# Example Prompts

## Codebase chat (RAG)

These are answered using retrieval over your source files and generated docs:

- Explain the authentication flow.
- How does database initialization work?
- Which file handles JWT validation?
- Where are the API routes defined?
- What design patterns are used in the service layer?
- How is state managed across the app?
- What environment variables does the project require?
- Walk me through what happens when a request hits the `/login` endpoint.
- Which modules depend on the database layer?
- How would I add a new API endpoint?

## Per-agent generation prompts (built automatically)

The orchestrator builds each agent's prompt from a shared context block plus the
files most relevant to that document. The shape is:

```
[System] You are the <ROLE>. Produce <DOCUMENT> in GitHub-flavored Markdown.
         Follow the required sections exactly. Use ONLY the provided context;
         do not invent endpoints, files, or facts.

[User]   PROJECT CONTEXT
         name, language, framework, database, architecture, modules,
         technologies, folder structure, summary

         RELEVANT FILES
         <path>:
         <excerpt>
         …

         TASK
         Write <DOCUMENT> including: <required sections>.
```

### README Agent
Sections: Description, Features, Technologies, Installation, Build, Run,
Environment Variables, Screenshots placeholder, Roadmap, Contributing, License.

### API Documentation Agent
Sections: Endpoints, Request examples, Response examples, Authentication,
Error handling.

### Architecture Agent
Sections: Layers, Data flow, Module relationships, Design patterns,
Dependency overview.

### Installation Agent
Sections: Prerequisites, Setup, Environment variables, Docker instructions,
Build instructions.

### Contributing Agent
Sections: Branch strategy, Commit convention, Pull request process,
Code standards.

### Changelog Agent
Sources: git history (if present), project structure, existing release notes.
