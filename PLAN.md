# PLAN.md

## Purpose

Use this file when planning a new app repository. The goal is to create a small, consistent repo that follows the same conventions across projects without making unnecessary assumptions.

Stay in planning mode until the user approves the proposed plan. Do not initialize, scaffold, commit, or push during planning mode.

## 1. Ask the setup questions

Ask these questions together in one message. Clearly show defaults.

1. **What is the app idea?**  
   No default. Ask for a short description of:
   - the intended user;
   - the main problem or task;
   - the primary user flow.

2. **Any preferred tech stack?**  
   Default: **Electrobun + React + Vite + shadcn/ui**.

3. **Should this repo use a special Git identity?**  
   No default. Require one of these explicit answers:
   - provide the Git username/display name and no-reply email; or
   - explicitly say to use the existing Git identity.

   Do not create commits until this is answered.

4. **Do we want GitHub Actions build automation?**  
   Default: **No**.

5. **Are there previous repos this one should follow?**  
   Optional, with no default. Ask for local paths or repository URLs when available.

6. **What license should the repository use?**  
   Default: **The Unlicense**. Use the user's requested license when specified. Otherwise, add the standard Unlicense text in the repository's license file.

7. **Any machine-specific tools required?**  
   Default: **No**. If yes, document only portable environment variable names and setup notes. Do not commit personal paths.

Suggested intake message:

> Before I plan the repo:
>
> 1. App idea — what should it do, who is it for, and what is the main user flow?
> 2. Tech stack — use Electrobun + React + Vite + shadcn/ui, or something else?
> 3. Git identity — provide the Git username/display name and no-reply email, or explicitly say to use the existing identity.
> 4. GitHub Actions — add build automation? Default: no.
> 5. Reference repos — any existing repos whose structure or conventions should be followed?
> 6. License — use The Unlicense, or another license? Default: The Unlicense.
> 7. Machine-specific tools — any required local tools, SDKs, emulators, or services? Default: none; use portable env vars only.

## 2. Inspect before proposing changes

When an existing directory or repo is available:

- inspect the current files, scripts, package manager, runtime versions, and Git status;
- read `AGENTS.md` and `AGENTS_LOCAL.md` when present;
- preserve established conventions unless the user requests a change;
- do not overwrite working configuration without identifying the impact;
- use reference repos to infer conventions, but list every inferred convention in the plan.

## 3. Produce the implementation plan

The plan should contain:

- app summary;
- MVP features;
- explicit non-goals;
- selected stack and package manager;
- proposed repository structure;
- main processes or architecture;
- development, test, build, and packaging commands;
- VS Code launch configurations;
- Git identity decision;
- GitHub Actions decision;
- license decision;
- files to create or modify;
- open questions and risks;
- a short completion checklist.

Keep the first version small. Prefer a working vertical slice over a broad scaffold.

## 4. Standard repository baseline

Unless the repo already has an equivalent convention, plan for:

- a deliberately slim `README.md` covering only essential setup, run, debug, test, build, and packaging commands;
- a deliberately slim `CONTRIBUTING.md` using the default template in this plan, unless the user requests otherwise;
- `AGENTS.md` with shared agent instructions;
- optional `AGENTS_LOCAL.md` for machine-specific and local-development instructions;
- `.gitignore` entries for `AGENTS_LOCAL.md`, local environment files, generated output, and platform-specific artifacts;
- committed `.vscode/launch.json` only; do not add `.vscode/tasks.json` unless a launch configuration cannot reasonably work without it and the user explicitly approves the exception;
- one lockfile and an explicitly selected package manager;
- pinned or documented runtime/tool versions;
- scripts for `dev`, `build`, `test`, `typecheck`, `lint`, and `format` when supported;
- a minimal smoke test for the primary app flow;
- `.env.example` when environment variables are needed, without secret values;
- checked-in wrapper scripts for machine-dependent tools when direct launch commands would otherwise require personal paths;
- a repository license file using **The Unlicense** by default, unless the user selects another license.

Do not add `.github/workflows/` unless GitHub Actions was explicitly approved.

## 5. Portable environment policy

All committed workflow, editor, build, launch, and test configuration must work across machines without personal paths or maintainer-specific assumptions.

Do not commit:

