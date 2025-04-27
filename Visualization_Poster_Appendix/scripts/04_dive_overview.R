#!/usr/bin/env Rscript

# Whale Behavior Visualization - Dark-Themed Dive Overview
# Visualization #2: Dark Dive Overview

library(ggplot2)
library(viridis)
library(dplyr)
library(scales)
library(signal)

# Use the utility functions from setup.R

create_dive_overview <- function(hdf5_data, output_path) {
  cat("Creating dive overview visualization...\n")
  
  # Get utility functions from global environment (from setup.R)
  format_time_smart <- get("format_time_smart", envir = .GlobalEnv)
  create_dark_theme <- get("create_dark_theme", envir = .GlobalEnv)
  calculate_twistiness <- get("calculate_twistiness", envir = .GlobalEnv)
  
  # Extract data
  depth_data <- hdf5_data$depth
  dive_indices <- hdf5_data$dive_indices  # Only needed for count
  orientation_data <- hdf5_data$orientation
  eti_data <- hdf5_data$eti
  sample_rate <- hdf5_data$sample_rate
  
  # Calculate twistiness
  twistiness <- calculate_twistiness(orientation_data)
  
  # Ensure twistiness has the same length as depth data
  if (length(twistiness) != length(depth_data)) {
    # Trim or pad the data to match
    twistiness <- twistiness[1:length(depth_data)]
  }
  
  # ETI values are already in seconds
  eti_seconds <- eti_data
  
  # Print time range for debugging
  total_hours <- (max(eti_seconds) - min(eti_seconds)) / 3600
  cat("Total dataset time span:", round(total_hours, 2), "hours (", round(max(eti_seconds)/60, 1), "minutes)\n")
  
  # Create a data frame for plotting
  plot_data <- data.frame(
    time = eti_seconds,
    depth = depth_data,
    twistiness = twistiness
  )
  
  # Count dives for the title
  n_dives <- ncol(dive_indices)
  
  # Create 12 evenly spaced time breaks
  time_range <- range(plot_data$time)
  time_breaks <- seq(time_range[1], time_range[2], length.out = 12)
  
  # Get dark theme from utility function with dark gray background (matching dive frames)
  dark_theme <- create_dark_theme(background_color = "#1A1A1A", text_color = "white")
  
  # Add additional tweaks specific to the overview plot
  dark_theme <- dark_theme + theme(
    axis.text.x = element_text(angle = 0, hjust = 0.5, color = "white"), # Horizontal labels
    panel.grid.major.x = element_line(color = "#333333", linewidth = 0.1),
    panel.grid.major.y = element_line(color = "#333333", linewidth = 0.1),
    panel.border = element_rect(color = "white", fill = NA, linewidth = 0.5)
  )
  
  # Create the plot with a smoother line using geom_line instead of geom_path
  p <- ggplot(plot_data, aes(x = time, y = depth)) +
    geom_line(aes(color = twistiness, linewidth = 0.8 + 2.5*twistiness), # More gradual line width scaling
             alpha = 0.85,  # Slightly higher alpha for better visibility
             lineend = "round",
             linejoin = "round") +
    scale_color_viridis_c(
      option = "plasma", 
      name = "Relative\nTwistiness",
      guide = guide_colorbar(
        barwidth = 1, 
        barheight = 10,
        title.position = "right",
        title.vjust = 1
      )
    ) +
    scale_linewidth_identity() +
    scale_y_reverse(name = "Depth (m)") +
    scale_x_continuous(
      name = "Time (s)",
      breaks = time_breaks,
      labels = sapply(time_breaks, format_time_smart),
      expand = expansion(mult = c(0.0025, 0.0025)) # 0.25% padding
    ) +
    labs(
      title = sprintf("Dive Dataset Overview (%d dives)", n_dives),
      caption = "Line color/thickness indicates body orientation rates"
    ) +
    dark_theme
  
  # Remove coord_cartesian which might be restricting the range
  # Don't use coord_cartesian for x-axis, only for y-axis
  p <- p + coord_cartesian(ylim = c(40, 0))
  
  # Add border around the plot
  p <- p + 
    theme(
      panel.border = element_rect(color = "white", fill = NA, linewidth = 0.5)
    )
  
  # Save plot
  ggsave(
    output_path,
    plot = p,
    width = 15,
    height = 8,
    dpi = 300,
    bg = "#1A1A1A"
  )
  
  cat(sprintf("Saved dive overview to %s\n", output_path))
  return(output_path)
} 