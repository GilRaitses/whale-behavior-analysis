# Dive Analysis Report

*Generated on: 2025-04-10 13:56:31*

## Report Summary

This report provides an overview of the dive behavior analysis results.

### Dataset Overview
* Analyzed 42 dive events
* Identified 7 distinct behaviors
* Depth range: 0 to 35.8 meters
The report includes 2 interactive visualizations.



## Dive Visualizations

### Enhanced t-SNE

*Multi-factor t-SNE visualization colored by behavior type*

[View visualization in interactive report](interactive_visualizations/enhanced_tsne.html)

### Energy t-SNE

*t-SNE visualization colored by energy expenditure*

[View visualization in interactive report](interactive_visualizations/energy_tsne.html)

## Data Analysis

### Behavior Distribution

| Behavior | Count |
|----------|-------|
| Side rolls | 9 |
| Exploratory dives | 7 |
| Kick feeding | 8 |
| Noodle feeding | 6 |
| Feeding loop | 5 |
| Side rolls and loop | 4 |
| Traveling | 3 |

### Feature Importance

#### Observations

* The top feature is acc_x_std with 0.1820 importance
* Accelerometer features contribute 0.6120 total importance
* Depth-related features contribute 0.3880 total importance

#### Top Features

| Feature | Importance |
|---------|------------|
| acc_x_std | 0.1820 |
| depth_range | 0.1740 |
| acc_z_mean | 0.1560 |
| depth_max | 0.1420 |
| acc_y_std | 0.1260 |

