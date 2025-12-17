require "json"
require "./aws_credentials_provider"

module GrafanaBackup
  class Config
    property grafana_url : String
    property grafana_api_key : String
    property s3_bucket : String
    property s3_region : String
    property s3_access_key : String
    property s3_secret_key : String
    property s3_session_token : String?
    property backup_prefix : String
    property aws_profile : String

    def initialize
      @grafana_url = ENV.fetch("GRAFANA_URL", "http://localhost:3000")
      @grafana_api_key = ENV.fetch("GRAFANA_API_KEY", "")
      @s3_bucket = ENV.fetch("S3_BUCKET", "")
      @s3_region = ENV.fetch("S3_REGION", "us-east-1")
      @backup_prefix = ENV.fetch("BACKUP_PREFIX", "grafana-backups")
      @aws_profile = ENV.fetch("AWS_PROFILE", "default")
      
      # Try to get AWS credentials from various sources
      # Priority: env vars -> credentials file -> IAM instance role
      @s3_access_key = ENV.fetch("AWS_ACCESS_KEY_ID", "")
      @s3_secret_key = ENV.fetch("AWS_SECRET_ACCESS_KEY", "")
      @s3_session_token = ENV["AWS_SESSION_TOKEN"]?
      
      # If credentials are not in environment variables, try other sources
      if @s3_access_key.empty? || @s3_secret_key.empty?
        if creds = AwsCredentialsProvider.get_credentials(@aws_profile)
          @s3_access_key = creds.access_key
          @s3_secret_key = creds.secret_key
          @s3_session_token = creds.session_token
        end
      end
    end

    def validate!
      raise "GRAFANA_API_KEY is required" if @grafana_api_key.empty?
      raise "S3_BUCKET is required" if @s3_bucket.empty?
      raise "AWS credentials not found. Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables, configure ~/.aws/credentials, or use an IAM instance role." if @s3_access_key.empty? || @s3_secret_key.empty?
    end
  end
end
