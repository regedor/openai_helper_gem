require 'net/http'
require 'json'
require 'uri'
require 'fileutils'
require 'base64'

module OpenAIHelperGem
  class Client
    @notification_method = :both
    @model = ENV['GPT_MODEL'] || 'gpt-4o-mini'
    @api_key = ENV['OPENAI_API_KEY']
    @default_audio_path = ENV['OPENAI_AUDIO_PATH'] || File.join(Dir.home, 'Local Resources', 'API Logs', 'OpenAI Whisper')
    @request_log_path = ENV['OPENAI_REQUEST_LOG_PATH'] || File.join(Dir.home, 'Local Resources', 'API Logs', 'open_ai_helper_gem_request.txt')

    @tts_api_endpoint = URI('https://api.openai.com/v1/audio/speech')
    @chat_completion_endpoint = URI('https://api.openai.com/v1/chat/completions')

    @debugging = true

    raise "API key not set. Please set the 'OPENAI_API_KEY' environment variable." unless @api_key
    FileUtils.mkdir_p(File.dirname(@default_audio_path)) unless Dir.exist?(File.dirname(@default_audio_path))
    FileUtils.mkdir_p(File.dirname(@request_log_path)) unless Dir.exist?(File.dirname(@request_log_path))

    class << self
      attr_accessor :notification_method, :default_audio_path, :request_log_path, :api_key

      # Simplified method to make a strict GPT request with an auto-constructed schema.
      def strict_gpt_request(messages, simplified_structure)
        # Convert the simplified structure into a full JSON schema
        schema = construct_schema(simplified_structure)
        send_message_with_strict_schema(messages, schema)
      end

      # Generates speech from text using OpenAI's TTS API and saves the audio locally.
      # Optionally, it can automatically play the generated audio file.
      def generate_speech(text, output_file_name = "output.mp3", autoplay: true)
        request_data = { model: 'tts-1-hd', voice: 'alloy', input: text }

        begin
          response = make_api_request(@tts_api_endpoint, request_data)

          output_path = File.join(@default_audio_path, output_file_name)
          FileUtils.mkdir_p(File.dirname(output_path))
          File.open(output_path, 'wb') { |file| file.write(response.body) }

          puts "Audio saved to #{output_path}"
          play_audio(output_path) if autoplay
        rescue StandardError => e
          notify_error("Text-to-Speech Error", e.message)
        end
      end

      # Plays an audio file on macOS using the 'afplay' command.
      def play_audio(file_path)
        system("afplay '#{file_path}'")
      end

      private

      # Constructs the full JSON schema based on the simplified structure provided by the user.
      def construct_schema(simplified_structure)
        {
          name: "response",
          strict: true,
          schema: {
            type: "object",
            properties: simplify_structure_keys(simplified_structure),
            required: simplified_structure.keys.map(&:to_s),
            additionalProperties: false
          }
        }
      end

      # Converts symbol keys to strings recursively
      def simplify_structure_keys(structure)
        structure.each_with_object({}) do |(key, value), result|
          result[key.to_s] = value
        end
      end

      # Sends a message to the OpenAI API with a specified strict schema and returns the structured response.
      def send_message_with_strict_schema(messages, schema)
        messages.each do |message|
          # Initialize content array with the main text content
          content_array = [{ type: "text", text: message[:content] }]

          # Process image files
          if message[:image_files]
            content_array += message[:image_files].map do |file|
              { type: "image_url", image_url: { url: "data:image/jpeg;base64,#{encode_image(file)}" } }
            end
          end

          # Process content files
          if message[:content_files]
            content_array += message[:content_files].map do |file|
              { type: "text", text: "Below is the content of the file #{File.basename(file)}:\n\n#{File.read(file)}" }
            end
          end

          # Replace the content in the message with the constructed array
          message[:content] = content_array
          message.delete(:image_files)
          message.delete(:content_files)
        end

        request_data = {
          model: @model,
          messages: messages,
          response_format: {
            type: "json_schema",
            json_schema: schema
          }
        }

        puts "API Request: #{request_data}" if @debugging

        begin
          response = make_api_request(@chat_completion_endpoint, request_data)
          log_request_info(response.body)

          parsed_response = JSON.parse(response.body)
          puts "Raw API Response: #{parsed_response}" if @debugging

          return extract_strict_schema_output(parsed_response, schema[:name])
        rescue StandardError => e
          notify_error("API Request Failed", e.message)
          log_request_info(e.message)
          return nil
        end
      end

      # Encodes an image file to a base64 string.
      def encode_image(image_path)
        Base64.strict_encode64(File.read(image_path))
      end

      # Makes a POST request to the specified endpoint with the provided data.
      def make_api_request(endpoint, data)
        http = Net::HTTP.new(endpoint.host, endpoint.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(endpoint.path, {
          'Content-Type': 'application/json',
          'Authorization': "Bearer #{@api_key}"
        })
        request.body = data.to_json
        http.request(request)
      end

      # Extracts and parses the structured output from the API response based on the provided schema.
      def extract_strict_schema_output(response, expected_function_name)
        return nil unless response
        return nil if response['error']

        # Extract the content from the response
        choice = response.dig('choices', 0, 'message', 'content')
        
        # Parse the JSON string in 'content' if it exists
        parsed_content = choice ? JSON.parse(choice) : nil
      
        # Return the parsed content if it matches the expected schema
        return parsed_content if parsed_content.is_a?(Hash)
      
        notify_error("Schema Validation Failed", "The response does not match the expected schema.")
        nil
      end

      # Displays a notification or logs an error message depending on the configured notification method.
      def notify_error(title, message)
        case @notification_method
        when :mac_os
          system("osascript -e 'display notification \"#{message}\" with title \"#{title}\"'")
        when :puts, :both
          puts "[#{title}] #{message}"
          system("osascript -e 'display notification \"#{message}\" with title \"#{title}\"'") if @notification_method == :both
        end
      end

      # Logs information about the API request, including the response body.
      def log_request_info(response_body)
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        log_entry = "#{timestamp}\nAPI Response: #{response_body}\n\n"
        File.open(@request_log_path, 'a') { |f| f.write(log_entry) }
      end
    end
  end
end

# Example usage
file_path = '/Users/miguel/Desktop/b.png'
file_path2 = '/Users/miguel/Desktop/aa.txt'
messages = [
  { role: 'system', content: 'I analyze images You must include the company stated in the file' },
  { role: 'user', content: "What is in the image? Please describe the attached image but state the company in the file.", image_files: [file_path] },
  { role: 'user', content: "Somehow in the middle of the image descriptions, include a summary of this text file (you should find the name of the company).", content_files: [file_path2] }
]

response_structure = {
  image_description: {
    type: "string",
    description: "An image description of approximately 20 words."
  },
  image_description_in_3_words: {
    type: "string",
    description: "An image description of 3 words."
  },
  company_name: {
    type: "string",
    description: "Name of the company referred in the shared file."
  }
}

response = OpenAIHelperGem::Client.strict_gpt_request(messages, response_structure)

if response && response['image_description']
  puts "Description: #{response['image_description']}"
  OpenAIHelperGem::Client.generate_speech(response['image_description'])
else
  puts "Failed to generate description."
end