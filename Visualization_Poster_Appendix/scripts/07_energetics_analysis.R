#!/usr/bin/env Rscript

# Whale Behavior Visualization - Energetics Analysis
# Visualization #5: Energetics Analysis

library(ggplot2)
library(viridis)

create_energetics_analysis <- function(hdf5_data, output_path) {
  cat("Creating energetics analysis visualization...\n")
  
  # Extract data
  depth_data <- hdf5_data$depth
  sample_indices <- hdf5_data$sample_indices
  acceleration_data <- hdf5_data$acceleration
  dive_indices <- hdf5_data$dive_indices
  sample_rate <- hdf5_data$sample_rate
  
  # Get utility functions from global environment (from setup.R)
  create_dark_theme <- get("create_dark_theme", envir = .GlobalEnv)
  
  # Calculate dive metrics
  dive_metrics <- calculate_dive_metrics(depth_data, dive_indices, sample_rate, acceleration_data)
  
  # Get dark theme from utility function
  dark_theme <- create_dark_theme(background_color = "#1A1A1A", text_color = "white")
  
  # Create plot - with odba on x-axis and max_depth on y-axis
  p <- ggplot(dive_metrics, aes(x = odba, y = max_depth, color = duration)) +
    geom_point(size = 4, alpha = 0.8) +
    scale_color_viridis_c(
      option = "inferno", 
      name = "Dive Duration (s)",
      guide = guide_colorbar(
        barwidth = 1, 
        barheight = 20,  
        title.position = "right",
        title.vjust = 1
      )
    ) +
    scale_y_reverse(limits = c(40, 0)) +  # Inverts y-axis with 0 at top and 40 at bottom
    labs(
      title = "ODBA vs Maximum Depth",
      x = "Overall Dynamic Body Acceleration (Force Magnitude)",
      y = "Maximum Depth (m)"
    ) +
    dark_theme
  
  # Save the plot
  ggsave(
    output_path,
    plot = p,
    width = 12,
    height = 8,
    dpi = 300,
    bg = "#1A1A1A"
  )
  
  cat(sprintf("Saved energetics analysis to %s\n", output_path))
  return(output_path)
} 