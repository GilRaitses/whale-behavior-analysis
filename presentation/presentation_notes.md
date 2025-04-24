Whale Behavior Analysis
│
├── 1. Introduction & Data Visualization
│   ├── Project Overview
│   │   ├── Whale behavior analysis using sensor data
│   │   ├── Classification of dive patterns and behaviors
│   │   └── Real-world application in marine biology research
│   │
│   ├── Data Collection
│   │   ├── Multi-sensor acceleration and depth recordings
│   │   ├── Time series data from whale-mounted tags
│   │   └── Raw data processing challenges
│   │
│   ├── Visualizations
│       ├── Static Dive Visualization
│       │   ├── 128 detected dives with varying patterns
│       │   ├── Depth and movement patterns visible
│       │   └── Color-coding representing movement complexity
│       │
│       ├── Interactive 3D Visualization
│       │   ├── 3D representation of dive paths
│       │   ├── Depth, orientation, and twistiness mapping
│       │   └── Patterns revealing behavioral states
│       │
│       └── Dive Frames
│           ├── Frame-by-frame analysis of individual dives
│           └── Correlation between visual patterns and behaviors
│
├── 2. Data Processing & Features
│   ├── Data Challenges
│   │   ├── Noisy sensor data from ocean environment
│   │   ├── Variable dive durations (30s to 5min)
│   │   └── Limited labeled ground truth (599 windows)
│   │
│   ├── Feature Extraction
│   │   ├── Statistical measures from raw sensor data
│   │   ├── Domain-specific features (ODBA, VDBA)
│   │   └── Windowing technique (100-point, 50% overlap)
│   │
│   ├── Preprocessing Pipeline
│   │   ├── HDF5 file parsing for multi-dimensional data
│   │   ├── Signal filtering and normalization
│   │   └── Memory-efficient implementations
│   │
│   └── Class Handling
│       ├── 8 distinct behavior classes identified
│       ├── Significant class imbalance (36% vs 1%)
│       └── SMOTE augmentation & class weighting
│
├── 3. Model Architecture & Implementation
│   ├── Model Selection Rationale
│   │   ├── Time series nature of whale behavior
│   │   ├── Need for sequential memory
│   │   └── Efficiency requirements for deployment
│   │
│   ├── minGRU Architecture
│   │   ├── Minimal Gated Recurrent Unit design
│   │   ├── 39,690 trainable parameters (vs ~120K standard)
│   │   └── Components: reset/update gates, candidate activation
│   │
│   └── Technical Approach
│       ├── Architecture search & hyperparameter tuning
│       ├── Hardware optimization (Metal Performance Shaders)
│       └── Validation strategy (leave-one-out by whale)
│
└── 4. Results & Conclusion
    ├── Classification Performance
    │   ├── Overall accuracy metrics
    │   ├── Per-class performance
    │   └── Comparison to baseline methods
    │
    ├── Key Insights
    │   ├── Correlation between depth and behavior
    │   ├── Movement complexity as behavior indicator
    │   └── Duration patterns across different behaviors
    │
    └── Future Directions
        ├── Additional sensor integration
        ├── Transfer learning across species
        └── Applications for conservation