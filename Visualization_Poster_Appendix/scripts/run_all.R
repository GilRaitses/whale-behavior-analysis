#!/usr/bin/env Rscript

# Whale Behavior Analysis - Driver Script
# This script sets up the environment and runs the visualization pipeline
# Author: Gil Raitses

# Set the working directory to the scripts directory
script_dir <- dirname(normalizePath(commandArgs(trailingOnly=FALSE)[grep("--file=", commandArgs(trailingOnly=FALSE))][1], winslash="/", mustWork=FALSE))
script_dir <- gsub("^--file=", "", script_dir)
setwd(script_dir)

cat("===================================================\n")
cat("Whale Behavior Visualization Pipeline\n")
cat("===================================================\n")
cat("Working directory set to:", getwd(), "\n\n")

# Source all the modular scripts
source("01_setup.R")
source("02_data_loading.R")
source("03_composite_dashboard.R")
source("04_dive_overview.R")
source("05_dive_frames.R")
source("06_hierarchical_visualization.R")
source("07_energetics_analysis.R")

# Main function to run the entire visualization pipeline
run_visualization_pipeline <- function() {
  cat("Starting whale behavior visualization pipeline...\n")
  
  # Setup environment - this will create output directories in the parent folder
  env <- setup_env()
  output_dir <- env$dirs$base_dir
  cat(sprintf("Output will be saved to: %s\n", normalizePath(output_dir)))
  
  # Set relative data paths
  csv_data_path <- "../data/mn09_203a.csv"
  csv_log_path <- "../data/log_mn09_203a.csv"
  hdf5_data_path <- "../data/dive_analysis.h5"
  
  # Verify data files exist
  tryCatch({
    env$utility_functions$verify_data_paths(csv_data_path, csv_log_path, hdf5_data_path)
  }, error = function(e) {
    stop(paste("Data verification failed:", e$message))
  })
  
  # Visualization 1: Composite Dashboard
  cat("\n==== Creating Visualization #1: Composite Dashboard ====\n")
  csv_data <- load_csv_data(csv_data_path, csv_log_path)
  output_path <- file.path(output_dir, "01_composite_dashboard.png")
  create_composite_dashboard(csv_data, output_path)
  
  # Load HDF5 data
  hdf5_data <- load_hdf5_data(hdf5_data_path)
  
  # Visualization 2: Dive Overview
  cat("\n==== Creating Visualization #2: Dive Overview ====\n")
  output_path <- file.path(output_dir, "02_dive_overview.png")
  create_dive_overview(hdf5_data, output_path)
  
  # Visualization 3: Individual Dive Frames
  cat("\n==== Creating Visualization #3: Individual Dive Frames ====\n")
  create_dive_frames(hdf5_data, output_dir)
  
  # Visualization 4: Hierarchical 3D Visualization
  cat("\n==== Creating Visualization #4: Hierarchical 3D Visualization ====\n")
  output_path <- file.path(output_dir, "04_hierarchical_visualization.html")
  
  # Create a simplified data structure for the hierarchical visualization (following test_hierarchical.R approach)
  cat("Preparing data for hierarchical visualization...\n")
  viz_data <- list(
    depth = hdf5_data$depth,
    eti = hdf5_data$eti,
    sample_rate = hdf5_data$sample_rate,
    dive_indices = hdf5_data$dive_indices,
    orientation = if (!is.null(hdf5_data$orientation$pitch)) hdf5_data$orientation$pitch else NULL,  # Use pitch as orientation
    acceleration = if (!is.null(hdf5_data$jerk)) hdf5_data$jerk else NULL  # Use jerk as acceleration
  )
  
  # Call the hierarchical visualization function with the simplified data structure
  result <- create_hierarchical_visualization(viz_data, output_path)
  
  # Check result
  if (is.character(result) && file.exists(result)) {
    cat(sprintf("SUCCESS: Hierarchical visualization created at %s\n", result))
  } else if (is.character(result)) {
    cat("WARNING: Issue with hierarchical visualization: ", result, "\n")
  }
  
  # Visualization 5: Energetics Analysis
  cat("\n==== Creating Visualization #5: Energetics Analysis ====\n")
  output_path <- file.path(output_dir, "05_energetics_analysis.png")
  
  # Skip energetics analysis if no acceleration data is available
  if (is.null(hdf5_data$acceleration)) {
    cat("WARNING: Acceleration data not found in the data file. Skipping energetics analysis.\n")
    
    # Create a placeholder notice file
    cat("Energetics analysis visualization could not be generated because the acceleration data was not available in the provided HDF5 file.\n", 
        file = gsub(".png", ".txt", output_path))
    cat(sprintf("Created notice file at %s\n", gsub(".png", ".txt", output_path)))
  } else {
    # Only try to create the energetics visualization if data is available
    tryCatch({
      create_energetics_analysis(hdf5_data, output_path)
    }, error = function(e) {
      cat(sprintf("ERROR: Could not create energetics visualization: %s\n", e$message))
      cat("Energetics analysis visualization could not be generated due to an error: ", e$message, "\n", 
          file = gsub(".png", ".txt", output_path))
    })
  }
  
  cat("\nVisualization pipeline complete!\n")
  cat(sprintf("All output files have been saved to %s\n", normalizePath(output_dir)))
}

# Run the pipeline
run_visualization_pipeline()

# Final message
cat("\n===================================================\n")
cat("Visualization pipeline execution complete!\n")
cat("All output files have been saved to the '../output' directory\n")
cat("\nTo view the visualizations, check the following files:\n")
cat("1. ../output/01_composite_dashboard.png\n")
cat("2. ../output/02_dive_overview.png\n")
cat("3. ../output/03_dive_frames/ (directory with individual dive visualizations)\n")
cat("4. ../output/04_hierarchical_visualization.html (open in a web browser)\n")
cat("5. ../output/05_energetics_analysis.png\n")
cat("===================================================\n") 