- absolute home-directory paths such as `<posix-home>/...` or `<windows-user-home>\...`;
- paths to locally installed apps, SDKs, emulators, package managers, or toolchains;
- machine-specific ports unless they are documented defaults and overrideable;
- shell-specific startup assumptions such as aliases, private functions, or local dotfiles;
- personal Git identity, private emails, tokens, keys, or copied terminal transcripts.

Prefer:

- repository-relative paths;
- standard commands on `PATH`;
- environment variables with documented names;
- checked-in wrapper scripts that discover tools portably;
- `.env.example` for variable names only;
- ignored `.env`, `.env.local`, `AGENTS_LOCAL.md`, and editor-local override files.

If a tool path may differ by machine, commit a wrapper script such as `tools/run-thing.sh` that:

1. accepts an explicit environment variable override, for example `MGBA_BIN`;
2. searches common executable names on `PATH`;
3. optionally checks common package-manager launchers;
4. prints actionable setup help when not found.

Treat portability cleanup as a release blocker. If committed setup only works on one maintainer's machine, replace it with a wrapper, an environment variable, or documentation before publishing.

## 6. VS Code launch configuration

The user should be able to launch and debug the app from VS Code without manually reconstructing commands.

Create only the configurations that are useful for the selected stack. Typical configurations include:

- **App: Dev** — starts the complete application;
- **Renderer: Dev** — starts only the web renderer when useful;
- **Tests** — runs or debugs targeted tests;
- **Build/Package** — runs the production build or packaging command only when explicitly requested or approved;
- a compound launch configuration when multiple processes must start together.

Prefer direct launch configurations, runtime executables, and compound launches. Do not use `preLaunchTask` or `.vscode/tasks.json` by default. If a setup step cannot be represented cleanly in `launch.json`, document the command in `README.md` rather than introducing tasks. Keep launch names stable across repos where possible.

Committed VS Code configuration must not contain personal paths. Use `${workspaceFolder}`, `${env:VAR_NAME}`, or repository scripts. If a launch configuration needs a tool that may live in different places, call a checked-in wrapper script and let that script read an environment variable override.

## 7. `AGENTS.md` and `AGENTS_LOCAL.md`

Add the following local-instructions policy, or equivalent wording, to `AGENTS.md`:

> Local-only agent and development instructions belong in `AGENTS_LOCAL.md`.  
> Read `AGENTS_LOCAL.md` after this file when it exists. It must remain gitignored and must not be committed.  
> When it is absent, continue normally and inform the user once that they may create it for machine-specific paths, ports, launch notes, and repo-local Git identity.  
> Never store passwords, access tokens, private keys, or other secrets in either agent file.

Add this entry to `.gitignore`:

```gitignore
AGENTS_LOCAL.md
```

A useful local template is:

```markdown
# AGENTS_LOCAL.md

## Repo-local Git identity

- Git user name:
- Git no-reply email:

## Local development

- Machine-specific paths:
- Ports:
- Environment file location:
- Launch or debugging notes:
- Other local-only instructions:
```

Treat the Git name and no-reply email as identity configuration, not secret credentials. Store actual secrets in an ignored environment file, operating-system credential store, or approved secret manager.

When a special Git identity is provided:

1. record it in `AGENTS_LOCAL.md`;
2. apply it to the repository with repo-local Git configuration;
3. verify the effective values before the first commit.

Example commands:

```bash
git config --local user.name "<name>"
git config --local user.email "<no-reply-email>"
git config --local --get user.name
git config --local --get user.email
```

## 8. Default agent instructions

Add these instructions to `AGENTS.md`, adapting names only where needed for the repository:

### Documentation and text files

- Keep `README.md` and `CONTRIBUTING.md` intentionally slim. Do not expand them with process-heavy guidance unless the user explicitly asks.
- Finalize edited text files with CRLF line endings, unless an existing repository policy explicitly requires another format.

### Privacy, logging, and network behavior

- Do not add telemetry, automatic diagnostic uploads, secret logging, prompt or transcript logging, raw path logging, command-output logging, or unapproved network calls.
- Do not commit PII, personal identity details, corporate identity details, local machine paths, private email addresses, tokens, keys, certificates, credentials, private configuration, copied chat transcripts, or anything that only makes sense on one maintainer's machine.
- Treat privacy cleanup as a release blocker. If sensitive or personal material appears, remove it from the current tree and coordinate a history rewrite before publishing.

