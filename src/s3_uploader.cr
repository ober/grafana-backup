require "awscr-s3"
require "awscr-signer"
require "http/client"
require "uri"

module GrafanaBackup
  class S3Uploader
    getter config : Config

    def initialize(@config : Config)
    end

    def upload(key : String, content : String)
      # If we have a session token, we need to use a custom approach
      # because the standard awscr-s3 Client doesn't support session tokens
      if @config.s3_session_token
        upload_with_session_token(key, content)
      else
        # Use the standard client for static credentials
        upload_with_standard_client(key, content)
      end

      puts "Uploaded to s3://#{@config.s3_bucket}/#{key}"
    end

    private def upload_with_standard_client(key : String, content : String)
      client = Awscr::S3::Client.new(
        @config.s3_region,
        @config.s3_access_key,
        @config.s3_secret_key
      )

      io = IO::Memory.new(content)

      client.put_object(
        @config.s3_bucket,
        key,
        io
      )
    end

    private def upload_with_session_token(key : String, content : String)
      # Build the S3 URL
      host = "#{@config.s3_bucket}.s3.#{@config.s3_region}.amazonaws.com"
      path = "/#{key}"
      url = URI.parse("https://#{host}#{path}")

      # Create HTTP client
      HTTP::Client.new(url) do |client|
        # Create the request
        request = HTTP::Request.new("PUT", path)
        request.headers["Host"] = host
        request.headers["Content-Length"] = content.bytesize.to_s
        request.body = content

        # Create signer with session token support
        signer = Awscr::Signer::Signers::V4.new(
          service: "s3",
          region: @config.s3_region,
          aws_access_key: @config.s3_access_key,
          aws_secret_key: @config.s3_secret_key,
          amz_security_token: @config.s3_session_token
        )

        # Sign the request
        signer.sign(request)

        # Execute the request
        response = client.exec(request)

        # Accept both 200 and 201 status codes for successful uploads
        unless [200, 201].includes?(response.status_code)
          raise "Failed to upload to S3: #{response.status_code} - #{response.body}"
        end
      end
    end
  end
end
