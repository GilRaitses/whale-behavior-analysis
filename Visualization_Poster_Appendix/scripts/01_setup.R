#!/usr/bin/env Rscript

# Whale Behavior Visualization - Setup Script
# Sets up the environment, loads packages, and creates output directories
# Visualization #: Setup (required for all visualizations)

# Set repository
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Load required packages
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("dplyr")) install.packages("dplyr")
if (!require("viridis")) install.packages("viridis")
if (!require("patchwork")) install.packages("patchwork")
if (!require("htmlwidgets")) install.packages("htmlwidgets")
if (!require("signal")) install.packages("signal")
if (!require("scales")) install.packages("scales")
if (!require("plotly")) install.packages("plotly")

# Install BiocManager if needed, then install rhdf5
if (!require("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
if (!require("rhdf5")) {
  BiocManager::install("rhdf5")
  library(rhdf5)
}

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(rhdf5)
  library(plotly)
  library(viridis)
  library(patchwork)
  library(htmlwidgets)
  library(signal)
  library(scales)
})

# Function to create output directory
create_output_dirs <- function(base_dir = "../output") {
  if (!dir.exists(base_dir)) {
    dir.create(base_dir, recursive = TRUE)
  }
  
  # Create subdirectory for individual dive frames
  dive_frames_dir <- file.path(base_dir, "03_dive_frames")
  if (!dir.exists(dive_frames_dir)) {
    dir.create(dive_frames_dir, recursive = TRUE)
  }
  
  return(list(
    base_dir = base_dir,
    dive_frames_dir = dive_frames_dir
  ))
}

# Utility functions used across multiple visualizations
convert_to_degrees <- function(radians) {
  return(radians * 180 / pi)
}

convert_degrees_continuous <- function(degrees) {
  delta_degrees <- diff(degrees)
  jumps <- which(abs(delta_degrees) > 180)
  continuous_degrees <- degrees
  
  for (jump in jumps) {
    if (delta_degrees[jump] > 180) {
      continuous_degrees[(jump + 1):length(degrees)] <- continuous_degrees[(jump + 1):length(degrees)] - 360
    } else if (delta_degrees[jump] < -180) {
      continuous_degrees[(jump + 1):length(degrees)] <- continuous_degrees[(jump + 1):length(degrees)] + 360
    }
  }
  
  return(continuous_degrees)
}

# Calculate normalized jerk from accelerometer data
calculate_normjerk <- function(acc_data, sample_rate) {
  # Ensure acc_data is a matrix with 3 columns (x, y, z)
  if (!is.matrix(acc_data) || ncol(acc_data) != 3) {
    stop("Acceleration data must be a matrix with 3 columns (x, y, z)")
  }
  
  # Calculate the derivative of each acceleration component
  dx <- c(0, diff(acc_data[, 1])) * sample_rate
  dy <- c(0, diff(acc_data[, 2])) * sample_rate
  dz <- c(0, diff(acc_data[, 3])) * sample_rate
  
  # Calculate the norm (magnitude) of the jerk
  normjerk <- sqrt(dx^2 + dy^2 + dz^2)
  
  return(normjerk)
}