### Portable workflows and local tools

- Keep committed launch, task, workflow, and setup files universal. Use repository-relative paths, environment variables, or wrapper scripts instead of personal paths.
- Put maintainer-specific paths, ports, emulator locations, SDK locations, and shell notes in ignored local files such as `AGENTS_LOCAL.md` or `.env.local`.
- When a local executable may be installed differently across machines, provide a checked-in wrapper script that accepts an environment variable override, checks `PATH`, and fails with clear setup instructions.

### Validation and potentially destructive operations

- Default to quick, targeted validation.
- Do not run history rewrites, reflog expiration, garbage collection, packaging, end-to-end suites, or full test suites unless the user explicitly asks or approves them for the current task.
- Before starting a potentially long or destructive command, state its purpose and scope, use a bounded timeout where practical, and provide periodic progress updates during long-running work.

### Managed agent runtime update policy

Include these rules only when the repository bundles or manages an agent runtime:

- Do not introduce in-app agent runtime update checking or installation. Runtime updates are handled outside the app by publishers or package managers.
- Keep managed agent runtime updates disabled until a signed-manifest update design is deliberately specified and implemented.

## 9. Default `CONTRIBUTING.md`

Create a slim `CONTRIBUTING.md` by default, using this text unless the repository already has an equivalent file or the user requests different guidance:

````markdown
# Contributing

Use common sense, be nice, and keep changes easy to understand.

## The Basics

- Be friendly.
- One clear change is easier to review than five tangled ones.
- Do not submit code, assets, or text you do not have the right to share.
- Do not add telemetry, surprise network calls, secrets, generated bundles, diagnostics, local config, or prepared agent runtime binaries to the repo.
- Match the style of nearby code. If something looks inconsistent, ask or keep it boring.

There is no CLA, copyright assignment, or DCO sign-off.

AI-assisted work is fine, but **you are responsible for what you submit**.

## Maybe Do This Before Opening a Pull Request

Run the checks that make sense for what you touched. For normal code changes, run:

```text
npm run typecheck
npm test
```

Run `npm run test:e2e` for startup, Electrobun or Electron integration, preload, runtime, packaging, or end-to-end workflow changes.
````

Keep this file intentionally short. Adapt command names only when the selected package manager or repository scripts differ. Remove references to agent runtime binaries, preload, Electron, or packaging when they do not apply to the repository.

## 10. GitHub Actions

Default to no workflow files.

When explicitly enabled, propose the smallest useful workflow:

- install the pinned runtime and package manager;
- install dependencies from the lockfile;
- run type checking, linting, targeted tests, and build;
- package or upload artifacts only when requested;
- avoid publishing, releases, signing, or deployment unless separately approved.

## 11. Portability scan

Before committing setup, workflow, editor, or launch files, scan for personal paths and secrets:

```bash
git grep -nE '(/(home|Users)/[^/]+|C:\\(Users)\\|github[_]pat_|gh[pousr]_|s[k]-|B[E]GIN (RSA|OPENSSH|PRIVATE) KEY)' -- .
```

Treat any match in tracked files as a blocker unless it is harmless documentation using placeholders.

## 12. Completion criteria

The repo setup is complete when:

- the approved app plan is implemented;
- the app can be launched from VS Code without VS Code tasks;
- committed launch, task, workflow, and setup files use repository-relative paths, environment variables, or wrapper scripts;
- essential setup and common commands are documented without process-heavy expansion;
- repo-local Git identity matches the user's decision;
- `AGENTS_LOCAL.md` is ignored and documented;
- edited text files follow the selected CRLF policy;
- no secrets, PII, private paths, personal absolute paths, transcripts, or machine-specific configuration are committed;
- machine-specific setup is documented through ignored local files or environment variables only;
- wrapper scripts fail with clear setup instructions instead of assuming the maintainer's machine;
- no telemetry, surprise logging, or unapproved network behavior was introduced;
- quick, targeted validation passes where applicable;
- `CONTRIBUTING.md` remains slim and uses commands that exist in the repository;
- the selected license is present, with The Unlicense used by default;
- GitHub Actions are absent unless explicitly approved;
- the first usable app flow works end to end.
