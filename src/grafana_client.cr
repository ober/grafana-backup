require "http/client"
require "json"

module GrafanaBackup
  class GrafanaClient
    getter config : Config

    def initialize(@config : Config)
    end

    def list_dashboards : Array(JSON::Any)
      response = make_request("/api/search?type=dash-db")
      
      if response.status_code == 200
        JSON.parse(response.body).as_a
      else
        raise "Failed to list dashboards: #{response.status_code} - #{response.body}"
      end
    end

    def get_dashboard(uid : String) : JSON::Any
      response = make_request("/api/dashboards/uid/#{uid}")
      
      if response.status_code == 200
        JSON.parse(response.body)
      else
        raise "Failed to get dashboard #{uid}: #{response.status_code} - #{response.body}"
      end
    end

    private def make_request(path : String) : HTTP::Client::Response
      uri = URI.parse(@config.grafana_url)
      
      HTTP::Client.new(uri) do |client|
        headers = HTTP::Headers{
          "Authorization" => "Bearer #{@config.grafana_api_key}",
          "Content-Type"  => "application/json",
        }
        
        client.get(path, headers: headers)
      end
    end
  end
end
