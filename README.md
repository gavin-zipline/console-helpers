# Console Helpers

## Overview

Rails console helper functions for Zipline application debugging and investigation.

**Architecture**: Flat structure required for GitHub repo deployment.

## Usage

### Local Development

1. Develop and test helpers locally
2. Use `helper_workflow.rb` to manage deployment
3. Deploy to GitHub repo for remote console access

### Remote Console Access

```ruby
# In Rails console (hrc)
gh("helper_name")  # Loads helper from GitHub repo
```

## Helper Standards & Registration System

- File naming: `*_helper.rb`
- Version constant: `HELPER_NAME_VERSION = "x.x.x"`
- Cheatsheet method: `helper_name_cheatsheet`
- Standard header with description
- Each helper must:
  - Begin with `disable_return_printing`
  - Register itself unconditionally via `ConsoleHelpers.register_helper("name", HELPER_VERSION, method(:cheatsheet))` after defining its cheatsheet method
  - End with `enable_return_printing` and a call to its cheatsheet method

### Registration System

- All helpers register themselves in a global registry using `ConsoleHelpers.register_helper`.
- Registration is unconditional (no `if`/`unless` blocks).
- The registry tracks helper name, version, and a cheatsheet proc.
- The global `helpers` method lists all registered helpers and their versions.
- The global `cheatsheets` method displays all registered cheatsheets.

### Cheatsheet Conventions

- Each helper defines a `cheatsheet` method that outputs usage info.
- The cheatsheet is registered as a proc and callable via the registry.
- The global `cheatsheets` method displays all cheatsheets for discoverability.

### Dynamic Loading

- Helpers can be loaded dynamically via the `gh` alias, which fetches and evals remote helper files.

### Spec Compliance

- Registration must occur after the cheatsheet method is defined.
- No conditional registration.
- All helpers must follow the above conventions for consistency and discoverability.

## Workflow

```
Local Development → GitHub repo → Remote Rails Console
```

## Files

- `*_helper.rb` - Individual helper files
- `HELPER_TEMPLATE_*.rb` - Templates for new helpers
  -- `deploy_to_repo.sh` - Deployment script
- `helper_workflow.rb` - Management tool (links to main project)

---

_Part of the Zipline Customer Support toolchain_
