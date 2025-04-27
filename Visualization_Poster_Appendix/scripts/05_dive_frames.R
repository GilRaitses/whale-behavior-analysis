#!/usr/bin/env Rscript

# Whale Behavior Visualization - Dark-Themed Individual Dive Frames
# Visualization #3: Dive Frames

library(ggplot2)
library(viridis)
library(tidyr)
library(signal)
library(zoo)

# Instead of defining format_time_smart here, we'll use the utility function from setup

create_dive_frames <- function(hdf5_data, output_dir) {
  cat("Creating individual dive frame visualizations...\n")
  
  # Get utility functions from global environment (from setup.R)
  format_time_smart <- get("format_time_smart", envir = .GlobalEnv)
  create_dark_theme <- get("create_dark_theme", envir = .GlobalEnv)
  calculate_twistiness <- get("calculate_twistiness", envir = .GlobalEnv)
  
  # Extract data
  depth_data <- hdf5_data$depth
  eti_data <- hdf5_data$eti  # ETI values are already in seconds
  sample_rate <- hdf5_data$sample_rate
  orientation_data <- hdf5_data$orientation
  dive_indices <- hdf5_data$dive_indices
  
  # Setup output directory
  dive_frames_dir <- file.path(output_dir, "03_dive_frames")
  if (!dir.exists(dive_frames_dir)) {
    dir.create(dive_frames_dir, recursive = TRUE)
  }
  
  # Get dark theme from utility function
  dark_theme <- create_dark_theme(background_color = "#1A1A1A", text_color = "white")
  
  # Set max number of dives (limit to 14)
  num_dives <- ncol(dive_indices)
  max_dives <- min(num_dives, 14)
  
  cat("Processing", max_dives, "dives\n")
  
  # Process each dive
  for (i in 1:max_dives) {
    # Get indices from the 3×N matrix (rows: start, max, end)
    start_idx <- dive_indices[1, i]
    max_depth_idx <- dive_indices[2, i]
    end_idx <- dive_indices[3, i]
    
    # Get bottom phase indices (directly from data)
    bottom_start_idx <- hdf5_data$bottom_start_idx[i]
    bottom_end_idx <- hdf5_data$bottom_end_idx[i]
    
    # Validate indices
    if (start_idx < 1 || end_idx > length(depth_data) || start_idx >= end_idx) {
      cat("Warning: Invalid dive indices for dive", i, "- skipping\n")
      next
    }
    
    # Calculate dive duration in seconds
    dive_duration_seconds <- round((eti_data[end_idx] - eti_data[start_idx]))
    
    # Get time values in seconds from the overall dataset (not normalized to dive start)
    dive_eti_seconds <- eti_data[start_idx:end_idx]
    
    # Extract dive data
    dive_depth <- depth_data[start_idx:end_idx]
    dive_pitch <- orientation_data$pitch[start_idx:end_idx]
    dive_roll <- orientation_data$roll[start_idx:end_idx]
    dive_heading <- orientation_data$heading[start_idx:end_idx]
    
    # Calculate twistiness
    if (length(dive_pitch) > 5) {
      # Create a temporary orientation data structure for this dive
      dive_orientation <- list(
        pitch = dive_pitch,
        roll = dive_roll,
        heading = dive_heading
      )
      
      # Use the shared utility function
      dive_twistiness <- calculate_twistiness(
        orientation_data = dive_orientation,
        sample_rate = sample_rate,
        window_size = min(21, length(dive_pitch)),
        heading_weight = 2,
        normalize_method = "percentile"
      )
    } else {
      dive_twistiness <- rep(0, length(dive_depth))
    }
    
    # Ensure all vectors have the same length
    n <- min(length(dive_eti_seconds), length(dive_depth), length(dive_twistiness))
    
    # Create data frame
    orig_df <- data.frame(
      eti = dive_eti_seconds[1:n],
      depth = dive_depth[1:n],
      twistiness = dive_twistiness[1:n]
    )
    
    # Interpolate for smoother visualization
    if (n > 10) {
      interp_factor <- 5
      new_eti <- seq(min(orig_df$eti), max(orig_df$eti), length.out = n * interp_factor)
      new_depth <- approx(orig_df$eti, orig_df$depth, new_eti, method = "linear")$y
      new_twistiness <- approx(orig_df$eti, orig_df$twistiness, new_eti, method = "linear")$y
      
      dive_df <- data.frame(
        eti = new_eti,
        depth = new_depth,
        twistiness = new_twistiness
      )
    } else {
      dive_df <- orig_df
    }
    
    # Calculate x-axis breaks - exactly 12 breaks
    max_eti <- max(dive_df$eti)
    min_eti <- min(dive_df$eti)
    
    # Round min and max to nearest 5 seconds
    min_eti_rounded <- floor(min_eti / 5) * 5
    max_eti_rounded <- ceiling(max_eti / 5) * 5
    
    # Calculate total duration and determine interval for 12 breaks
    total_duration <- max_eti_rounded - min_eti_rounded
    interval_seconds <- ceiling(total_duration / 11)  # 11 intervals for 12 breaks
    
    # Round up to the nearest 5-second multiple
    interval_seconds <- ceiling(interval_seconds / 5) * 5
    
    # Generate exactly 12 breaks
    x_breaks <- seq(min_eti_rounded, max_eti_rounded, length.out = 12)
    
    # Round each break to the nearest 5-second mark
    x_breaks <- sapply(x_breaks, function(x) round(x / 5) * 5)
    
    # Ensure we have unique breaks (in case rounding caused duplicates)
    x_breaks <- unique(x_breaks)
    
    # Create plot
    p <- ggplot(dive_df) +
      geom_line(aes(x = eti, y = depth, 
                   color = twistiness, 
                   linewidth = 1 + 2.5*twistiness),
               alpha = 0.9,
               lineend = "round", linejoin = "round") +
      scale_color_viridis_c(
        option = "plasma", 
        name = "Relative\nTwistiness",
        begin = 0.15,
        end = 1.0,
        guide = guide_colorbar(barwidth = 1, barheight = 20)
      ) +
      scale_linewidth_identity() +
      scale_y_reverse(
        limits = c(40, 0),
        breaks = seq(0, 40, by = 5)  # Integer breaks: 0, 5, 10, 15, 20, 25, 30, 35, 40
      ) +
      scale_x_continuous(
        breaks = x_breaks,
        labels = sapply(x_breaks, format_time_smart),  # Format as MM:SS or H:MM:SS
        name = "Time",
        expand = expansion(mult = c(0.0025, 0.0025)) # 0.25% padding
      ) +
      labs(
        title = sprintf("Dive %03d (%ds)", i, dive_duration_seconds),
        y = "Depth (m)",
        caption = "Color and width indicate orientation activity"
      ) +
      dark_theme
    
    # Add max depth marker using actual max depth index
    max_depth_time <- eti_data[max_depth_idx]
    p <- p + geom_point(
      data = data.frame(
        eti = max_depth_time,
        depth = depth_data[max_depth_idx]
      ),
      aes(x = eti, y = depth),
      color = "red",
      size = 4,
      inherit.aes = FALSE
    )
    
    # Add bottom phase markers using the loaded indices
    if (!is.na(bottom_start_idx) && bottom_start_idx > 0) {
      bottom_start_time <- eti_data[bottom_start_idx]
      p <- p + geom_vline(xintercept = bottom_start_time, color = "green", linetype = "dashed", alpha = 0.7)
    }
    
    if (!is.na(bottom_end_idx) && bottom_end_idx > 0) {
      bottom_end_time <- eti_data[bottom_end_idx]
      p <- p + geom_vline(xintercept = bottom_end_time, color = "yellow", linetype = "dashed", alpha = 0.7)
    }
    
    # Add improved legend for phase markers in a box
    p <- p + 
      annotate("rect", 
               xmin = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.18, 
               xmax = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.01,
               ymin = 0.1, 
               ymax = 4.0, 
               fill = "#333333", alpha = 0.7) +
      # Bottom Phase title
      annotate("text", 
               x = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.17, 
               y = 0.7, 
               label = "Bottom Phase", color = "white", hjust = 0, fontface = "bold", size = 3) +
      # Start text - indented
      annotate("text", 
               x = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.16, 
               y = 1.8, 
               label = "Start", color = "green", hjust = 0, size = 3) +
      # End text
      annotate("text", 
               x = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.09, 
               y = 1.8, 
               label = "End", color = "yellow", hjust = 0, size = 3) +
      # Deepest Point text (now white)
      annotate("text", 
               x = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.17, 
               y = 3.0, 
               label = "Deepest Point", color = "white", hjust = 0, size = 3) +
      # Red marker (now to the right of text)
      annotate("point",
               x = max(dive_df$eti) - (max(dive_df$eti) - min(dive_df$eti)) * 0.06,
               y = 3.0, 
               color = "red", size = 3)
    
    # Save plot
    output_file <- file.path(dive_frames_dir, sprintf("dive_%03d.png", i))
    ggsave(
      output_file,
      plot = p,
      width = 10,
      height = 6,
      dpi = 300,
      bg = "#1A1A1A"
    )
  }
  
  cat(sprintf("Saved %d individual dive plots to %s\n", max_dives, dive_frames_dir))
  return(dive_frames_dir)
} 