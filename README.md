# Chissue

Ever discussed a task or issue in the group chat and then had to manually create an issue on GitHub?
Now you can just tag the Chissue bot; it will read through the conversation and create an issue using AI.

> The conversations are stored within memory, never saved anywhere, and not shared with AI providers unless you explicitly tag the bot. You can also use local or self-deployed AI models by specifying custom base URLs to ensure privacy.

## Environment Variables

Required:

- `TELEGRAM_BOT_TOKEN` - Telegram bot token
- `TELEGRAM_BOT_USERNAME` - Telegram bot username (e.g. `chissuebot`)
- `GITHUB_TOKEN` - GitHub token
- `GITHUB_REPOSITORY` - GitHub repository (e.g. `breitburg/chissue`)
- `OPENAI_API_KEY` - OpenAI API key
- `OPENAI_MODEL` - OpenAI model with support for schema-based output (e.g. `gpt-4o-mini`)

Optional:

- `OPENAI_BASE_URL` - OpenAI-compatible inference URL. Use this to specify a local or self-deployed AI model. Fallbacks to `https://api.openai.com/v1` if not set.