# Calculate twistiness (orientation change rate) from orientation data
calculate_twistiness <- function(orientation_data, sample_rate = 1, target_length = NULL, 
                                window_size = 21, heading_weight = 2, normalize_method = "max") {
  # Check if orientation data is available
  if (is.null(orientation_data) || 
      is.null(orientation_data$pitch) || 
      is.null(orientation_data$roll) || 
      is.null(orientation_data$heading)) {
    warning("Missing orientation data for twistiness calculation")
    return(NULL)
  }
  
  # Extract orientation components
  pitch <- orientation_data$pitch
  roll <- orientation_data$roll
  heading <- orientation_data$heading
  
  # Calculate gradients (rates of change) - use sgolay filter for smoother gradients if possible
  if (length(pitch) >= 5) {
    pitch_rate <- sgolayfilt(diff(c(pitch[1], pitch)), 1, 5) * sample_rate
    roll_rate <- sgolayfilt(diff(c(roll[1], roll)), 1, 5) * sample_rate
    heading_rate <- sgolayfilt(diff(c(heading[1], heading)), 1, 5) * sample_rate
  } else {
    pitch_rate <- c(0, diff(pitch)) * sample_rate
    roll_rate <- c(0, diff(roll)) * sample_rate
    heading_rate <- c(0, diff(heading)) * sample_rate
  }
  
  # Take absolute values
  pitch_rate_norm <- abs(pitch_rate)
  roll_rate_norm <- abs(roll_rate)
  heading_rate_norm <- abs(heading_rate)
  
  # Combined metric with configurable weight on heading
  raw_twistiness <- sqrt(pitch_rate_norm^2 + roll_rate_norm^2 + heading_weight*heading_rate_norm^2)
  
  # Apply a moving average smoothing for gradual transitions
  window_size <- min(window_size, length(raw_twistiness))
  if (window_size > 1) {
    twistiness <- stats::filter(raw_twistiness, rep(1/window_size, window_size), sides = 2)
    twistiness[is.na(twistiness)] <- raw_twistiness[is.na(twistiness)]
  } else {
    twistiness <- raw_twistiness
  }
  
  # Normalize based on method
  if (normalize_method == "percentile") {
    # Normalize using percentiles (more stable for visualizations)
    p1 <- quantile(twistiness, 0.01, na.rm = TRUE)
    p99 <- quantile(twistiness, 0.99, na.rm = TRUE)
    if (p99 > p1) {
      twistiness_norm <- (twistiness - p1) / (p99 - p1)
      twistiness_norm[twistiness_norm < 0] <- 0
      twistiness_norm[twistiness_norm > 1] <- 1
    } else {
      twistiness_norm <- rep(0, length(twistiness))
    }
  } else {
    # Normalize to [0,1] using max value
    twistiness_max <- max(twistiness, na.rm = TRUE)
    if (twistiness_max > 0) {
      twistiness_norm <- twistiness / twistiness_max
    } else {
      twistiness_norm <- rep(0, length(twistiness))
    }
  }
  
  # Adjust to target length if provided
  if (!is.null(target_length)) {
    if (length(twistiness_norm) > target_length) {
      twistiness_norm <- twistiness_norm[1:target_length]
    } else if (length(twistiness_norm) < target_length) {
      # Pad with zeros if needed
      twistiness_norm <- c(twistiness_norm, rep(0, target_length - length(twistiness_norm)))
    }
  }
  
  return(twistiness_norm)
}

# Detect dives from depth data
detect_dives <- function(depth_data, min_depth = 2.0, min_duration = 10) {
  # Find regions where depth is greater than min_depth
  dive_regions <- depth_data > min_depth
  
  # Find transitions from non-dive to dive (dive start)
  dive_starts <- which(diff(c(0, dive_regions)) == 1)
  
  # Find transitions from dive to non-dive (dive end)
  dive_ends <- which(diff(c(dive_regions, 0)) == -1)
  
  # Ensure equal number of starts and ends
  n_dives <- min(length(dive_starts), length(dive_ends))
  
  if (n_dives == 0) {
    return(NULL)
  }
  
  # Create a matrix with dive start/end indices
  dive_indices <- matrix(0, nrow = 2, ncol = n_dives)
  for (i in 1:n_dives) {
    start_idx <- dive_starts[i]
    end_idx <- dive_ends[i]
    
    # Only include dives with sufficient duration
    if (end_idx - start_idx >= min_duration) {
      # Find max depth index within this dive
      depth_section <- depth_data[start_idx:end_idx]
      max_depth_idx <- start_idx + which.max(depth_section) - 1
      
      dive_indices[1, i] <- start_idx
      dive_indices[2, i] <- end_idx
    }
  }
  
  # Remove zero columns
  dive_indices <- dive_indices[, colSums(dive_indices) > 0]
  
  return(dive_indices)
}

