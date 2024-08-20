# OpenAIHelperGem

`OpenAIHelperGem` is a Ruby module designed to streamline interactions with OpenAI's API. It offers an array of features for developers and power users who want to automate tasks, integrate AI-powered workflows, and enhance productivity on macOS. Whether you're triggering scripts from the terminal, Alfred, or macOS Shortcuts, this gem provides a solid foundation for integrating AI services seamlessly.

## Features

- **Simplified API Requests:** Easily send messages to OpenAI and receive structured responses, including automated schema generation.
- **File Handling:** Attach and process both text and image files in your requests, with automatic content handling.
- **Text-to-Speech (TTS):** Convert text to high-quality speech, save the audio locally, and optionally play it immediately.
- **Automation Ready:** Perfect for use in productivity scripts, terminal commands, Alfred workflows, and macOS Shortcuts.
- **Logging:** Keep a detailed log of all requests and responses, ensuring you have a record of your AI interactions.
- **Custom Notifications:** Tailor error handling and notifications to suit your workflow (macOS notifications, terminal output, or silent mode).

## Installation

Add the module to your project:

```ruby
require 'openai_helper_gem'
```

Ensure you have the following environment variables set:

- `OPENAI_API_KEY`: Your OpenAI API key.
- `GPT_MODEL` (optional): The OpenAI model you wish to use (defaults to `gpt-4`).
- `OPENAI_AUDIO_PATH` (optional): Custom path to save generated audio (defaults to the user's home directory).

## Usage

### Basic Example

Send a message and receive a structured response with automatic schema generation:

```ruby
require 'openai_helper_gem'

messages = [{ role: 'user', content: 'Summarize this document.' }]
response_structure = {
  summary: {
    type: "string",
    description: "A concise summary of the document."
  }
}

response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)
puts response['summary']
```

### File Processing

Upload and process files as part of your requests:

#### Text File Example

```ruby
file_path = '/path/to/your/documents/summary.txt'
messages = [
  { role: 'user', content: 'Summarize the attached document.', content_files: [file_path] }
]

response_structure = {
  summary: {
    type: "string",
    description: "A summary of the text file."
  }
}

response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)
puts response['summary']
```

#### Image File Example

```ruby
file_path = '/path/to/your/pictures/image.jpg'
messages = [
  { role: 'user', content: 'Describe the contents of this image.', image_files: [file_path] }
]

response_structure = {
  image_description: {
    type: "string",
    description: "A description of the image."
  }
}

response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)
puts response['image_description']
```

### Text-to-Speech

Generate and play audio responses:

```ruby
OpenAIHelperGem::Client.generate_speech("This is an automated message.", "message.mp3", autoplay: true)
```

Generate speech without autoplay:

```ruby
OpenAIHelperGem::Client.generate_speech("This is a test message.", "output.mp3", autoplay: false)
```

### Automating Tasks

**Example 1: Automated Email Drafting**

Generate a professional email draft based on meeting notes:

```ruby
file_path = '/path/to/your/meeting_notes.txt'
messages = [
  { role: 'user', content: 'Draft an email based on the meeting notes.', content_files: [file_path] }
]

response_structure = {
  email_subject: {
    type: "string",
    description: "A subject line for the email."
  },
  email_body: {
    type: "string",
    description: "The main content of the email."
  }
}

response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)
puts "Subject: #{response['email_subject']}"
puts "Body:\n#{response['email_body']}"
```

**Example 2: Organizing and Categorizing Images**

Categorize images based on their contents:

```ruby
image_files = ['/path/to/your/pictures/image1.jpg', '/path/to/your/pictures/image2.jpg']

image_files.each do |file_path|
  messages = [
    { role: 'user', content: 'Categorize this image.', image_files: [file_path] }
  ]

  response_structure = {
    image_category: {
      type: "string",
      description: "A category for the image."
    }
  }

  response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)
  puts "Image: #{File.basename(file_path)} - Category: #{response['image_category']}"
end
```

### Custom Notifications

Customize how errors and notifications are handled:

```ruby
# Use terminal output for notifications
OpenAIHelperGem::Client.notification_method = :puts

# Disable notifications
OpenAIHelperGem::Client.notification_method = :none
```

### Advanced Example: Processing Multiple Files

This advanced example demonstrates how to process all files in a specified folder, extract key topics and details, and then generate an audio summary.

```ruby
require 'openai_helper_gem'

# Folder containing text files
folder_path = '/path/to/your/documents/ProjectNotes'
text_files = Dir.glob("#{folder_path}/*.md")

messages = [
  { role: 'user', content: 'Analyze the attached documents, identify the most relevant topic, and provide a detailed description.' }
]

# Adding content from each file
text_files.each do |file_path|
  messages << { role: 'user', content: "Please include details from this document.", content_files: [file_path] }
end

# Define the response structure
response_structure = {
  relevant_topic: {
    type: "string",
    description: "The most relevant topic across all documents."
  },
  detailed_description: {
    type: "string",
    description: "A detailed description of the relevant topic."
  }
}

# Make the request
response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)

# Output the result
if response && response['relevant_topic'] && response['detailed_description']
  puts "Relevant Topic: #{response['relevant_topic']}"
  puts "Detailed Description:\n#{response['detailed_description']}"
  
  # Generate and play the audio summary
  full_text = "The most relevant topic across all documents is #{response['relevant_topic']}. Here is a detailed description: #{response['detailed_description']}"
  OpenAIHelperGem::Client.generate_speech(full_text, "project_summary.mp3", autoplay: true)
else
  puts "Failed to generate the topic and description."
end
```

## License

This module is licensed under the MIT License. Feel free to use and modify it in your own projects. See the `LICENSE.txt` file for more details.