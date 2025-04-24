Whale Behavior Analysis
│
├── 1. Introduction & Data Visualization
│   ├── Project Overview
│   │   ├── Whale behavior analysis using sensor data
│   │   │   └── [PRESENTATION NOTE] Point to the title and first paragraph in the Overview section
│   │   ├── Classification of dive patterns and behaviors
│   │   │   └── [PRESENTATION NOTE] Discuss during Overview section while showing the dive overview image
│   │   └── Real-world application in marine biology research
│   │       └── [PRESENTATION NOTE] Mention when showing Resources section at the end
│   │
│   ├── Data Collection
│   │   ├── Multi-sensor acceleration and depth recordings
│   │   │   └── [PRESENTATION NOTE] Explain while showing the Dive Frame Analysis section
│   │   ├── Time series data from whale-mounted tags
│   │   │   └── [PRESENTATION NOTE] Reference during Overview section
│   │   └── Raw data processing challenges
│   │       └── [PRESENTATION NOTE] Covered in Dashboard/Metrics section
│   │
│   ├── Visualizations
│       ├── Static Dive Visualization
│       │   ├── 128 detected dives with varying patterns
│       │   │   └── [PRESENTATION NOTE] Point to the Overview section image
│       │   ├── Depth and movement patterns visible
│       │   │   └── [PRESENTATION NOTE] Demonstrate in the Dive Frames section
│       │   └── Color-coding representing movement complexity
│       │       └── [PRESENTATION NOTE] Highlight in Overview image (color intensity)
│       │
│       ├── Interactive 3D Visualization
│       │   ├── 3D representation of dive paths
│       │   │   └── [PRESENTATION NOTE] Show in the Hierarchical Dive Visualization section
│       │   ├── Depth, orientation, and twistiness mapping
│       │   │   └── [PRESENTATION NOTE] Demonstrate by interacting with the hierarchical visualization
│       │   └── Patterns revealing behavioral states
│       │       └── [PRESENTATION NOTE] Point out in hierarchical visualization clusters
│       │
│       └── Dive Frames
│           ├── Frame-by-frame analysis of individual dives
│           │   └── [PRESENTATION NOTE] Demonstrate using the frame controls in Dive Frame Analysis section
│           └── Correlation between visual patterns and behaviors
│               └── [PRESENTATION NOTE] Show while toggling through different frames
│
├── 2. Data Processing & Features
│   ├── Data Challenges
│   │   ├── Noisy sensor data from ocean environment
│   │   │   └── [PRESENTATION NOTE] Mention during Dimensionality Reduction section
│   │   ├── Variable dive durations (30s to 5min)
│   │   │   └── [PRESENTATION NOTE] Point out in Dashboard/Metrics section
│   │   └── Limited labeled ground truth (599 windows)
│   │       └── [PRESENTATION NOTE] Highlight during Training section slides
│   │
│   ├── Feature Extraction
│   │   ├── Statistical measures from raw sensor data
│   │   │   └── [PRESENTATION NOTE] Cover in Dimensionality Reduction section
│   │   ├── Domain-specific features (ODBA, VDBA)
│   │   │   └── [PRESENTATION NOTE] Explain in Dashboard/Energetics section
│   │   └── Windowing technique (100-point, 50% overlap)
│   │       └── [PRESENTATION NOTE] Mention during Training section
│   │
│   ├── Preprocessing Pipeline
│   │   ├── HDF5 file parsing for multi-dimensional data
│   │   │   └── [PRESENTATION NOTE] Reference in Architecture section slides
│   │   ├── Signal filtering and normalization
│   │   │   └── [PRESENTATION NOTE] Cover in Dimensionality Reduction section
│   │   └── Memory-efficient implementations
│   │       └── [PRESENTATION NOTE] Explain during Architecture section
│   │
│   └── Class Handling
│       ├── 8 distinct behavior classes identified
│       │   └── [PRESENTATION NOTE] Point out in Training section slides
│       ├── Significant class imbalance (36% vs 1%)
│       │   └── [PRESENTATION NOTE] Highlight during Training section
│       └── SMOTE augmentation & class weighting
│           └── [PRESENTATION NOTE] Explain in Training section slides
│
├── 3. Model Architecture & Implementation
│   ├── Model Selection Rationale
│   │   ├── Time series nature of whale behavior
│   │   │   └── [PRESENTATION NOTE] Discuss at start of Architecture section
│   │   ├── Need for sequential memory
│   │   │   └── [PRESENTATION NOTE] Explain in Architecture section slides
│   │   └── Efficiency requirements for deployment
│   │       └── [PRESENTATION NOTE] Highlight during Architecture section
│   │
│   ├── minGRU Architecture
│   │   ├── Minimal Gated Recurrent Unit design
│   │   │   └── [PRESENTATION NOTE] Point to details in Architecture slides
│   │   ├── 39,690 trainable parameters (vs ~120K standard)
│   │   │   └── [PRESENTATION NOTE] Highlight comparison in Architecture section
│   │   └── Components: reset/update gates, candidate activation
│   │       └── [PRESENTATION NOTE] Show diagrams in Architecture slides
│   │
│   └── Technical Approach
│       ├── Architecture search & hyperparameter tuning
│       │   └── [PRESENTATION NOTE] Covered in Training section slides
│       ├── Hardware optimization (Metal Performance Shaders)
│       │   └── [PRESENTATION NOTE] Point out in Architecture section slides
│       └── Validation strategy (leave-one-out by whale)
│           └── [PRESENTATION NOTE] Explain in Training section slides
│
└── 4. Results & Conclusion
    ├── Classification Performance
    │   ├── Overall accuracy metrics
    │   │   └── [PRESENTATION NOTE] Show in Conclusions section first card
    │   ├── Per-class performance
    │   │   └── [PRESENTATION NOTE] Reference results in Training section slides
    │   └── Comparison to baseline methods
    │       └── [PRESENTATION NOTE] Point out in Training section slides
    │
    ├── Key Insights
    │   ├── Correlation between depth and behavior
    │   │   └── [PRESENTATION NOTE] Reference in Conclusions section
    │   ├── Movement complexity as behavior indicator
    │   │   └── [PRESENTATION NOTE] Highlight in Conclusions section
    │   └── Duration patterns across different behaviors
    │       └── [PRESENTATION NOTE] Point out in Conclusions section
    │
    └── Future Directions
        ├── Additional sensor integration
        │   └── [PRESENTATION NOTE] Show in Conclusions section "Future Work" card
        ├── Transfer learning across species
        │   └── [PRESENTATION NOTE] Highlight in Conclusions section "Future Work" card
        └── Applications for conservation
            └── [PRESENTATION NOTE] Emphasize in Conclusions section "Future Work" card