# Calculate dive metrics including energetics
calculate_dive_metrics <- function(depth_data, dive_indices, sample_rate, acceleration_data) {
  n_dives <- ncol(dive_indices)
  
  # Initialize metrics data frame
  dive_metrics <- data.frame(
    dive_id = 1:n_dives,
    start_idx = dive_indices[1, ],
    end_idx = dive_indices[2, ],
    duration = (dive_indices[2, ] - dive_indices[1, ]) / sample_rate,
    max_depth = rep(0, n_dives),
    odba = rep(0, n_dives),
    vdba = rep(0, n_dives)
  )
  
  # Calculate metrics for each dive
  for (i in 1:n_dives) {
    start_idx <- dive_indices[1, i]
    end_idx <- dive_indices[2, i]
    
    # Extract dive data
    dive_depth <- depth_data[start_idx:end_idx]
    
    # Max depth
    dive_metrics$max_depth[i] <- max(dive_depth)
    
    # Calculate ODBA (Overall Dynamic Body Acceleration)
    if (!is.null(acceleration_data) && nrow(acceleration_data) > 0) {
      dive_acc <- acceleration_data[start_idx:end_idx, ]
      
      # ODBA: sum of absolute accelerations
      dive_metrics$odba[i] <- mean(abs(dive_acc[, 1]) + abs(dive_acc[, 2]) + abs(dive_acc[, 3]))
      
      # VDBA: vector magnitude of accelerations
      dive_metrics$vdba[i] <- mean(sqrt(dive_acc[, 1]^2 + dive_acc[, 2]^2 + dive_acc[, 3]^2))
    }
  }
  
  return(dive_metrics)
}

# Segment a dive into phases
segment_dive_phases <- function(depth_data, dive_indices, sample_rate) {
  start_idx <- dive_indices[1]
  end_idx <- dive_indices[2]
  
  # Extract dive depth data
  dive_depth <- depth_data[start_idx:end_idx]
  dive_length <- length(dive_depth)
  
  # Calculate dive duration in seconds
  dive_duration <- dive_length / sample_rate
  
  # Find maximum depth and its index
  max_depth <- max(dive_depth)
  max_depth_idx <- start_idx + which.max(dive_depth) - 1
  
  # For very short dives (less than 30 seconds), bottom phase might not be distinguishable
  if (dive_duration < 30 || dive_length < 20) {
    # For extremely short dives, the bottom phase is minimal
    phases <- list(
      bottom_start_idx = max_depth_idx,
      bottom_end_idx = max_depth_idx
    )
    return(phases)
  }
  
  # Calculate vertical velocity (depth rate of change)
  # Positive velocity = increasing depth (descending)
  # Negative velocity = decreasing depth (ascending)
  depth_diff <- c(0, diff(dive_depth))
  vert_velocity <- depth_diff * sample_rate  # in meters per second
  
  # Smooth the velocity to reduce noise
  window_size <- min(5, floor(dive_length/10))
  if (window_size > 1) {
    smooth_velocity <- stats::filter(vert_velocity, rep(1/window_size, window_size), sides = 2)
    smooth_velocity[is.na(smooth_velocity)] <- vert_velocity[is.na(smooth_velocity)]
  } else {
    smooth_velocity <- vert_velocity
  }
  
  # Define bottom phase as where depth is close to max and vertical velocity is low
  depth_threshold <- 0.85 * max_depth  # 85% of max depth
  velocity_threshold <- 0.2  # 0.2 m/s (adjust based on your data)
  
  # Identify points where animal is at bottom phase
  bottom_points <- which(
    dive_depth > depth_threshold &  # Close to max depth
    abs(smooth_velocity) < velocity_threshold  # Low vertical velocity
  )
  
  # If no bottom points are found, fall back to area around max depth
  if (length(bottom_points) == 0) {
    window_size <- max(2, floor(dive_length * 0.1))  # 10% of dive or at least 2 points
    bottom_start <- max(1, which.max(dive_depth) - window_size)
    bottom_end <- min(dive_length, which.max(dive_depth) + window_size)
    
    phases <- list(
      bottom_start_idx = start_idx + bottom_start - 1,
      bottom_end_idx = start_idx + bottom_end - 1
    )
    return(phases)
  }
  
  # Find continuous stretches of bottom points
  breaks <- which(diff(bottom_points) > 1)
  if (length(breaks) == 0) {
    # Only one continuous segment
    bottom_segments <- list(bottom_points)
  } else {
    # Multiple segments
    segment_starts <- c(1, breaks + 1)
    segment_ends <- c(breaks, length(bottom_points))
    bottom_segments <- lapply(1:length(segment_starts), function(i) {
      bottom_points[segment_starts[i]:segment_ends[i]]
    })
  }
  
  # Select the longest continuous bottom segment
  segment_lengths <- sapply(bottom_segments, length)
  longest_segment <- bottom_segments[[which.max(segment_lengths)]]
  
  # Convert to absolute indices
  bottom_start_idx <- start_idx + longest_segment[1] - 1
  bottom_end_idx <- start_idx + longest_segment[length(longest_segment)] - 1
  
  phases <- list(
    bottom_start_idx = bottom_start_idx,
    bottom_end_idx = bottom_end_idx
  )
  
  return(phases)
}

