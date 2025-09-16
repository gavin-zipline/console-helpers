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
- **Convention:**
  1. Declare version constant at the top (e.g. `USER_HELPER_VERSION = "1.4.1"`)
  2. Define the cheatsheet method (e.g. `def user_helper_cheatsheet ... end`)
  3. Register the helper immediately after (e.g. `ConsoleHelpers.register_helper("user", USER_HELPER_VERSION, method(:user_helper_cheatsheet))`)
  4. Then define all other methods and logic
  5. End with a call to the cheatsheet method for auto-display
- Standard header with description
- Registration is unconditional (no `if`/`unless` blocks)
- All helpers register themselves in a global registry using `ConsoleHelpers.register_helper`
- The registry tracks helper name, version, and a cheatsheet proc
- The global `helpers` method lists all registered helpers and their versions
- The global `cheatsheets` method displays all registered cheatsheets

### Cheatsheet Conventions

- Each helper defines a `*_cheatsheet` method that outputs usage info
- The cheatsheet is registered as a proc and callable via the registry
- The global `cheatsheets` method displays all cheatsheets for discoverability

### Dynamic Loading

- Helpers can be loaded dynamically via the `gh` alias, which fetches and evals remote helper files

### Spec Compliance

- Registration must occur after the cheatsheet method is defined
- No conditional registration
- All helpers must follow the above conventions for consistency and discoverability

### Example Helper Structure

```ruby
USER_HELPER_VERSION = "1.4.1"
def user_helper_cheatsheet
  # ...
end
ConsoleHelpers.register_helper("user", USER_HELPER_VERSION, method(:user_helper_cheatsheet))
# ...rest of helper code...
user_helper_cheatsheet
```

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
