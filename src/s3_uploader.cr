require "awscr-s3"

module GrafanaBackup
  class S3Uploader
    getter config : Config

    def initialize(@config : Config)
    end

    def upload(key : String, content : String)
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

      puts "Uploaded to s3://#{@config.s3_bucket}/#{key}"
    end
  end
end
