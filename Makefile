.PHONY: all build install clean test

all: build

# Install dependencies
deps:
	shards install

# Build the application
build: deps
	@mkdir -p bin
	crystal build src/grafana-backup.cr -o bin/grafana-backup

# Build optimized release version
release: deps
	@mkdir -p bin
	crystal build --release --no-debug src/grafana-backup.cr -o bin/grafana-backup --static

# Install to /usr/local/bin
install: release
	install -m 755 bin/grafana-backup /usr/local/bin/grafana-backup

# Clean build artifacts
clean:
	rm -rf bin/ lib/ .crystal/ .shards/

# Run the application (requires environment variables to be set)
run: build
	./bin/grafana-backup

# Check syntax without building
check:
	crystal build --no-codegen src/grafana-backup.cr

help:
	@echo "Available targets:"
	@echo "  deps     - Install dependencies"
	@echo "  build    - Build the application"
	@echo "  release  - Build optimized release version"
	@echo "  install  - Install to /usr/local/bin"
	@echo "  clean    - Remove build artifacts"
	@echo "  run      - Build and run the application"
	@echo "  check    - Check syntax without building"
	@echo "  help     - Show this help message"
