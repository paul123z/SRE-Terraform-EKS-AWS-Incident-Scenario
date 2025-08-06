#!/bin/bash

# Export Flowcharts Script
# This script extracts Mermaid diagrams from ARCHITECTURE_FLOWCHARTS.md
# and exports them as PNG images for better visualization

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if mermaid-cli is installed
check_mermaid_cli() {
    if ! command -v mmdc &> /dev/null; then
        print_warning "mermaid-cli not found. Installing..."
        npm install -g @mermaid-js/mermaid-cli
        if [ $? -ne 0 ]; then
            print_error "Failed to install mermaid-cli. Please install manually:"
            echo "npm install -g @mermaid-js/mermaid-cli"
            exit 1
        fi
    fi
    print_success "mermaid-cli is available"
}

# Create output directory
create_output_dir() {
    OUTPUT_DIR="flowchart-exports"
    mkdir -p "$OUTPUT_DIR"
    print_status "Created output directory: $OUTPUT_DIR"
}

# Extract Mermaid diagrams from markdown
extract_diagrams() {
    local input_file="ARCHITECTURE_FLOWCHARTS.md"
    local temp_dir="temp-mermaid"
    
    mkdir -p "$temp_dir"
    
    print_status "Extracting Mermaid diagrams from $input_file..."
    
    # Extract diagrams using awk
    awk '
    /^```mermaid$/ {
        in_mermaid = 1
        diagram_name = ""
        diagram_content = ""
        next
    }
    
    in_mermaid && /^```$/ {
        in_mermaid = 0
        if (diagram_name == "") {
            diagram_name = "diagram_" ++count
        }
        gsub(/[^a-zA-Z0-9_-]/, "_", diagram_name)
        filename = "temp-mermaid/" diagram_name ".mmd"
        print diagram_content > filename
        print "Extracted: " filename
        next
    }
    
    in_mermaid {
        if (diagram_name == "" && /^graph/) {
            # Try to extract a meaningful name from the first line
            diagram_name = $0
            gsub(/^graph [A-Z]+ /, "", diagram_name)
            gsub(/[^a-zA-Z0-9_-]/, "_", diagram_name)
        }
        diagram_content = diagram_content "\n" $0
    }
    
    /^## / && !in_mermaid {
        # Extract section name for diagram naming
        section_name = $0
        gsub(/^## /, "", section_name)
        gsub(/[^a-zA-Z0-9_-]/, "_", section_name)
        current_section = section_name
    }
    ' "$input_file"
    
    print_success "Diagrams extracted to $temp_dir/"
}

# Export diagrams to PNG
export_diagrams() {
    local temp_dir="temp-mermaid"
    local output_dir="flowchart-exports"
    
    print_status "Exporting diagrams to PNG..."
    
    for file in "$temp_dir"/*.mmd; do
        if [ -f "$file" ]; then
            filename=$(basename "$file" .mmd)
            output_file="$output_dir/${filename}.png"
            
            print_status "Exporting $filename..."
            mmdc -i "$file" -o "$output_file" -b transparent -w 1920 -H 1080
            
            if [ $? -eq 0 ]; then
                print_success "Exported: $output_file"
            else
                print_error "Failed to export: $filename"
            fi
        fi
    done
}

# Clean up temporary files
cleanup() {
    print_status "Cleaning up temporary files..."
    rm -rf temp-mermaid
    print_success "Cleanup complete"
}

# Main execution
main() {
    print_status "Starting flowchart export process..."
    
    check_mermaid_cli
    create_output_dir
    extract_diagrams
    export_diagrams
    cleanup
    
    print_success "All flowcharts exported successfully!"
    print_status "Check the '$OUTPUT_DIR' directory for PNG files"
    print_status "You can now use these high-quality images in your YouTube video"
    
    echo ""
    echo "📁 Exported files:"
    ls -la "$OUTPUT_DIR"/*.png 2>/dev/null || echo "No PNG files found"
}

# Run main function
main "$@" 