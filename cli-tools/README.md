# CLI Tools for Cline/Claude Code

Custom CLI tools that extend Cline's capabilities without requiring MCP servers.

## Slack Search Tool

Search your Slack workspace directly from the command line or via Cline.

### Setup

1. **Create a Slack User Token** (no admin approval needed):
   - Go to https://api.slack.com/apps
   - Click "Create New App" → "From scratch"
   - Name: "Personal Slack Search" (or whatever you want)
   - Select your workspace
   - Navigate to "OAuth & Permissions"
   - Under **"User Token Scopes"** (NOT Bot Token Scopes!), add:
     - `channels:history`
     - `channels:read`
     - `search:read`
     - `users:read`
   - Click "Install to Workspace" (uses YOUR permissions, no admin needed)
   - Copy the **User OAuth Token** (starts with `xoxp-`)

2. **Set the environment variable**:
   ```bash
   export SLACK_USER_TOKEN="xoxp-your-token-here"
   ```

3. **Make it permanent** by adding to your `~/.zshrc`:
   ```bash
   echo 'export SLACK_USER_TOKEN="xoxp-your-token-here"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. **Add to PATH** (optional, for easy access):
   ```bash
   # Add this to ~/.zshrc
   export PATH="$PATH:/Users/gavinmeans/work-local/console-helpers/cli-tools"

   # Then create symlink
   ln -s /Users/gavinmeans/work-local/console-helpers/cli-tools/slack-search.js /Users/gavinmeans/work-local/console-helpers/cli-tools/slack-search
   ```

### Usage

**From command line:**
```bash
./slack-search.js "your search query"
./slack-search.js "MCP servers" --limit 10
./slack-search.js "in:#d-developers-ai console helpers"
```

**From Cline:**
Just ask:
- "Search Slack for discussions about console helpers"
- "Find Slack messages about MCP configuration"
- "Look up what the team said about user_helper performance"

Cline will automatically use this tool via the Bash command.

### Search Syntax

Slack's search supports advanced queries:
- `in:#channel-name search terms` - Search in specific channel
- `from:@username search terms` - Search messages from user
- `after:2026-01-01 search terms` - Date filters
- `"exact phrase"` - Exact phrase match

**Examples:**
```bash
./slack-search.js "in:#d-developers-ai MCP"
./slack-search.js "from:philippe console helpers"
./slack-search.js "after:2026-01-01 Cline configuration"
```

### How It Works

- Uses Slack's **User Token** (your own permissions, no bot needed)
- No admin approval required (you're just using your own Slack access)
- Returns formatted results with links to original messages
- Cline can call it like any other CLI tool

### Security Notes

- User token gives access to everything YOU can see in Slack
- Store token securely (environment variable, never commit to git)
- Add `SLACK_USER_TOKEN` to your `.gitignore` and `.env` files
- Treat it like a password

### Troubleshooting

**Error: SLACK_USER_TOKEN not set**
- Make sure you've exported the environment variable
- Restart your terminal or run `source ~/.zshrc`

**Error: unauthorized**
- Check that your token is valid
- Verify scopes are correct in Slack app settings

**No results found**
- Try broader search terms
- Check if you have access to the channels being searched
- Use Slack's search syntax (see examples above)
