# Makefile for Cursor Agent VIM Plugin

# Variables
PLUGIN_NAME = cursor-agent-vim-plugin
VIM_PLUGIN_DIR = $(HOME)/.vim/pack/plugins/start
INSTALL_DIR = $(VIM_PLUGIN_DIR)/$(PLUGIN_NAME)

# Default target
all: help

# Help target
help:
	@echo "Cursor Agent VIM Plugin Makefile"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  install    - Install the plugin to VIM"
	@echo "  uninstall  - Remove the plugin from VIM"
	@echo "  test       - Run plugin tests"
	@echo "  clean      - Clean up temporary files"
	@echo "  help       - Show this help message"
	@echo ""

# Install the plugin
install:
	@echo "Installing Cursor Agent VIM Plugin..."
	@mkdir -p $(VIM_PLUGIN_DIR)
	@if [ -d "$(INSTALL_DIR)" ]; then \
		echo "Removing existing installation..."; \
		rm -rf $(INSTALL_DIR); \
	fi
	@cp -r . $(INSTALL_DIR)
	@echo "Plugin installed to $(INSTALL_DIR)"
	@echo "Restart VIM to load the plugin"

# Uninstall the plugin
uninstall:
	@echo "Uninstalling Cursor Agent VIM Plugin..."
	@if [ -d "$(INSTALL_DIR)" ]; then \
		rm -rf $(INSTALL_DIR); \
		echo "Plugin removed from $(INSTALL_DIR)"; \
	else \
		echo "Plugin not found in $(INSTALL_DIR)"; \
	fi

# Run tests
test:
	@echo "Running plugin tests..."
	@vim -S test/test_cursor_agent.vim

# Clean up
clean:
	@echo "Cleaning up..."
	@find . -name "*.swp" -delete
	@find . -name "*.swo" -delete
	@find . -name "*~" -delete
	@echo "Cleanup complete"

# Check if cursor-agent is installed
check-deps:
	@echo "Checking dependencies..."
	@if command -v cursor-agent >/dev/null 2>&1; then \
		echo "✓ cursor-agent is installed"; \
	else \
		echo "✗ cursor-agent not found. Please install it first."; \
		echo "  Visit: https://github.com/getcursor/cursor-agent"; \
	fi

# Show plugin status
status:
	@echo "Cursor Agent VIM Plugin Status"
	@echo "=============================="
	@if [ -d "$(INSTALL_DIR)" ]; then \
		echo "✓ Plugin is installed"; \
		echo "  Location: $(INSTALL_DIR)"; \
	else \
		echo "✗ Plugin is not installed"; \
	fi
	@echo ""
	@$(MAKE) check-deps

.PHONY: all help install uninstall test clean check-deps status