# TaskMaster AI Setup for Tournament Management App

## Prerequisites

Before using TaskMaster AI, you need at least one API key from the following providers:
- Anthropic (Claude API) - Recommended for main model
- OpenAI (GPT models)
- Google (Gemini models)
- Perplexity (for research)
- xAI, Mistral, or OpenRouter

## Setup Steps

### 1. Configure API Keys

Edit the `.cursor/mcp.json` file and replace the placeholder API keys with your actual keys:

```json
{
  "mcpServers": {
    "taskmaster-ai": {
      "env": {
        "ANTHROPIC_API_KEY": "sk-ant-api03-your-actual-key-here",
        "OPENAI_API_KEY": "sk-your-actual-openai-key-here"
      }
    }
  }
}
```

**Important**: You can remove API key lines for services you don't use.

### 2. Enable TaskMaster in Cursor

1. Open Cursor Settings (`Ctrl+Shift+J` or `Cmd+,`)
2. Click on the "MCP" tab on the left
3. Find "taskmaster-ai" in the list
4. Enable it with the toggle switch
5. Restart Cursor if prompted

### 3. Configure AI Models (Optional)

In Cursor's AI chat, tell TaskMaster which models to use:

```
Change the main, research and fallback models to claude-3-sonnet, perplexity-llama-3.1-sonar-small-128k-online and gpt-4 respectively.
```

### 4. Verify Installation

In Cursor's AI chat, type:
```
Initialize taskmaster-ai in my project
```

You should see TaskMaster respond and confirm initialization.

## Project-Specific Configuration

This tournament management Flutter app has been pre-configured with:

- **PRD Location**: `.taskmaster/docs/prd.txt`
- **Project Type**: Flutter with clean architecture
- **Backend**: Supabase integration
- **Platforms**: Android, iOS, Web

## Getting Started

1. **Review the PRD**: Check `.taskmaster/docs/prd.txt` and modify as needed
2. **Generate Tasks**: Ask TaskMaster to "Parse my PRD and generate tasks"
3. **Start Development**: Ask "What's the next task I should work on?"

## Common Commands

- `Parse my PRD at .taskmaster/docs/prd.txt`
- `What's the next task I should work on?`
- `Help me implement task [number]`
- `Expand task [number] into subtasks`
- `Show task progress summary`

## Troubleshooting

### TaskMaster Not Responding
- Verify API keys are correct
- Check that the MCP server is enabled in Cursor settings
- Restart Cursor completely

### Cannot Find Tasks
- Ensure you've parsed the PRD first
- Check that `.taskmaster/tasks/` directory exists
- Verify the project initialization completed successfully

### API Errors
- Check your API key balance/quota
- Verify the API key format is correct
- Try using a different model if one fails

## Support

For TaskMaster AI issues:
- GitHub: https://github.com/eyaltoledano/claude-task-master
- Documentation: Check the `docs/` directory

For Flutter development:
- Flutter Documentation: https://docs.flutter.dev
- Supabase Documentation: https://supabase.com/docs 