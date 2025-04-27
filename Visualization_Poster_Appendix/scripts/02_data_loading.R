#!/usr/bin/env Rscript

# Whale Behavior Visualization - Data Loading Script
# Functions for loading data from CSV and HDF5 files
# Visualization #: Data Loading (required for all visualizations)

# Load required libraries
if (!requireNamespace("yaml", quietly = TRUE)) {
  install.packages("yaml")
}
library(yaml)
# rhdf5 is required but should be loaded by the calling script

# Default config file path
DEFAULT_CONFIG_PATH <- "data_config.yaml"

# Function to load configuration
load_config <- function(config_file = DEFAULT_CONFIG_PATH) {
  stopifnot(file.exists(config_file))
  
  # Load the YAML configuration
  config <- yaml.load_file(config_file)
  cat(sprintf("Loaded configuration from %s\n", config_file))
  
  return(config)
}

# Function to load CSV data (for early dashboard visualizations)
load_csv_data <- function(data_file, log_file) {
  cat(sprintf("Loading CSV data from %s and %s...\n", data_file, log_file))
  
  # Load data files
  df <- read.csv(data_file)
  log_df <- read.csv(log_file)
  
  stopifnot(nrow(df) > 0, nrow(log_df) > 0)
  
  cat(sprintf("Loaded %d data rows and %d log entries\n", nrow(df), nrow(log_df)))
  
  return(list(
    data = df,
    log = log_df
  ))
}

