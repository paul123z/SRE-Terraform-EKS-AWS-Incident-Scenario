#!/bin/bash

# dos2unix.sh - Convert all .sh scripts to Unix line endings for WSL compatibility
# This script recursively finds all .sh files and converts Windows line endings to Unix

# set -e disabled due to grep exit codes causing early termination

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  DOS2UNIX Script Converter${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_header

# Check if dos2unix is installed
if ! command -v dos2unix &> /dev/null; then
    print_error "dos2unix is not installed!"
    print_status "Installing dos2unix..."
    
    # Try to install dos2unix
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y dos2unix
    elif command -v yum &> /dev/null; then
        sudo yum install -y dos2unix
    elif command -v brew &> /dev/null; then
        brew install dos2unix
    else
        print_error "Cannot install dos2unix automatically. Please install it manually:"
        print_error "  Ubuntu/Debian: sudo apt-get install dos2unix"
        print_error "  CentOS/RHEL: sudo yum install dos2unix"
        print_error "  macOS: brew install dos2unix"
        exit 1
    fi
fi

print_status "Finding all .sh files in the repository..."
mapfile -t SH_FILES < <(find . -name "*.sh" -type f ! -path "./.git/*" | sort)

# Debug: Show first few files found
print_status "DEBUG: First 5 files found:"
for i in "${!SH_FILES[@]}"; do
    if [ $i -lt 5 ]; then
        echo "  [$i]: ${SH_FILES[$i]}"
    fi
done

# Check if we found any files
if [ ${#SH_FILES[@]} -eq 0 ]; then
    print_warning "No .sh files found in the repository"
    exit 0
fi

# Count total files
TOTAL_FILES=${#SH_FILES[@]}
print_status "Found $TOTAL_FILES shell script(s) to process"
echo ""

# Process each file
CONVERTED_COUNT=0
ALREADY_UNIX_COUNT=0
ERROR_COUNT=0

# Process each file using for loop (more reliable than while loop with stdin)
print_status "DEBUG: Starting to process ${#SH_FILES[@]} files..."
for file in "${SH_FILES[@]}"; do
    print_status "DEBUG: Current file: '$file'"
    if [ -n "$file" ] && [ -f "$file" ]; then
        print_status "Processing: $file"
        
        # Check if file has Windows line endings
        print_status "DEBUG: Checking file format..."
        FILE_INFO=$(file "$file" 2>/dev/null)
        print_status "DEBUG: File info: $FILE_INFO"
        if echo "$FILE_INFO" | grep -q "CRLF" || [[ $? == 1 ]]; then
            HAS_CRLF=$?
        else
            HAS_CRLF=2
        fi
        
        if [[ $HAS_CRLF == 0 ]]; then
            # File has Windows line endings, convert it
            print_status "DEBUG: File has CRLF, converting..."
            if dos2unix "$file" 2>/dev/null; then
                print_success "  ✅ Converted to Unix line endings"
                ((CONVERTED_COUNT++))
            else
                print_error "  ❌ Failed to convert"
                ((ERROR_COUNT++))
            fi
        else
            # File already has Unix line endings
            print_status "DEBUG: File already has Unix line endings"
            print_success "  ✅ Already has Unix line endings"
            print_status "DEBUG: About to increment ALREADY_UNIX_COUNT (current: $ALREADY_UNIX_COUNT)"
            ((ALREADY_UNIX_COUNT++))
            print_status "DEBUG: Incremented ALREADY_UNIX_COUNT to: $ALREADY_UNIX_COUNT"
        fi
        print_status "DEBUG: Finished processing $file"
    elif [ -n "$file" ]; then
        print_error "File not found: $file"
        ((ERROR_COUNT++))
    fi
done

print_status "DEBUG: Finished processing all files!"
echo ""
print_header

# Summary
print_status "CONVERSION SUMMARY:"
echo ""
print_success "  📁 Total files processed: $TOTAL_FILES"
print_success "  🔄 Files converted: $CONVERTED_COUNT"
print_success "  ✅ Already Unix format: $ALREADY_UNIX_COUNT"

if [ $ERROR_COUNT -gt 0 ]; then
    print_error "  ❌ Errors encountered: $ERROR_COUNT"
else
    print_success "  ❌ Errors encountered: 0"
fi

echo ""

if [ $ERROR_COUNT -gt 0 ]; then
    print_warning "Some files had errors during conversion. Please check manually."
    exit 1
else
    print_success "🎉 All shell scripts are now WSL-compatible!"
    print_status "You can now run any .sh script in WSL without line ending issues."
fi

echo ""
print_status "Files processed:"
for file in "${SH_FILES[@]}"; do
    echo "  • $file"
done
