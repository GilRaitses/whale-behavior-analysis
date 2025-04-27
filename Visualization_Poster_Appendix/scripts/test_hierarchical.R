#!/usr/bin/env Rscript

# Test script for hierarchical visualization
# This script loads data from HDF5 file and passes it to the hierarchical visualization function

# Load required libraries
library(rhdf5)
library(yaml)

cat("Starting test of hierarchical visualization...\n")

# Source the data loading module
source("02_data_loading.R")

# Source the hierarchical visualization module
source("06_hierarchical_visualization.R")

# Set paths
config_file <- "data_config.yaml"
if (!file.exists(config_file)) {
  cat(sprintf("ERROR: Configuration file %s not found\n", config_file))
  quit(status = 1)
}

# Set output path
output_dir <- "../output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
output_path <- file.path(output_dir, "test_hierarchical_visualization.html")

# Load HDF5 data using the data loading module
hdf5_path <- "../data/dive_analysis.h5"
if (!file.exists(hdf5_path)) {
  cat(sprintf("ERROR: HDF5 file %s not found\n", hdf5_path))
  quit(status = 1)
}

# Load HDF5 data directly with the function
cat("Loading data from", hdf5_path, "...\n")
hdf5_data <- load_hdf5_data(hdf5_path, config_file)

# Create a simplified data structure for the hierarchical visualization
cat("Preparing data for visualization...\n")
viz_data <- list(
  depth = hdf5_data$depth,
  eti = hdf5_data$eti,
  sample_rate = hdf5_data$sample_rate,
  dive_indices = hdf5_data$dive_indices,
  orientation = hdf5_data$orientation$pitch,  # Use pitch as orientation
  acceleration = hdf5_data$jerk  # Use jerk as acceleration
)

# Call the hierarchical visualization function
cat("Creating hierarchical visualization...\n")
result <- create_hierarchical_visualization(viz_data, output_path)

# Check result
if (is.character(result) && file.exists(result)) {
  cat(sprintf("SUCCESS: Hierarchical visualization created at %s\n", result))
  cat("Open this file in a web browser to view the visualization.\n")
} else {
  cat("ERROR: Failed to create hierarchical visualization\n")
  if (is.character(result)) {
    cat("Error message:", result, "\n")
  }
} 