# Format time in MM:SS or H:MM:SS format (without leading zeros for hours)
format_time_smart <- function(seconds) {
  hours <- floor(seconds / 3600)
  minutes <- floor((seconds %% 3600) / 60)
  secs <- round(seconds %% 60)
  
  if (hours > 0) {
    # H:MM:SS format with no leading zeros for hours
    sprintf("%d:%02d:%02d", hours, minutes, secs)
  } else {
    # MM:SS format
    sprintf("%02d:%02d", minutes, secs)
  }
}

# Create a standardized dark theme for visualizations
create_dark_theme <- function(background_color = "#1A1A1A", text_color = "white") {
  theme(
    plot.background = element_rect(fill = background_color, color = NA),
    panel.background = element_rect(fill = background_color, color = NA),
    panel.grid.major = element_line(color = "#333333", linewidth = 0.2),
    panel.grid.minor = element_blank(),
    plot.title = element_text(color = text_color, size = 24, hjust = 0.5),
    axis.title = element_text(color = text_color, size = 16),
    axis.text = element_text(color = text_color, size = 12),
    axis.line = element_line(color = text_color),
    legend.background = element_rect(fill = background_color),
    legend.key = element_rect(fill = background_color),
    legend.title = element_text(color = text_color),
    legend.text = element_text(color = text_color),
    legend.position = "right",
    plot.caption = element_text(color = text_color, hjust = 1, size = 10),
    plot.margin = margin(t = 5, r = 10, b = 15, l = 10, unit = "pt")
  )
}

# Function to verify data paths exist
verify_data_paths <- function(csv_data_path, csv_log_path, hdf5_data_path) {
  missing_files <- c()
  
  if (!file.exists(csv_data_path)) {
    missing_files <- c(missing_files, csv_data_path)
  }
  
  if (!file.exists(csv_log_path)) {
    missing_files <- c(missing_files, csv_log_path)
  }
  
  if (!file.exists(hdf5_data_path)) {
    missing_files <- c(missing_files, hdf5_data_path)
  }
  
  if (length(missing_files) > 0) {
    stop("Missing required data files: ", paste(missing_files, collapse = ", "))
  }
  
  cat("All required data files are available.\n")
  return(TRUE)
}

# Return functions as a list to be used by other scripts
setup_env <- function() {
  # Create directories
  dirs <- create_output_dirs()
  
  return(list(
    dirs = dirs,
    utility_functions = list(
      convert_to_degrees = convert_to_degrees,
      convert_degrees_continuous = convert_degrees_continuous,
      verify_data_paths = verify_data_paths,
      calculate_normjerk = calculate_normjerk,
      calculate_twistiness = calculate_twistiness,
      detect_dives = detect_dives,
      calculate_dive_metrics = calculate_dive_metrics,
      segment_dive_phases = segment_dive_phases,
      format_time_smart = format_time_smart,
      create_dark_theme = create_dark_theme
    )
  ))
} 