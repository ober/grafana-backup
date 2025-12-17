require "json"

module GrafanaBackup
  class Config
    property grafana_url : String
    property grafana_api_key : String
    property s3_bucket : String
    property s3_region : String
    property s3_access_key : String
    property s3_secret_key : String
    property backup_prefix : String

    def initialize
      @grafana_url = ENV.fetch("GRAFANA_URL", "http://localhost:3000")
      @grafana_api_key = ENV.fetch("GRAFANA_API_KEY", "")
      @s3_bucket = ENV.fetch("S3_BUCKET", "")
      @s3_region = ENV.fetch("S3_REGION", "us-east-1")
      @s3_access_key = ENV.fetch("AWS_ACCESS_KEY_ID", "")
      @s3_secret_key = ENV.fetch("AWS_SECRET_ACCESS_KEY", "")
      @backup_prefix = ENV.fetch("BACKUP_PREFIX", "grafana-backups")
    end

    def validate!
      raise "GRAFANA_API_KEY is required" if @grafana_api_key.empty?
      raise "S3_BUCKET is required" if @s3_bucket.empty?
      raise "AWS_ACCESS_KEY_ID is required" if @s3_access_key.empty?
      raise "AWS_SECRET_ACCESS_KEY is required" if @s3_secret_key.empty?
    end
  end
end