# Function to load HDF5 data (for hierarchical visualizations)
load_hdf5_data <- function(hdf5_file, config_file = DEFAULT_CONFIG_PATH) {
  cat(sprintf("Loading HDF5 data from %s...\n", hdf5_file))
  
  stopifnot(file.exists(hdf5_file))
  
  # Load configuration
  config <- load_config(config_file)
  paths <- config$paths
  
  # Get file structure for reference
  file_structure <- h5ls(hdf5_file)
  
  # Load depth data
  depth_path <- paths$depth
  cat(sprintf("Loading depth data from %s\n", depth_path))
  depth_data <- h5read(hdf5_file, depth_path)
  cat(sprintf("Loaded depth data, length: %d\n", length(depth_data)))
  
  # Create sample indices
  sample_indices <- seq_len(length(depth_data))
  
  # Load ETI (External Time Index) data
  eti_path <- paths$eti
  cat(sprintf("Loading ETI data from %s\n", eti_path))
  eti_data <- h5read(hdf5_file, eti_path)
  cat(sprintf("Loaded ETI data, length: %d\n", length(eti_data)))
  
  # Load sample rate from HDF5 file
  sample_rate_path <- paths$sample_rate
  cat(sprintf("Loading sample rate from %s\n", sample_rate_path))
  sample_rate <- h5read(hdf5_file, sample_rate_path)
  cat(sprintf("Loaded sample rate: %f Hz\n", sample_rate))
  
  # Create time data
  time_data <- eti_data[1:length(depth_data)]
  cat("Created time array from ETI data\n")
  
  # Load dive indices
  dive_indices_path <- paths$dive_indices
  cat(sprintf("Loading dive indices from %s\n", dive_indices_path))
  
  # Debug info
  dive_match <- file_structure[file_structure$group == "/dives" & file_structure$name == "dive_indices", ]
  cat("Matching dive indices entry:\n")
  print(dive_match)
  
  # Load dive indices directly as a 3×N matrix
  # In our data, dive_indices is a 3×N matrix (3 rows × N columns) where:
  # Row 1: Start index
  # Row 2: Max depth index
  # Row 3: End index
  dive_indices <- h5read(hdf5_file, dive_indices_path)
  
  # No reshaping needed - the matrix should already be in the correct format
  cat(sprintf("Loaded dive indices, count: %d\n", ncol(dive_indices)))
  
  # Load annotations from attributes
  annotations_root <- paths$annotations_root
  cat(sprintf("Loading annotations from %s\n", annotations_root))
  
  # Get annotation groups from file structure
  annotation_groups <- file_structure[file_structure$group == annotations_root, ]
  cat(sprintf("Found %d annotation groups\n", nrow(annotation_groups)))
  
  # Load all annotations
  annotation_data <- list()
  for (i in 1:nrow(annotation_groups)) {
    annotation_name <- annotation_groups$name[i]
    annotation_path <- file.path(annotations_root, annotation_name)
    
    # Read attributes directly
    attrs <- h5readAttributes(hdf5_file, annotation_path)
    
    # Store the attributes in the list
    annotation_data[[annotation_name]] <- attrs
  }
  
  # Load behavior types
  behavior_types_path <- paths$behavior_types
  cat(sprintf("Loading behavior types from %s\n", behavior_types_path))
  
  # Get behavior types directly from file structure
  behavior_types <- file_structure[file_structure$group == behavior_types_path, "name"]
  cat(sprintf("Found %d behavior types\n", length(behavior_types)))
  
  # Load orientation data
  pitch_path <- paths$pitch
  roll_path <- paths$roll
  heading_path <- paths$head
  
  cat("Loading orientation data\n")
  pitch <- h5read(hdf5_file, pitch_path)
  roll <- h5read(hdf5_file, roll_path)
  heading <- h5read(hdf5_file, heading_path)
  
  orientation_data <- list(
    pitch = pitch,
    roll = roll,
    heading = heading
  )
  cat("Loaded orientation data\n")
  
  # Load acceleration data
  acc_x_path <- paths$acceleration_x
  acc_y_path <- paths$acceleration_y
  acc_z_path <- paths$acceleration_z
  
  cat("Loading acceleration data\n")
  acc_x <- h5read(hdf5_file, acc_x_path)
  acc_y <- h5read(hdf5_file, acc_y_path)
  acc_z <- h5read(hdf5_file, acc_z_path)
  
  acceleration_data <- cbind(acc_x, acc_y, acc_z)
  cat("Loaded acceleration data\n")
  
  # Load derived metrics directly
  cat("Loading derived metrics\n")
  
  # Load jerk
  jerk_path <- paths$jerk
  jerk_data <- h5read(hdf5_file, jerk_path)
  cat(sprintf("Loaded jerk magnitude, length: %d\n", length(jerk_data)))
  
  # Load ODBA
  odba_path <- paths$odba
  odba_data <- h5read(hdf5_file, odba_path)
  cat(sprintf("Loaded ODBA, length: %d\n", length(odba_data)))
  
  # Load VDBA
  vdba_path <- paths$vdba
  vdba_data <- h5read(hdf5_file, vdba_path)
  cat(sprintf("Loaded VDBA, length: %d\n", length(vdba_data)))
  
  # Load dive-level metrics
  cat("Loading dive phase metrics\n")
  descent_duration <- h5read(hdf5_file, paths$descent_duration)
  descent_rate <- h5read(hdf5_file, paths$descent_rate)
  bottom_duration <- h5read(hdf5_file, paths$bottom_duration)
  ascent_duration <- h5read(hdf5_file, paths$ascent_duration)
  ascent_rate <- h5read(hdf5_file, paths$ascent_rate)
  
  # Load bottom start and end indices from dive segment attributes
  n_dives <- ncol(dive_indices)
  bottom_start_idx <- numeric(n_dives)
  bottom_end_idx <- numeric(n_dives)
  
  cat("Loading bottom phase indices from dive segments\n")
  for (i in 1:n_dives) {
    # Skip if beyond the maximum dives we can display (14)
    if (i > 14) {
      bottom_start_idx[i] <- -1
      bottom_end_idx[i] <- -1
      next
    }
    
    # Form the path to this dive's segment
    dive_segment_path <- file.path(paths$dive_segments, sprintf("dive_%03d", i))
    
    # Try to read the attributes
    attrs <- tryCatch({
      h5readAttributes(hdf5_file, dive_segment_path)
    }, error = function(e) {
      # If the dive segment doesn't exist, return NULL
      cat(sprintf("Warning: Dive segment %s not found\n", dive_segment_path))
      return(NULL)
    })
    
    # Get the indices from attributes if they exist
    if (!is.null(attrs) && "bottom_start_idx" %in% names(attrs) && "bottom_end_idx" %in% names(attrs)) {
      bottom_start_idx[i] <- attrs$bottom_start_idx
      bottom_end_idx[i] <- attrs$bottom_end_idx
    } else {
      # Default to max depth point if no attributes exist
      bottom_start_idx[i] <- dive_indices[2, i]  # Use max depth index as fallback
      bottom_end_idx[i] <- dive_indices[2, i]
    }
  }
  
  # Load dive-level metrics
  dive_odba_path <- paths$dive_odba
  dive_vdba_path <- paths$dive_vdba
  
  dive_odba <- h5read(hdf5_file, dive_odba_path)
  dive_vdba <- h5read(hdf5_file, dive_vdba_path)
  
  # Create a data frame with dive metrics
  dive_metrics <- data.frame(
    dive_id = 1:length(dive_odba),
    odba = dive_odba,
    vdba = dive_vdba,
    descent_duration = descent_duration,
    descent_rate = descent_rate,
    bottom_duration = bottom_duration,
    ascent_duration = ascent_duration,
    ascent_rate = ascent_rate
  )
  cat("Loaded dive-level metrics and phase metrics\n")
  
  # Return data as list
  return(list(
    depth = depth_data,
    time = time_data,
    eti = eti_data,
    dive_indices = dive_indices,
    orientation = orientation_data,
    acceleration = acceleration_data,
    sample_rate = sample_rate,
    sample_indices = sample_indices,
    file_structure = file_structure,
    annotations = annotation_data,
    behavior_types = behavior_types,
    jerk = jerk_data,
    odba = odba_data,
    vdba = vdba_data,
    dive_metrics = dive_metrics,
    bottom_start_idx = bottom_start_idx,
    bottom_end_idx = bottom_end_idx
  ))
} 