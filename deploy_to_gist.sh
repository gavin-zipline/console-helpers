#!/bin/bash
# Deploy console helpers to GitHub Gist

COMMIT_MESSAGE="${1:-Update helpers - $(date '+%Y-%m-%d %H:%M')}"

echo "🚀 Deploying console helpers to Gist..."

# Add all helper files
git add *.rb *.md

# Commit changes
if git commit -m "$COMMIT_MESSAGE"; then
  echo "✅ Committed changes: $COMMIT_MESSAGE"
else
  echo "ℹ️ No changes to commit"
fi

# Push to Gist (assuming Gist is set as origin)
echo "🌐 Pushing to Gist..."
if git push origin master; then
  echo "✅ Successfully deployed to Gist!"
  echo "🎯 Helpers now available in remote Rails console via gh(\"helper_name\")"
else
  echo "❌ Deploy failed - check git remote and credentials"
  echo "💡 Set up Gist as origin: git remote add origin https://gist.github.com/YOUR_GIST_ID.git"
fi
