# Pretty Claude JSON

A bash script for formatting and colorizing Claude raw JSON output with intelligent parsing and presentation.

## Overview

`pretty_claude.sh` is a color/indent-aware formatter specifically designed to make Claude's raw JSON output more readable. It intelligently parses different types of Claude messages and presents them in a structured, colorized format.

## Features

- **Smart JSON parsing**: Automatically detects and handles different Claude message types
- **Color-coded output**: Uses terminal colors to highlight different message components
- **Message type detection**: Recognizes system messages, results, tool calls, and regular messages
- **Usage statistics**: Displays token usage and cost information when available
- **Flexible formatting**: Handles text wrapping based on terminal width

## Requirements

- bash 3.2+
- jq 1.5+
- Terminal with color support (optional but recommended)

## Usage

```bash
# Format Claude JSON output from a file
claude --print --verbose --output-format=stream-json "What directory am I in and what files are in it?" | ./pretty_claude.sh


# Process the example file
./pretty_claude.sh < example.jsonl
```

## Message Types Supported

- **System messages**: Session initialization and configuration
- **Assistant messages**: Claude's responses with content parsing
- **Tool calls**: Function calls with parameters
- **Tool results**: Function call results
- **Result messages**: Final session results with timing and cost info

## Output Format

The script uses various symbols and colors to represent different message types:
- 🔧 System messages
- 💬 Text content
- 🛠 Tool calls
- 🔧 Tool results
- 💭 Thinking content
- 📊 Usage statistics
- ✅ Results

## License

MIT License
