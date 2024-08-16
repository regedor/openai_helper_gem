# OpenAIHelperGem

`OpenAIHelperGem` is a Ruby module designed to simplify interactions with OpenAI's API. It provides functionality to upload files, send messages with structured outputs, generate speech from text, and automatically play the resulting audio on macOS.

## Features

- **File Upload:** Upload files to OpenAI and retrieve `file_id` for further use.
- **Text-to-Speech (TTS):** Convert text to high-quality speech and save the audio locally.
- **Autoplay Audio:** Automatically play the generated audio after saving (configurable).
- **Structured Output Extraction:** Send messages and extract structured outputs from OpenAI responses.
- **Custom Notifications:** Handle errors with notifications (macOS, terminal output, or none).

## Installation

Add the module to your project:

```ruby
require_relative 'path_to_openai_helper_gem/openai_helper_gem'
```

Ensure you have the following environment variables set:

- `OPENAI_API_KEY`: Your OpenAI API key.
- `GPT_MODEL` (optional): The OpenAI model you wish to use (defaults to gpt-3.5-turbo).
- `OPENAI_AUDIO_PATH` (optional): Custom path to save generated audio (defaults to the user's home directory).

## Usage

### Basic Example

Send a message and extract structured output:

```ruby
require_relative 'openai_helper_gem'

messages = [{ role: 'user', content: 'Tell me a joke.' }]
schema = {
  type: "object",
  properties: {
    joke: { type: "string" }
  },
  required: ["joke"]
}

response = OpenAIHelperGem::Client.perform_request(messages, schema)
puts response['joke']
```

### File Upload

Upload a file to OpenAI and retrieve the `file_id`:

```ruby
file_id = OpenAIHelperGem::Client.upload_file('path_to_your_file.pdf')
```

### Generate Speech

Generate speech from text and automatically play the audio:

```ruby
OpenAIHelperGem::Client.generate_speech("This is a test message.")
```

Generate speech without playing it immediately:

```ruby
OpenAIHelperGem::Client.generate_speech("This is a test message.", "output.mp3", autoplay: false)
```

### Notifications

Customize how errors and other notifications are handled:

Use terminal output:

```ruby
OpenAIHelperGem::Client.notification_method = :puts
```

Disable notifications:

```ruby
OpenAIHelperGem::Client.notification_method = :none
```

### Default Paths

The module saves generated audio files to a default directory in the user's home folder:

```ruby
OpenAIHelperGem::Client.default_audio_path = ENV['OPENAI_AUDIO_PATH'] || File.join(Dir.home, 'Local Resources', 'API Logs', 'OpenAI Whisper')
```

## Complex Example

Here’s a more comprehensive example that combines file upload, schema validation, and text-to-speech generation:

```ruby
require_relative 'openai_helper_gem'

# Step 1: Define messages and schema
messages = [
  { role: 'user', content: 'Please summarize the attached document.' }
]

schema = {
  type: "object",
  properties: {
    summary: { type: "string" }
  },
  required: ["summary"]
}

# Step 2: Send message with the file and extract structured output
response = OpenAIHelperGem::Client.perform_request(messages, schema, 'path_to_your_document.pdf')

# Step 3: Output the summary
puts response['summary']

# Step 4: Convert the summary to speech and save it as an audio file
OpenAIHelperGem::Client.generate_speech(response['summary'], "document_summary.mp3")
```

## License

This module is free to use and modify under the MIT License. See the `LICENSE.txt` file for more details.