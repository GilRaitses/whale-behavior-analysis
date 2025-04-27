#!/usr/bin/env Rscript

# Whale Behavior Visualization - Hierarchical 3D Visualization
# Simplified version that exits if data is missing

format_time_smart <- function(time_sec) {
  if (is.na(time_sec)) return("N/A")
  
  hours <- floor(time_sec / 3600)
  minutes <- floor((time_sec %% 3600) / 60)
  seconds <- round(time_sec %% 60)
  
  if (hours > 0) {
    return(sprintf("%d:%02d:%02d", hours, minutes, seconds))
  } else {
    return(sprintf("%02d:%02d", minutes, seconds))
  }
}

create_hierarchical_visualization <- function(hdf5_data, output_path) {
  cat("Starting hierarchical visualization creation...\n")
  
  # Load required libraries
  library(plotly)
  library(viridisLite)
  
  # Create colorscale using viridisLite - use magma instead of viridis for better contrast
  colorscale <- magma(100)
  
  # Debug and extract data
  cat("Extracting data from HDF5 file...\n")
  
  # Extract depth data - required
  if (is.null(hdf5_data$depth) || length(hdf5_data$depth) == 0) {
    cat("ERROR: Depth data is NULL or empty\n")
    return("No depth data available for visualization")
  }
  depth_data <- hdf5_data$depth
  cat("Loaded depth data, length:", length(depth_data), "\n")
  
  # Extract ETI/time data - required
  if (is.null(hdf5_data$eti) || length(hdf5_data$eti) == 0) {
    cat("ERROR: ETI data is NULL or empty\n")
    return("No ETI data available for visualization")
  }
  eti_data <- hdf5_data$eti
  cat("Loaded ETI data, length:", length(eti_data), "\n")
  
  # Extract sample rate - use default if missing
  sample_rate <- 5 # Default
  if (!is.null(hdf5_data$sample_rate) && length(hdf5_data$sample_rate) > 0) {
    sample_rate <- hdf5_data$sample_rate
  }
  cat("Using sample rate:", sample_rate, "\n")
  
  # Extract dive indices - required
  if (is.null(hdf5_data$dive_indices)) {
    cat("ERROR: Dive indices are NULL or empty\n")
    return("No dive indices available for visualization")
  }
  dive_indices <- hdf5_data$dive_indices
  
  # Handle 3xN dive indices matrix format
  if (is.matrix(dive_indices) && dim(dive_indices)[1] == 3) {
    cat("Converting 3xN dive indices to Nx2 format\n")
    dive_indices <- t(dive_indices[c(1,3),]) # Just use start and end indices
  }
  cat("Using dive indices: ", 
      ifelse(is.matrix(dive_indices), 
             paste(dim(dive_indices)[1], "dives"), 
             "single dive"), "\n")
  
  # Extract orientation data - optional
  orientation_data <- NULL
  if (!is.null(hdf5_data$orientation)) {
    orientation_data <- hdf5_data$orientation
    cat("Loaded orientation data\n")
  }
  
  # Extract acceleration data - optional
  acceleration_data <- NULL
  if (!is.null(hdf5_data$acceleration)) {
    acceleration_data <- hdf5_data$acceleration
    cat("Loaded acceleration data\n")
  }
  
  # Limit max dives to 10 for clarity
  max_dives <- 10
  
  # Set up plot
  cat("Setting up 3D plot...\n")
  
  fig <- plot_ly() %>%
    layout(
      title = list(
        text = "Whale Dive Behaviors - 3D Visualization",
        font = list(color = "white"),
        y = 0.95
      ),
      paper_bgcolor = "rgb(48, 48, 48)",
      plot_bgcolor = "rgb(48, 48, 48)",
      scene = list(
        xaxis = list(
          title = "Time (seconds from dive start)",
          showgrid = TRUE,
          gridcolor = "rgba(80, 80, 80, 0.5)",
          zeroline = TRUE,
          zerolinecolor = "rgba(255, 255, 255, 0.8)",
          titlefont = list(color = "white"),
          tickfont = list(color = "white"),
          autorange = TRUE  # Ensure proper time direction
        ),
        yaxis = list(
          title = "Dive Number",
          showgrid = TRUE,
          gridcolor = "rgba(80, 80, 80, 0.5)",
          zeroline = FALSE,
          titlefont = list(color = "white"),
          tickfont = list(color = "white"),
          autorange = TRUE  # Ensure ascending dive numbers
        ),
        zaxis = list(
          title = "Depth (meters)",
          showgrid = TRUE,
          gridcolor = "rgba(80, 80, 80, 0.5)",
          zeroline = FALSE,
          titlefont = list(color = "white"),
          tickfont = list(color = "white"),
          # Make depth show positive values going down
          autorange = "reversed"
        ),
        aspectmode = "manual",
        aspectratio = list(x = 2, y = 1, z = 1),
        camera = list(
          up = list(x = 0, y = 0, z = 1),
          center = list(x = 0, y = 0, z = 0),
          eye = list(x = -1.8, y = -1.8, z = 0.8)  # Adjusted camera position for correct orientation
        ),
        annotations = list(),
        bgcolor = "rgb(48, 48, 48)"
      )
    )
  
  # Process dives
  cat("Processing dives...\n")
  
  # Counter for number of traces added
  traces_added <- 0
  
  # Add legend entries for supplementary items (body movement, max depth) at the end
  # storing them first instead of adding them immediately
  legend_items <- list()
  
  # Keep track of legend additions
  legend_added <- FALSE
  
  # Store dive durations for reference
  dive_durations <- numeric(0)
  dive_max_depths <- numeric(0)
  
  # Process each dive
  num_dives <- if (is.matrix(dive_indices)) dim(dive_indices)[1] else 1
  num_dives <- min(num_dives, max_dives)
  
  # Pre-process to get max durations and depths for better scaling
  for (i in 1:num_dives) {
    if (is.matrix(dive_indices)) {
      dive_start <- dive_indices[i, 1]
      dive_end <- dive_indices[i, 2]
    } else {
      dive_start <- dive_indices[1]
      dive_end <- dive_indices[2]
    }
    
    if (is.na(dive_start) || is.na(dive_end) || dive_start < 1 || dive_end > length(depth_data)) {
      dive_durations[i] <- 0
      dive_max_depths[i] <- 0
      next
    }
    
    dive_depth <- depth_data[dive_start:dive_end]
    dive_time <- eti_data[dive_start:dive_end]
    
    # Calculate normalized time in seconds from dive start
    dive_durations[i] <- max(dive_time) - min(dive_time)
    dive_max_depths[i] <- max(dive_depth)
  }
  
  # Find overall maximum for scaling
  max_duration <- max(dive_durations)
  max_dive_depth <- max(dive_max_depths)
  
  cat(sprintf("Maximum dive duration: %.1f seconds, Maximum depth: %.1f meters\n", 
              max_duration, max_dive_depth))
  
  # Segment size calculation - adaptive based on dive durations
  median_duration <- median(dive_durations[dive_durations > 0])
  segment_size <- max(3, round(median_duration / 30))  # Aim for ~30 segments for median dive
  cat(sprintf("Using segment size of %d seconds\n", segment_size))
  
  # Process each dive
  for (i in 1:num_dives) {
    tryCatch({
      # Get dive start/end indices
      if (is.matrix(dive_indices)) {
        dive_start <- dive_indices[i, 1]
        dive_end <- dive_indices[i, 2]
        cat(sprintf("Processing dive %d: indices %d to %d\n", i, dive_start, dive_end))
      } else {
        # Handle case where there's only one dive as a vector
        dive_start <- dive_indices[1]
        dive_end <- dive_indices[2]
        cat(sprintf("Processing single dive: indices %d to %d\n", dive_start, dive_end))
      }
      
      # Check valid indices
      if (is.na(dive_start) || is.na(dive_end) || dive_start < 1 || dive_end > length(depth_data)) {
        cat(sprintf("WARNING: Invalid dive indices for dive %d, skipping\n", i))
        next
      }
      
      # Get data for this dive
      dive_depth <- depth_data[dive_start:dive_end]
      original_dive_time <- eti_data[dive_start:dive_end]
      
      # Normalize time to start at 0 for each dive
      dive_time <- original_dive_time - original_dive_time[1]
      
      # Find max depth index
      max_depth_idx <- which.max(dive_depth)
      
      # Calculate Y position for this dive (use consistent spacing)
      y_position <- i
      
      # Calculate twistiness if orientation data is available
      twistiness <- rep(0.5, length(dive_depth))  # Default medium activity
      if (!is.null(orientation_data) && length(orientation_data) >= dive_end) {
        # Get orientation data for this dive
        dive_orientation <- orientation_data[dive_start:dive_end]
        
        # Calculate orientation rate of change
        orientation_diff <- diff(dive_orientation)
        orientation_diff <- c(0, orientation_diff)  # Add zero for first point
        
        # Normalize to 0-1 range for coloring with improved scaling
        # Use a more robust scaling approach to avoid extreme values dominating
        abs_diffs <- abs(orientation_diff)
        
        # Use quantile-based scaling for better color distribution
        quantile_95 <- quantile(abs_diffs, 0.95, na.rm = TRUE)
        twistiness <- pmin(abs_diffs / max(quantile_95, 0.001), 1)
        
        # Smooth the twistiness values
        n_smooth <- min(9, length(twistiness))
        if (n_smooth > 2) {
          twistiness <- stats::filter(twistiness, rep(1/n_smooth, n_smooth), sides = 2)
          twistiness[is.na(twistiness)] <- 0.5  # Fill NAs with medium value
        }
      }
      
      # Add main dive path
      fig <- fig %>% add_trace(
        type = "scatter3d",
        mode = "lines",
        x = dive_time,
        y = rep(y_position, length(dive_time)),
        z = dive_depth,
        line = list(
          color = "rgba(255, 255, 255, 0.3)",
          width = 3
        ),
        name = paste("Dive", i),
        legendgroup = paste("dive", i),
        showlegend = TRUE,
        legendrank = i, # Set explicit rank for dives
        hoverinfo = "none"
      )
      traces_added <- traces_added + 1
      
      # Now add color-coded segments
      segments_added <- 0
      
      # Use time-based segmentation instead of index-based
      time_points <- seq(0, max(dive_time), by=segment_size)
      if (length(time_points) < 2) time_points <- c(0, max(dive_time))
      
      for (j in 1:(length(time_points)-1)) {
        # Find indices within this time segment
        seg_start_time <- time_points[j]
        seg_end_time <- time_points[j+1]
        
        idx_in_segment <- which(dive_time >= seg_start_time & dive_time < seg_end_time)
        
        if (length(idx_in_segment) < 2) next
        
        segment_twistiness <- mean(twistiness[idx_in_segment], na.rm=TRUE)
        
        # Get color from palette based on twistiness
        color_idx <- round(segment_twistiness * 99) + 1
        color_idx <- min(max(color_idx, 1), 100)
        color <- colorscale[color_idx]
        
        # Convert to RGB string format
        rgb_values <- col2rgb(color)
        color_str <- sprintf("rgb(%d, %d, %d)", rgb_values[1], rgb_values[2], rgb_values[3])
        
        # Store legend entries for later instead of adding them immediately
        if (!legend_added && j == 1) {
          for (level in c(0.1, 0.5, 0.9)) {
            level_idx <- round(level * 99) + 1
            level_color <- colorscale[level_idx]
            rgb_level <- col2rgb(level_color)
            level_color_str <- sprintf("rgb(%d, %d, %d)", rgb_level[1], rgb_level[2], rgb_level[3])
            
            # Store information for later
            legend_items[[paste0("movement_", level)]] <- list(
              type = "scatter3d",
              mode = "lines",
              x = c(0, 10),  # Will be set for all dives at the end
              y = c(1, 1),   # Will be set for all dives at the end
              z = c(0, 0),   # Will be set for all dives at the end
              line = list(color = level_color_str, width = 5),
              name = paste0(
                ifelse(level < 0.3, "Low", 
                       ifelse(level < 0.7, "Medium", "High")), 
                " Body Movement"
              ),
              legendgroup = "twistiness",
              showlegend = TRUE,
              legendrank = num_dives + level * 10, # Rank after dives
              hoverinfo = "none"
            )
          }
          legend_added <- TRUE
        }
        
        # Format time for hover text
        formatted_times <- sapply(
          original_dive_time[idx_in_segment],
          format_time_smart
        )
        
        # Add dive segment - Use spheres for better visualization
        fig <- fig %>% add_trace(
          type = "scatter3d",
          mode = "markers",
          x = dive_time[idx_in_segment],
          y = rep(y_position, length(idx_in_segment)),
          z = dive_depth[idx_in_segment],
          marker = list(
            color = color_str, 
            size = 4,  # Slightly smaller for more detailed view
            opacity = 0.8  # More opaque for better visibility
          ),
          name = paste("Dive", i, "Segment"),
          legendgroup = paste("dive", i),
          showlegend = FALSE,
          hoverinfo = "text",
          text = paste("Dive", i, "<br>Time from start:", 
                       round(dive_time[idx_in_segment], 1), "s<br>Depth:", 
                       round(dive_depth[idx_in_segment], 1), "m<br>Activity Level:", 
                       round(segment_twistiness, 2))
        )
        traces_added <- traces_added + 1
        segments_added <- segments_added + 1
      }
      cat(sprintf("Added %d colored segments for dive %d\n", segments_added, i))
      
      # Store max depth marker info
      tryCatch({
        max_depth_time <- dive_time[max_depth_idx]
        max_depth_value <- max(dive_depth)
        
        if (i == 1) {
          # Only add one Max Depth entry to legend, but showing first dive's data
          legend_items[["max_depth"]] <- list(
            type = "scatter3d",
            mode = "markers",
            x = max_depth_time,
            y = y_position,
            z = max_depth_value,
            marker = list(color = "red", size = 8, symbol = "diamond"),
            name = "Max Depth",
            legendgroup = "max_depth",
            showlegend = TRUE,
            legendrank = num_dives + 40, # Rank after movement indicators
            hoverinfo = "text",
            text = paste("Dive", i, "<br>Time from start:", 
                         round(max_depth_time, 1), "s<br>Max Depth:", 
                         round(max_depth_value, 1), "m")
          )
        }
        
        # Still add individual max depth markers, but don't show in legend
        fig <- fig %>% add_trace(
          type = "scatter3d",
          mode = "markers",
          x = max_depth_time,
          y = y_position,
          z = max_depth_value,
          marker = list(color = "red", size = 8, symbol = "diamond"),
          name = paste("Max Depth - Dive", i),
          legendgroup = "max_depth",
          showlegend = FALSE, # Don't show individual max depths in legend
          hoverinfo = "text",
          text = paste("Dive", i, "<br>Time from start:", 
                       round(max_depth_time, 1), "s<br>Max Depth:", 
                       round(max_depth_value, 1), "m")
        )
        traces_added <- traces_added + 1
        cat(sprintf("Added max depth marker for dive %d at %.1f seconds, %.1f meters\n", 
                    i, max_depth_time, max_depth_value))
      }, error = function(e) {
        cat("ERROR adding max depth marker:", conditionMessage(e), "\n")
      })
      
    }, error = function(e) {
      cat("ERROR processing dive", i, ":", conditionMessage(e), "\n")
    })
  }
  
  # Now add the supplementary legend items after all dives have been processed
  cat("Adding supplementary legend items...\n")
  
  # Add body movement indicators
  if (!is.null(legend_items[["movement_0.1"]])) {
    fig <- fig %>% add_trace(
      type = legend_items[["movement_0.1"]]$type,
      mode = legend_items[["movement_0.1"]]$mode,
      x = legend_items[["movement_0.1"]]$x,
      y = legend_items[["movement_0.1"]]$y,
      z = legend_items[["movement_0.1"]]$z,
      line = legend_items[["movement_0.1"]]$line,
      name = legend_items[["movement_0.1"]]$name,
      legendgroup = legend_items[["movement_0.1"]]$legendgroup,
      showlegend = legend_items[["movement_0.1"]]$showlegend,
      legendrank = legend_items[["movement_0.1"]]$legendrank,
      hoverinfo = legend_items[["movement_0.1"]]$hoverinfo
    )
    traces_added <- traces_added + 1
  }
  
  if (!is.null(legend_items[["movement_0.5"]])) {
    fig <- fig %>% add_trace(
      type = legend_items[["movement_0.5"]]$type,
      mode = legend_items[["movement_0.5"]]$mode,
      x = legend_items[["movement_0.5"]]$x,
      y = legend_items[["movement_0.5"]]$y,
      z = legend_items[["movement_0.5"]]$z,
      line = legend_items[["movement_0.5"]]$line,
      name = legend_items[["movement_0.5"]]$name,
      legendgroup = legend_items[["movement_0.5"]]$legendgroup,
      showlegend = legend_items[["movement_0.5"]]$showlegend,
      legendrank = legend_items[["movement_0.5"]]$legendrank,
      hoverinfo = legend_items[["movement_0.5"]]$hoverinfo
    )
    traces_added <- traces_added + 1
  }
  
  if (!is.null(legend_items[["movement_0.9"]])) {
    fig <- fig %>% add_trace(
      type = legend_items[["movement_0.9"]]$type,
      mode = legend_items[["movement_0.9"]]$mode,
      x = legend_items[["movement_0.9"]]$x,
      y = legend_items[["movement_0.9"]]$y,
      z = legend_items[["movement_0.9"]]$z,
      line = legend_items[["movement_0.9"]]$line,
      name = legend_items[["movement_0.9"]]$name,
      legendgroup = legend_items[["movement_0.9"]]$legendgroup,
      showlegend = legend_items[["movement_0.9"]]$showlegend,
      legendrank = legend_items[["movement_0.9"]]$legendrank,
      hoverinfo = legend_items[["movement_0.9"]]$hoverinfo
    )
    traces_added <- traces_added + 1
  }
  
  # Add max depth indicator
  if (!is.null(legend_items[["max_depth"]])) {
    fig <- fig %>% add_trace(
      type = legend_items[["max_depth"]]$type,
      mode = legend_items[["max_depth"]]$mode,
      x = legend_items[["max_depth"]]$x,
      y = legend_items[["max_depth"]]$y,
      z = legend_items[["max_depth"]]$z,
      marker = legend_items[["max_depth"]]$marker,
      name = legend_items[["max_depth"]]$name,
      legendgroup = legend_items[["max_depth"]]$legendgroup,
      showlegend = legend_items[["max_depth"]]$showlegend,
      legendrank = legend_items[["max_depth"]]$legendrank,
      hoverinfo = legend_items[["max_depth"]]$hoverinfo,
      text = legend_items[["max_depth"]]$text
    )
    traces_added <- traces_added + 1
  }
  
  # Setting up visualization
  cat("Setting up visualization...\n")
  cat(sprintf("Total traces added: %d\n", traces_added))
  
  # Set initial view to be zoomed out and properly oriented
  fig <- fig %>% layout(
    scene = list(
      dragmode = "turntable"  # Allow user to rotate the view freely
    ),
    legend = list(
      title = list(
        text = "Legend"
      ),
      x = 1.0,  # Position legend at right side
      y = 0.5,  # Center vertically
      bgcolor = "rgba(0, 0, 0, 0.6)",
      bordercolor = "rgba(255, 255, 255, 0.8)",
      font = list(
        color = "white"
      )
    ),
    width = 1200,    # Increased width
    height = 900     # Increased height
  )
  
  # Save visualization with centered layout
  cat("Saving visualization to", output_path, "...\n")
  tryCatch({
    # Save the widget normally first
    htmlwidgets::saveWidget(
      as_widget(fig), 
      output_path, 
      selfcontained = TRUE,
      libdir = NULL
    )
    
    # Create custom HTML content with centered graph and zoomed out view
    html_template <- '
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8"/>
      <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
      <style>
        html, body {
          width: 100%;
          height: 100%;
          margin: 0;
          padding: 0;
          background-color: rgb(48, 48, 48);
          overflow: hidden;
          display: flex;
          justify-content: center;
          align-items: center;
        }
        .plotly-graph-div {
          width: 100% !important;
          height: 100vh !important;
        }
        #graph-container {
          width: 100%;
          height: 100%;
          display: flex;
          justify-content: center;
          align-items: center;
        }
      </style>
    </head>
    <body>
      <div id="graph-container">
        <div id="htmlwidget-placeholder" class="plotly html-widget"></div>
      </div>
      <script type="text/javascript">
        // Extract the widget data from the original file
        
        // Set initial view
        window.onload = function() {
          var gd = document.getElementsByClassName("plotly-graph-div")[0];
          
          if (gd) {
            // Set initial view - zoomed out and oriented properly
            var init_camera = {
              up: {x: 0, y: 0, z: 1},
              center: {x: 0, y: 0, z: 0},
              eye: {x: -2.5, y: -2.5, z: 1.5}  // Adjusted for proper axis orientation
            };
            
            Plotly.relayout(gd, {"scene.camera": init_camera});
            
            // Handle window resize
            window.addEventListener("resize", function() {
              Plotly.Plots.resize(gd);
            });
          }
        };
      </script>
    </body>
    </html>
    '
    
    # Read the original HTML file to extract widget data
    original_html <- readLines(output_path)
    
    # Find widget data and script in original HTML
    widget_data_line <- grep('var htmlwidget_data', original_html)
    render_line <- grep('HTMLWidgets.renderValue', original_html)
    
    if (length(widget_data_line) > 0 && length(render_line) > 0) {
      # Extract necessary JavaScript
      widget_script <- original_html[widget_data_line:length(original_html)]
      
      # Insert the widget script into our template
      html_template <- gsub(
        "// Extract the widget data from the original file", 
        paste(widget_script, collapse = "\n"), 
        html_template
      )
      
      # Write modified HTML to file
      writeLines(html_template, output_path)
      cat("Successfully saved hierarchical visualization with custom template\n")
    } else {
      cat("WARNING: Could not extract widget data from original HTML, keeping default version\n")
    }
    
    cat(sprintf("Successfully saved hierarchical visualization to %s\n", output_path))
  }, error = function(e) {
    cat("ERROR saving visualization:", conditionMessage(e), "\n")
    # Fallback to standard saving if custom template fails
    tryCatch({
      htmlwidgets::saveWidget(as_widget(fig), output_path, selfcontained = TRUE)
      cat("Saved visualization with default template\n")
    }, error = function(e2) {
      cat("ERROR in fallback save:", conditionMessage(e2), "\n")
    })
  })
  
  return(output_path)
} 