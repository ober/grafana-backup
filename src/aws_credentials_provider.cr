require "http/client"
require "json"
require "ini"

module GrafanaBackup
  # Provides AWS credentials from various sources:
  # 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # 2. AWS credentials file (~/.aws/credentials)
  # 3. EC2 instance metadata service (IAM instance roles)
  class AwsCredentialsProvider
    class Credentials
      property access_key : String
      property secret_key : String
      property session_token : String?

      def initialize(@access_key : String, @secret_key : String, @session_token : String? = nil)
      end
    end

    # Get credentials using the standard AWS credential provider chain
    def self.get_credentials(profile : String = "default") : Credentials?
      # 1. Try environment variables first
      if creds = from_environment
        return creds
      end

      # 2. Try credentials file
      if creds = from_credentials_file(profile)
        return creds
      end

      # 3. Try EC2 instance metadata (IAM role)
      if creds = from_instance_metadata
        return creds
      end

      nil
    end

    # Get credentials from environment variables
    private def self.from_environment : Credentials?
      access_key = ENV["AWS_ACCESS_KEY_ID"]?
      secret_key = ENV["AWS_SECRET_ACCESS_KEY"]?
      session_token = ENV["AWS_SESSION_TOKEN"]?

      if access_key && secret_key && !access_key.empty? && !secret_key.empty?
        Credentials.new(access_key, secret_key, session_token)
      else
        nil
      end
    end

    # Get credentials from ~/.aws/credentials file
    private def self.from_credentials_file(profile : String = "default") : Credentials?
      home = ENV["HOME"]?
      return nil unless home
      
      credentials_path = File.join(home, ".aws", "credentials")
      
      return nil unless File.exists?(credentials_path)

      begin
        content = File.read(credentials_path)
        ini = INI.parse(content)

        if section = ini[profile]?
          access_key = section["aws_access_key_id"]?
          secret_key = section["aws_secret_access_key"]?
          session_token = section["aws_session_token"]?

          if access_key && secret_key
            return Credentials.new(access_key, secret_key, session_token)
          end
        end
      rescue ex
        # Silently fail and try next provider
      end

      nil
    end

    # Get credentials from EC2 instance metadata service (IMDSv2)
    private def self.from_instance_metadata : Credentials?
      begin
        # First, get the IMDSv2 token
        token = get_imds_token
        return nil unless token

        # Get the IAM role name
        role_name = get_iam_role_name(token)
        return nil unless role_name

        # Get the credentials for the role
        get_iam_role_credentials(token, role_name)
      rescue ex
        # Silently fail if we're not on an EC2 instance or metadata service is unavailable
        nil
      end
    end

    # Get IMDSv2 token
    private def self.get_imds_token : String?
      headers = HTTP::Headers{
        "X-aws-ec2-metadata-token-ttl-seconds" => "21600",
      }

      client = HTTP::Client.new("169.254.169.254")
      client.connect_timeout = 1.second
      client.read_timeout = 1.second
      
      response = client.put(
        "/latest/api/token",
        headers: headers
      )

      if response.status_code == 200
        response.body
      else
        nil
      end
    rescue
      nil
    end

    # Get IAM role name from metadata service
    private def self.get_iam_role_name(token : String) : String?
      headers = HTTP::Headers{
        "X-aws-ec2-metadata-token" => token,
      }

      client = HTTP::Client.new("169.254.169.254")
      client.connect_timeout = 1.second
      client.read_timeout = 1.second
      
      response = client.get(
        "/latest/meta-data/iam/security-credentials/",
        headers: headers
      )

      if response.status_code == 200 && !response.body.empty?
        response.body.strip
      else
        nil
      end
    rescue
      nil
    end

    # Get IAM role credentials from metadata service
    private def self.get_iam_role_credentials(token : String, role_name : String) : Credentials?
      headers = HTTP::Headers{
        "X-aws-ec2-metadata-token" => token,
      }

      client = HTTP::Client.new("169.254.169.254")
      client.connect_timeout = 1.second
      client.read_timeout = 1.second
      
      response = client.get(
        "/latest/meta-data/iam/security-credentials/#{role_name}",
        headers: headers
      )

      if response.status_code == 200
        data = JSON.parse(response.body)
        access_key = data["AccessKeyId"].as_s
        secret_key = data["SecretAccessKey"].as_s
        session_token = data["Token"].as_s

        Credentials.new(access_key, secret_key, session_token)
      else
        nil
      end
    rescue
      nil
    end
  end
end
