# Whale Behavior Visualization: Poster Appendix

This repository contains R scripts and supporting files for creating visualizations of whale diving behavior for the poster presentation. The code demonstrates the evolution of visualization techniques from early composite dashboards to integrated hierarchical visualizations.

## Directory Structure

```
Visualization_Poster_Appendix/
├── README.md                   # This documentation file
├── scripts/                    # Directory containing all R scripts
│   ├── run_all.R               # Driver script to run all visualizations
│   ├── 01_setup.R              # Environment setup and utilities
│   ├── 02_data_loading.R       # Data loading functions 
│   ├── 03_composite_dashboard.R # Dashboard visualization
│   ├── 04_dive_overview.R      # Dive overview visualization
│   ├── 05_dive_frames.R        # Individual dive frame visualization
│   ├── 06_hierarchical_visualization.R # 3D hierarchical visualization
│   └── 07_energetics_analysis.R # Energetics analysis visualization
├── docs/                       # Documentation directory
│   ├── code_appendix.md        # Markdown version of code appendix
│   ├── code_appendix_toc.md    # Table of contents for code appendix
│   └── code_appendix.docx      # Word document version of code appendix
├── data/                       # Data directory (must have data files)
│   ├── dive_analysis.h5        # Main HDF5 data file with dive data
│   ├── mn09_203a.csv           # CSV data file
│   └── log_mn09_203a.csv       # Log file with event annotations
└── output/                     # Output directory (created by scripts)
    ├── 01_composite_dashboard.png
    ├── 02_dive_overview.png
    ├── 03_dive_frames/         # Individual dive visualizations
    ├── 04_hierarchical_visualization.html
    └── 05_energetics_analysis.png
```

## Running the Visualizations

To generate all visualizations, run the driver script:

```
cd scripts
Rscript run_all.R
```

This script:
1. Sets the working directory correctly
2. Verifies all required files are present
3. Orchestrates the execution of all modular visualization scripts
4. Generates all output files in the `output` directory

## Visualization Types

The code produces five types of visualizations demonstrating the progression of techniques:

1. **Composite Dashboard** - Early approach with separate panels for different data dimensions
2. **Dive Overview** - Heatmap visualization providing temporal context across all dives
3. **Individual Dive Frames** - Dive visualizations with orientation encoding ("twistiness")
4. **Hierarchical 3D Visualization** - Integrated 3D visualization linking depth, time, and orientation
5. **Energetics Analysis** - Depth vs. ODBA (Overall Dynamic Body Acceleration) visualization

## Requirements

The script requires the following R packages:
- ggplot2
- dplyr
- rhdf5 (from BiocManager)
- plotly
- viridis
- patchwork
- htmlwidgets
- signal
- scales

Missing packages will be automatically installed by the script when executed.

## Data Sources

The whale telemetry data used in these visualizations comes from research conducted at the BioInspired Institute, Syracuse University. The data includes depth, acceleration, and orientation measurements from tags attached to marine mammals.

## Documentation

The `docs` directory contains comprehensive documentation:
- `code_appendix.md`: A markdown document with detailed explanation of the visualization code
- `code_appendix_toc.md`: Table of contents for the code appendix with module descriptions
- `code_appendix.docx`: Microsoft Word version of the code appendix for submission

## Notes

- The hierarchical 3D visualization (04) is generated as an HTML file and should be opened in a web browser.
- Individual dive frames (03) are saved as separate PNG files in the 03_dive_frames directory.
- All visualizations are optimized for inclusion in a scientific poster presentation.
- All fallback code and synthetic data generation has been removed - the scripts require the actual data files. 