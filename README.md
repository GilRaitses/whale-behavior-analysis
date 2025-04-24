# Whale Behavior Analysis Presentation

This is an interactive presentation website for the Whale Behavior Analysis project, built for the Applied Machine Learning course.

## Structure

The presentation is organized as follows:

- **Visualizations**: Interactive dashboard showing dive data
- **Dive Frames**: Static visualizations of individual dives
- **Classification Results**: Training outcomes and challenges
- **Model Architecture**: minGRU implementation details
- **Technical Details**: Implementation specifics

## How to Run

1. Make sure all files are properly organized by running the included script:
   ```bash
   chmod +x reorganize.sh
   ./reorganize.sh
   ```

2. Open `index.html` in a modern web browser (Chrome, Firefox, Safari)

## Contents

- `/assets/` - Static images and dive frames
- `/css/` - Stylesheet for the presentation
- `/js/` - JavaScript functionality
- `/presentation/` - Technical content (markdown files)
- `/visualizations/` - Interactive dive visualizations
- `/dashboard/` - Overview dashboards

## Technical Notes

- The website uses basic markdown parsing for technical content
- Interactive visualizations are loaded in iframes
- Navigation between sections uses anchor links
- Tabs are used to organize related content within sections

## Features

- Interactive dashboard for dive visualization
- Individual dive selection and visualization
- Static frame viewer with 128 dive frames
- Technical presentation of minGRU architecture
- Overview of classification challenges and solutions

## Requirements

- Modern web browser with JavaScript enabled
- Local file access (no server required) 