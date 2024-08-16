require 'net/http'
require 'json'
require 'uri'
require 'fileutils'

module OpenAIHelperGem
  class Client
    @notification_method = :mac_os
    @default_audio_path = ENV['OPENAI_AUDIO_PATH'] || File.join(Dir.home, 'Local Resources', 'API Logs', 'OpenAI Whisper')
    @api_key = ENV['OPENAI_API_KEY']
    @tts_api_endpoint = URI('https://api.openai.com/v1/audio/speech')
    @file_upload_endpoint = URI('https://api.openai.com/v1/files')
    @chat_completion_endpoint = URI('https://api.openai.com/v1/chat/completions')

    class << self
      attr_accessor :notification_method, :default_audio_path, :api_key

      def upload_file(file_path)
        file = File.open(file_path, 'rb')
        request_data = { purpose: 'assistant', file: file }

        begin
          http = Net::HTTP.new(@file_upload_endpoint.host, @file_upload_endpoint.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(@file_upload_endpoint.path, { 'Authorization': "Bearer #{@api_key}" })
          request.set_form([['file', file]], 'multipart/form-data')
          response = http.request(request)
          file.close
          result = JSON.parse(response.body)
          if result['error']
            notify_error("File Upload Failed", result['error']['message'])
            exit 1
          end
          result['id']
        rescue StandardError => e
          notify_error("File Upload Error", e.message)
          exit 1
        end
      end

      def send_message_with_file(messages, file_id)
        request_data = { model: ENV['GPT_MODEL'] || 'gpt-3.5-turbo', messages: messages, file_ids: [file_id] }

        begin
          http = Net::HTTP.new(@chat_completion_endpoint.host, @chat_completion_endpoint.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(@chat_completion_endpoint.path, {
            'Content-Type': 'application/json',
            'Authorization': "Bearer #{@api_key}"
          })
          request.body = request_data.to_json
          response = http.request(request)
          JSON.parse(response.body)
        rescue StandardError => e
          notify_error("API Request Failed", e.message)
          exit 1
        end
      end

      def generate_speech(text, output_file_name = "output.mp3", autoplay: true)
        request_data = { model: 'tts-1-hd', voice: 'alloy', input: text }

        begin
          http = Net::HTTP.new(@tts_api_endpoint.host, @tts_api_endpoint.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(@tts_api_endpoint.path, {
            'Content-Type': 'application/json',
            'Authorization': "Bearer #{@api_key}"
          })
          request.body = request_data.to_json
          response = http.request(request)

          output_path = File.join(@default_audio_path, output_file_name)
          FileUtils.mkdir_p(File.dirname(output_path))
          File.open(output_path, 'wb') { |file| file.write(response.body) }

          puts "Audio saved to #{output_path}"
          play_audio(output_path) if autoplay
        rescue StandardError => e
          notify_error("Text-to-Speech Error", e.message)
          exit 1
        end
      end

      def play_audio(file_path)
        system("afplay '#{file_path}'")
      end

      def extract_structured_output(response)
        if response['error']
          notify_error("API Error", response['error']['message'])
          exit 1
        end

        function_call = response.dig('choices', 0, 'message', 'function_call')
        unless function_call && function_call['arguments']
          notify_error("Invalid Response", "No structured output found in the response.")
          exit 1
        end

        begin
          JSON.parse(function_call['arguments'])
        rescue JSON::ParserError => e
          notify_error("JSON Parsing Error", e.message)
          exit 1
        end
      end

      def perform_request(messages, schema, file_path = nil)
        file_id = upload_file(file_path) if file_path
        response = send_message_with_file(messages, file_id) if file_id
        extract_structured_output(response)
      end

      def notify_error(title, message)
        case @notification_method
        when :mac_os
          system("osascript -e 'display notification \"#{message}\" with title \"#{title}\"'")
        when :puts
          puts "[#{title}] #{message}"
        when :none
          # No output
        else
          puts "[Unknown Notification Method] #{title}: #{message}"
        end
      end
    end
  end
end