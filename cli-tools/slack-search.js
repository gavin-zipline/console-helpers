#!/usr/bin/env node

/**
 * Slack Search CLI Tool
 * Search Slack workspace using user token (no admin approval needed)
 *
 * Usage:
 *   slack-search "your search query"
 *   slack-search "MCP servers" --channel d-developers-ai
 *   slack-search "console helpers" --limit 10
 */

const https = require('https');

// Configuration
const SLACK_TOKEN = process.env.SLACK_USER_TOKEN;
const DEFAULT_LIMIT = 5;

function makeSlackRequest(endpoint, params) {
  return new Promise((resolve, reject) => {
    const queryString = new URLSearchParams(params).toString();
    const url = `https://slack.com/api/${endpoint}?${queryString}`;

    const options = {
      headers: {
        'Authorization': `Bearer ${SLACK_TOKEN}`,
        'Content-Type': 'application/json'
      }
    };

    https.get(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          if (!json.ok) {
            reject(new Error(`Slack API error: ${json.error}`));
          } else {
            resolve(json);
          }
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function searchMessages(query, options = {}) {
  const params = {
    query: query,
    count: options.limit || DEFAULT_LIMIT,
    sort: 'timestamp',
    sort_dir: 'desc'
  };

  return await makeSlackRequest('search.messages', params);
}

function formatResults(response) {
  if (!response.messages || !response.messages.matches || response.messages.matches.length === 0) {
    return 'No results found.';
  }

  const matches = response.messages.matches;
  let output = `Found ${response.messages.total} results (showing ${matches.length}):\n\n`;

  matches.forEach((match, i) => {
    const date = new Date(parseFloat(match.ts) * 1000).toISOString().split('T')[0];
    const channel = match.channel?.name || 'DM';
    const user = match.username || 'Unknown';
    const text = match.text.replace(/\n/g, ' ').substring(0, 200);
    const permalink = match.permalink;

    output += `[${i + 1}] ${date} - #${channel} - @${user}\n`;
    output += `    ${text}\n`;
    output += `    ${permalink}\n\n`;
  });

  return output;
}

async function main() {
  const args = process.argv.slice(2);

  if (!SLACK_TOKEN) {
    console.error('Error: SLACK_USER_TOKEN environment variable not set');
    console.error('\nTo set it up:');
    console.error('1. Create a Slack app at https://api.slack.com/apps');
    console.error('2. Add User Token Scopes: channels:history, channels:read, search:read, users:read');
    console.error('3. Install to workspace and copy User OAuth Token (xoxp-...)');
    console.error('4. Set environment variable: export SLACK_USER_TOKEN="xoxp-..."');
    console.error('5. Add to ~/.zshrc or ~/.bashrc to persist');
    process.exit(1);
  }

  if (args.length === 0 || args[0] === '--help' || args[0] === '-h') {
    console.log('Usage: slack-search <query> [options]');
    console.log('\nOptions:');
    console.log('  --limit N    Number of results (default: 5)');
    console.log('  --help       Show this help');
    console.log('\nExamples:');
    console.log('  slack-search "MCP servers"');
    console.log('  slack-search "console helpers" --limit 10');
    console.log('  slack-search "in:#d-developers-ai Claude Code"');
    process.exit(0);
  }

  let query = args[0];
  let limit = DEFAULT_LIMIT;

  // Parse options
  for (let i = 1; i < args.length; i++) {
    if (args[i] === '--limit' && args[i + 1]) {
      limit = parseInt(args[i + 1]);
      i++;
    }
  }

  try {
    console.error('Searching Slack...\n');
    const results = await searchMessages(query, { limit });
    console.log(formatResults(results));
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}

main();
