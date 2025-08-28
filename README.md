# Console Helpers

## Overview
Rails console helper functions for Zipline application debugging and investigation. 

**Architecture**: Flat structure required for GitHub Gist deployment.

## Usage

### Local Development
1. Develop and test helpers locally
2. Use `helper_workflow.rb` to manage deployment
3. Deploy to Gist for remote console access

### Remote Console Access
```ruby
# In Rails console (hrc)
gh("helper_name")  # Loads helper from Gist
```

## Helper Standards
- File naming: `*_helper.rb`
- Version constant: `HELPER_NAME_VERSION = "x.x.x"`
- Cheatsheet method: `helper_name_cheatsheet`
- Standard header with description

## Workflow
```
Local Development → Gist → Remote Rails Console
```

## Files
- `*_helper.rb` - Individual helper files
- `HELPER_TEMPLATE_*.rb` - Templates for new helpers
- `deploy_to_gist.sh` - Deployment script
- `helper_workflow.rb` - Management tool (links to main project)

---
*Part of the Zipline Customer Support toolchain*
