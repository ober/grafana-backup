require "time"
require "json"

module GrafanaBackup
  class BackupService
    getter config : Config
    getter grafana_client : GrafanaClient
    getter s3_uploader : S3Uploader

    def initialize(@config : Config)
      @grafana_client = GrafanaClient.new(@config)
      @s3_uploader = S3Uploader.new(@config)
    end

    def run
      puts "Starting Grafana backup..."

      dashboards = @grafana_client.list_dashboards
      puts "Found #{dashboards.size} dashboards"

      date_path = Time.utc.to_s("%Y/%m/%d")
      backup_count = 0

      dashboards.each do |dashboard_info|
        uid = dashboard_info["uid"].as_s
        title = dashboard_info["title"].as_s

        puts "Backing up: #{title} (#{uid})"

        begin
          dashboard = @grafana_client.get_dashboard(uid)

          # Create S3 key with date path
          key = "#{@config.backup_prefix}/#{date_path}/#{uid}.json"

          # Upload to S3
          @s3_uploader.upload(key, dashboard.to_pretty_json)
          backup_count += 1
        rescue ex
          puts "Error backing up #{title}: #{ex.message}"
        end
      end

      puts "Backup complete! Backed up #{backup_count} of #{dashboards.size} dashboards"
    end
  end
end
