# Grafana Backup Tool

A Crystal-based command-line tool for backing up Grafana dashboards to AWS S3 with date-based paths.

## Features

- 🔄 Automatically walks through all Grafana dashboards
- ☁️ Uploads backups to AWS S3 with organized date paths
- 📅 Date-based organization (YYYY/MM/DD)
- 🔐 Secure authentication with Grafana API keys and AWS credentials
- 🚀 Fast and efficient, written in Crystal

## Prerequisites

- Crystal 1.11.2 or later
- Shards (Crystal dependency manager)
- Access to a Grafana instance
- AWS S3 bucket and credentials

## Installation

1. Clone the repository:
```bash
git clone https://github.com/ober/grafana-backup.git
cd grafana-backup
```

2. Install dependencies:
```bash
shards install
```

3. Build the application:
```bash
crystal build src/grafana-backup.cr -o bin/grafana-backup
```

Or build with optimizations:
```bash
crystal build --release src/grafana-backup.cr -o bin/grafana-backup
```

## Configuration

The tool is configured using environment variables:

### Required Variables

- `GRAFANA_API_KEY`: Your Grafana API key with read access to dashboards
- `S3_BUCKET`: The name of your AWS S3 bucket
- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

### Optional Variables

- `GRAFANA_URL`: Grafana instance URL (default: `http://localhost:3000`)
- `S3_REGION`: AWS region for your S3 bucket (default: `us-east-1`)
- `BACKUP_PREFIX`: Prefix for backup paths in S3 (default: `grafana-backups`)

## Usage

### Basic Usage

```bash
export GRAFANA_URL="https://your-grafana-instance.com"
export GRAFANA_API_KEY="your-grafana-api-key"
export S3_BUCKET="your-s3-bucket"
export AWS_ACCESS_KEY_ID="your-aws-access-key"
export AWS_SECRET_ACCESS_KEY="your-aws-secret-key"

./bin/grafana-backup
```

### With Custom Settings

```bash
export GRAFANA_URL="https://grafana.example.com"
export GRAFANA_API_KEY="glsa_xxxxxxxxxxxx"
export S3_BUCKET="my-grafana-backups"
export S3_REGION="us-west-2"
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxx"
export BACKUP_PREFIX="production-backups"

./bin/grafana-backup
```

### Using a .env File

Create a `.env` file:
```bash
GRAFANA_URL=https://grafana.example.com
GRAFANA_API_KEY=glsa_xxxxxxxxxxxx
S3_BUCKET=my-grafana-backups
S3_REGION=us-west-2
AWS_ACCESS_KEY_ID=AKIAXXXXXXXX
AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxx
BACKUP_PREFIX=grafana-backups
```

Then source it and run:
```bash
source .env
./bin/grafana-backup
```

## S3 Backup Structure

Backups are organized in S3 with the following structure:

```
s3://your-bucket/
  └── grafana-backups/          # BACKUP_PREFIX
      └── 2025/                 # Year
          └── 12/               # Month
              └── 17/           # Day
                  ├── dashboard-uid-1.json
                  ├── dashboard-uid-2.json
                  └── dashboard-uid-3.json
```

## Creating a Grafana API Key

1. Log in to your Grafana instance
2. Go to Configuration → API Keys (or Profile → API Keys in newer versions)
3. Click "New API Key"
4. Set a name (e.g., "Backup Tool")
5. Set role to "Viewer" (read-only access is sufficient)
6. Set expiration as needed
7. Click "Add"
8. Copy the generated key (it won't be shown again)

## Scheduling Backups

### Using Cron

Add to your crontab to run daily at 2 AM:

```bash
0 2 * * * /path/to/grafana-backup/bin/grafana-backup >> /var/log/grafana-backup.log 2>&1
```

### Using systemd Timer

Create `/etc/systemd/system/grafana-backup.service`:

```ini
[Unit]
Description=Grafana Backup Service

[Service]
Type=oneshot
EnvironmentFile=/etc/grafana-backup.env
ExecStart=/usr/local/bin/grafana-backup
```

Create `/etc/systemd/system/grafana-backup.timer`:

```ini
[Unit]
Description=Daily Grafana Backup

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl enable grafana-backup.timer
sudo systemctl start grafana-backup.timer
```

## Development

### Project Structure

```
grafana-backup/
├── src/
│   ├── grafana-backup.cr    # Main application
│   ├── config.cr            # Configuration management
│   ├── grafana_client.cr    # Grafana API client
│   ├── s3_uploader.cr       # S3 upload functionality
│   └── backup_service.cr    # Backup orchestration
├── shard.yml                # Dependencies
└── README.md
```

### Running Tests

```bash
crystal spec
```

### Building for Production

```bash
crystal build --release --no-debug src/grafana-backup.cr -o bin/grafana-backup
```

## Troubleshooting

### "GRAFANA_API_KEY is required"
Ensure all required environment variables are set before running the tool.

### "Failed to list dashboards: 401"
Your Grafana API key is invalid or expired. Generate a new one.

### "Failed to list dashboards: 403"
Your API key doesn't have permission to read dashboards. Use a key with at least Viewer role.

### Connection errors to S3
- Verify your AWS credentials are correct
- Check that the S3 bucket exists and you have write permissions
- Ensure the S3 region is correctly specified

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
