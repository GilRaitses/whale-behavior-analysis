#!/bin/bash

# Make script executable with: chmod +x convert_to_png.sh

# Script to convert HTML slides to PNG images using Chrome headless
# Prerequisites: Chrome or Chromium installed

echo "Converting HTML slides to PNG images..."

# Set the output directory for PNGs
OUTPUT_DIR="png_slides"
mkdir -p "$OUTPUT_DIR"

# Create a temporary JavaScript file to get document height
cat > get_height.js << 'EOL'
// Calculate the full height of the document
function getDocumentHeight() {
    return Math.max(
        document.body.scrollHeight,
        document.body.offsetHeight,
        document.documentElement.clientHeight,
        document.documentElement.scrollHeight,
        document.documentElement.offsetHeight
    );
}
console.log(getDocumentHeight());
EOL

# List of HTML slides to convert
SLIDES=(
  "slide1_title.html"
  "slide2_problem.html"
  "slide3_solution.html"
  "slide4_data.html"
  "slide5_dimensionality.html"
  "slide6_architecture.html"
  "slide7_challenges.html"
  "slide8_conclusions.html"
)

# Get full path to current directory
CURRENT_DIR="$(pwd)"

# Convert each slide
for slide in "${SLIDES[@]}"; do
  echo "Converting $slide..."
  
  # Get the base name without extension for the output file
  basename=$(echo "$slide" | sed 's/\.html$//')
  
  # Full path to the slide
  full_path="file://${CURRENT_DIR}/${slide}"
  
  # First get the height of the document
  echo "Getting height for $slide..."
  doc_height=$(/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
    --headless \
    --disable-gpu \
    --window-size=1920,1080 \
    --virtual-time-budget=2000 \
    --disable-web-security \
    --evaluate-on-load-script="${CURRENT_DIR}/get_height.js" \
    "${full_path}" 2>&1 | grep -v "DevTools" | tail -1)
  
  # Add a little padding to the height
  height=$((doc_height + 100))
  echo "Document height: $height px"
  
  # Use Chrome/Chromium to capture a screenshot with the calculated height
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
    --headless \
    --disable-gpu \
    --hide-scrollbars \
    --window-size=1920,$height \
    --virtual-time-budget=5000 \
    --screenshot="${CURRENT_DIR}/${OUTPUT_DIR}/${basename}.png" \
    "${full_path}"
  
  # Check if the file was created
  if [ -f "${CURRENT_DIR}/${OUTPUT_DIR}/${basename}.png" ]; then
    echo "✅ Created ${OUTPUT_DIR}/${basename}.png with height $height px"
  else
    echo "❌ Failed to create ${OUTPUT_DIR}/${basename}.png"
  fi
  
  # Sleep to make sure Chrome has time to exit properly
  sleep 1
done

# Clean up
rm get_height.js

echo "Conversion complete! PNG files should be in the $OUTPUT_DIR directory."
echo "Running 'ls -la ${OUTPUT_DIR}' to verify:"
ls -la "${OUTPUT_DIR}" 