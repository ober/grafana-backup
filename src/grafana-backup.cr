require "./config"
require "./grafana_client"
require "./s3_uploader"
require "./backup_service"

module GrafanaBackup
  VERSION = "1.0.0"

  def self.run
    puts "Grafana Backup Tool v#{VERSION}"
    puts "=" * 50

    config = Config.new

    begin
      config.validate!
    rescue ex
      puts "Configuration error: #{ex.message}"
      puts "\nRequired environment variables:"
      puts "  GRAFANA_API_KEY - Grafana API key"
      puts "  S3_BUCKET - AWS S3 bucket name"
      puts "  AWS_ACCESS_KEY_ID - AWS access key"
      puts "  AWS_SECRET_ACCESS_KEY - AWS secret key"
      puts "\nOptional environment variables:"
      puts "  GRAFANA_URL (default: http://localhost:3000)"
      puts "  S3_REGION (default: us-east-1)"
      puts "  BACKUP_PREFIX (default: grafana-backups)"
      exit 1
    end

    puts "Configuration:"
    puts "  Grafana URL: #{config.grafana_url}"
    puts "  S3 Bucket: #{config.s3_bucket}"
    puts "  S3 Region: #{config.s3_region}"
    puts "  Backup Prefix: #{config.backup_prefix}"
    puts "=" * 50
    puts ""

    service = BackupService.new(config)
    service.run
  end
end

GrafanaBackup.run
