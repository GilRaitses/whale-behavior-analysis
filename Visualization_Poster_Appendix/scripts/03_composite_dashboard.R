#!/usr/bin/env Rscript

# Whale Behavior Visualization - Composite Dashboard
# Visualization #1: Composite Dashboard

create_composite_dashboard <- function(csv_data, output_path) {
  cat("Creating composite dashboard visualization...\n")
  
  df <- csv_data$data
  log_df <- csv_data$log
  
  # Select longest event for visualization
  event_durations <- log_df$eventEnd - log_df$eventStart
  selected_event_idx <- which.max(event_durations)[1]
  event <- log_df[selected_event_idx, ]
  
  # Extract data
  event_start <- event$eventStart
  event_end <- event$eventEnd
  event_data <- df[df$s >= event_start & df$s <= event_end, ]
  
  # Convert units
  sample_rate <- event_data$fs[1]
  event_data <- event_data %>%
    mutate(
      time_sec = s / sample_rate,
      pitch_deg = pitch * 180 / pi,
      roll_deg = roll * 180 / pi,
      head_deg = convert_degrees_continuous(head * 180 / pi)
    )
  
  # Calculate norm jerk
  acc_data <- as.matrix(event_data %>% select(Aw.1, Aw.2, Aw.3))
  event_data$normjerk <- calculate_normjerk(acc_data, sample_rate)
  
  # Get time range information
  start_time_seconds <- min(event_data$time_sec, na.rm = TRUE)
  end_time_seconds <- max(event_data$time_sec, na.rm = TRUE)
  
  # Create orientation plot
  prh_plot <- ggplot(event_data) +
    geom_line(aes(x = time_sec, y = pitch_deg, color = "Pitch")) +
    geom_line(aes(x = time_sec, y = roll_deg, color = "Roll")) +
    geom_line(aes(x = time_sec, y = head_deg, color = "Head")) +
    labs(title = paste("Orientation for", event$event),
          x = "Time (s)", y = "Magnitude (Degrees)") +
    theme_minimal() +
    theme(legend.position = "top") +
    scale_color_manual(values = c("Pitch" = "red", "Roll" = "green", "Head" = "blue"))
  
  # Create jerk plot
  normjerk_plot <- ggplot(event_data) +
    geom_line(aes(x = time_sec, y = normjerk, color = "Norm Jerk")) +
    labs(title = "Norm Jerk",
          x = "Time (s)", y = "Norm Jerk (m/s^3)") +
    theme_minimal() +
    theme(legend.position = "top") +
    scale_color_manual(values = c("Norm Jerk" = "purple"))
  
  # Create depth plot
  depth_plot <- ggplot(event_data) +
    geom_line(aes(x = time_sec, y = -p, color = "Depth")) +
    labs(title = "Depth Profile",
          x = "Time (s)", y = "Depth (m)") +
    theme_minimal() +
    theme(legend.position = "top") +
    scale_color_manual(values = c("Depth" = "dodgerblue"))
  
  # Add wider context view
  padding_frames <- 5 * 60 * sample_rate
  padded_start_frame <- max(event_start - padding_frames, 0)
  padded_end_frame <- min(event_end + padding_frames, max(df$s))
  
  # Extract context data
  context_data <- df %>%
    filter(s >= padded_start_frame & s <= padded_end_frame) %>%
    mutate(time_sec = s / sample_rate)
  
  # Define dive thresholds
  deep_dive_threshold <- 10.0
  shallow_dive_threshold <- 5.0
  surface_threshold <- 0.0
  
  # Label dive phases
  event_data <- event_data %>%
    mutate(
      phase = case_when(
        p >= deep_dive_threshold ~ "Deep Phase",
        p < deep_dive_threshold & p >= shallow_dive_threshold ~ "Shallow Phase",
        p >= surface_threshold ~ "Surface Phase",
        TRUE ~ NA_character_
      )
    )
  
  # Create phase points
  phase_points <- event_data %>%
    group_by(phase) %>%
    slice(1) %>%
    ungroup() %>%
    filter(!is.na(phase)) %>%
    mutate(depth = -p)
  
  # Create context view
  phase_view_plot <- ggplot(context_data) +
    geom_line(aes(x = time_sec, y = -p, color = "Depth")) +
    geom_vline(xintercept = start_time_seconds, linetype = "dashed", color = "red", size = 0.5) +
    geom_vline(xintercept = end_time_seconds, linetype = "dashed", color = "red", size = 0.5) +
    geom_hline(yintercept = -deep_dive_threshold, linetype = "dashed", color = "blue", size = 0.5) +
    geom_hline(yintercept = -shallow_dive_threshold, linetype = "dashed", color = "green", size = 0.5) +
    geom_hline(yintercept = -surface_threshold, linetype = "dashed", color = "purple", size = 0.5) +
    annotate("text", x = mean(c(start_time_seconds, end_time_seconds)), 
            y = max(-context_data$p) * 0.8, 
            label = event$event, 
            color = "blue", size = 3) +
    labs(title = "Phase Level View", x = "Time (s)", y = "Depth (m)") +
    theme_minimal() +
    theme(legend.position = "top") +
    scale_color_manual(values = c("Depth" = "dodgerblue")) +
    geom_point(data = phase_points, aes(x = time_sec, y = depth), color = "black", size = 2) +
    geom_text(data = phase_points, aes(x = time_sec, y = depth, label = phase), 
              vjust = -0.5, hjust = 1.2, color = "black", size = 3)
  
  # Combine plots
  combined_plot <- (prh_plot / normjerk_plot / depth_plot / phase_view_plot) + 
    plot_layout(ncol = 1, heights = c(2, 1, 2, 2)) +
    plot_annotation(
      title = "Early Dashboard Approach",
      subtitle = paste("Event:", event$event, "- Multiple separate panels"),
      theme = theme(plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
                   plot.subtitle = element_text(size = 12, hjust = 0.5))
    )
  
  # Save the plot
  ggsave(output_path, plot = combined_plot, width = 10, height = 15, dpi = 300)
  cat(sprintf("Saved composite dashboard to %s\n", output_path))
  return(output_path)
} 