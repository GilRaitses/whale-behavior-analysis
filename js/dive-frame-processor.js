// Dive Frame Processor and UI Enhancements
document.addEventListener('DOMContentLoaded', function() {
    // Dark mode toggle implementation
    setupDarkModeToggle();
    
    // Convert dropdowns to sliders
    convertToSliders();
    
    // Add heatmap overlays to dive frames
    enhanceDiveFrames();
    
    // Process Three.js visualization
    initializeThreeJsVisualization();
    
    // Function to set up the dark mode toggle
    function setupDarkModeToggle() {
        // Check if dark mode toggle already exists
        if (document.querySelector('.dark-mode-switch')) return;
        
        // Create dark mode toggle
        const darkModeSwitch = document.createElement('div');
        darkModeSwitch.className = 'dark-mode-switch';
        darkModeSwitch.innerHTML = `
            <span>Dark Mode</span>
            <div class="dark-mode-toggle"></div>
        `;
        document.body.appendChild(darkModeSwitch);
        
        // Check for user preference
        const prefersDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches;
        let darkMode = localStorage.getItem('darkMode') === 'true' || prefersDarkMode;
        
        // Set initial state
        if (darkMode) {
            document.body.classList.add('dark-mode');
        }
        
        // Toggle functionality
        darkModeSwitch.addEventListener('click', function() {
            darkMode = !darkMode;
            document.body.classList.toggle('dark-mode');
            localStorage.setItem('darkMode', darkMode);
        });
    }
    
    // Function to convert dive selection dropdowns to sliders
    function convertToSliders() {
        // Find all dive selection dropdowns
        const diveSelects = document.querySelectorAll('#dive-select, #frame-select');
        
        diveSelects.forEach(select => {
            // Get the parent container
            const container = select.parentElement;
            
            // Create slider container
            const sliderContainer = document.createElement('div');
            sliderContainer.className = 'dive-slider-container';
            
            // Create slider
            const slider = document.createElement('input');
            slider.type = 'range';
            slider.min = '1';
            slider.max = '128';
            slider.value = select.value;
            slider.className = 'dive-slider';
            
            // Create value display
            const valueDisplay = document.createElement('div');
            valueDisplay.className = 'dive-slider-value';
            valueDisplay.textContent = `Dive ${slider.value}`;
            
            // Add slider and value display to container
            sliderContainer.appendChild(slider);
            sliderContainer.appendChild(valueDisplay);
            
            // Insert after the select element
            container.insertBefore(sliderContainer, select.nextSibling);
            
            // Hide the original select
            select.style.display = 'none';
            
            // Update select when slider changes
            slider.addEventListener('input', function() {
                select.value = this.value;
                valueDisplay.textContent = `Dive ${this.value}`;
                
                // Trigger change event on select
                const event = new Event('change');
                select.dispatchEvent(event);
            });
            
            // Make slider accessible
            slider.setAttribute('aria-label', 'Select dive');
            slider.setAttribute('aria-valuemin', '1');
            slider.setAttribute('aria-valuemax', '128');
            slider.setAttribute('aria-valuenow', slider.value);
            slider.setAttribute('role', 'slider');
        });
    }
    
    // Function to enhance dive frames with heatmap overlay
    function enhanceDiveFrames() {
        // Find all frame displays
        const frameDisplays = document.querySelectorAll('.frame-display');
        
        frameDisplays.forEach(display => {
            // Get the image
            const img = display.querySelector('img');
            if (!img) return;
            
            // Create canvas for heatmap overlay
            const canvas = document.createElement('canvas');
            canvas.className = 'heatmap-canvas';
            display.appendChild(canvas);
            
            // Set up canvas context
            const ctx = canvas.getContext('2d');
            
            // Process image when loaded
            img.onload = function() {
                // Set canvas dimensions to match image
                canvas.width = img.clientWidth;
                canvas.height = img.clientHeight;
                
                // Draw heatmap based on image data
                drawHeatmapOverlay(ctx, img);
            };
            
            // If image is already loaded
            if (img.complete) {
                img.onload();
            }
        });
    }
    
    // Function to draw heatmap overlay
    function drawHeatmapOverlay(ctx, img) {
        const width = ctx.canvas.width;
        const height = ctx.canvas.height;
        
        // Create gradient for heatmap
        const gradient = ctx.createLinearGradient(0, 0, width, 0);
        gradient.addColorStop(0, 'rgba(0, 0, 255, 0.3)');    // Blue
        gradient.addColorStop(0.25, 'rgba(0, 255, 255, 0.3)'); // Cyan
        gradient.addColorStop(0.5, 'rgba(0, 255, 0, 0.3)');   // Green
        gradient.addColorStop(0.75, 'rgba(255, 255, 0, 0.3)'); // Yellow
        gradient.addColorStop(1, 'rgba(255, 0, 0, 0.3)');    // Red
        
        // Clear canvas
        ctx.clearRect(0, 0, width, height);
        
        // Get dive number from image path
        const diveMatch = img.src.match(/dive_(\d+)\.png/);
        if (!diveMatch) return;
        
        const diveNumber = parseInt(diveMatch[1]);
        
        // Simulate twistiness data based on dive number
        // In a real implementation, this would come from actual data
        simulateTwistinessOverlay(ctx, diveNumber, gradient);
    }
    
    // Function to simulate twistiness overlay
    function simulateTwistinessOverlay(ctx, diveNumber, gradient) {
        const width = ctx.canvas.width;
        const height = ctx.canvas.height;
        
        // Different patterns based on dive number
        const seed = diveNumber % 10;
        
        // Draw main path
        ctx.lineWidth = 4;
        ctx.strokeStyle = gradient;
        ctx.beginPath();
        
        // Start at middle top
        ctx.moveTo(width / 2, 0);
        
        // Create control points for bezier curve
        const cp1x = width / 2 - 150 + seed * 30;
        const cp1y = height / 3;
        const cp2x = width / 2 + 150 - seed * 30;
        const cp2y = height * 2 / 3;
        const endx = width / 2;
        const endy = height;
        
        // Draw main dive path
        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, endx, endy);
        ctx.stroke();
        
        // For some dives, add more complexity
        if (seed % 3 === 0) {
            // Add side loops
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.moveTo(width / 2, height / 3);
            ctx.bezierCurveTo(
                width / 2 - 100, height / 3 - 50,
                width / 2 - 120, height / 3 + 50,
                width / 2, height / 3 + 20
            );
            ctx.stroke();
            
            ctx.beginPath();
            ctx.moveTo(width / 2, height * 2 / 3);
            ctx.bezierCurveTo(
                width / 2 + 100, height * 2 / 3 - 50,
                width / 2 + 120, height * 2 / 3 + 50,
                width / 2, height * 2 / 3 + 20
            );
            ctx.stroke();
        }
    }
    
    // Function to initialize Three.js visualization
    function initializeThreeJsVisualization() {
        // Check if we need to add the container
        const overviewImage = document.querySelector('.overview-image img');
        if (!overviewImage) return;
        
        // Create container for Three.js
        const threeContainer = document.createElement('div');
        threeContainer.className = 'three-overview-container';
        threeContainer.innerHTML = `
            <div id="three-overview"></div>
            <div class="three-controls">
                <button id="reset-view">Reset View</button>
                <button id="toggle-animation">Animate</button>
            </div>
        `;
        
        // Insert before the image
        overviewImage.parentElement.insertBefore(threeContainer, overviewImage);
        
        // Add twistiness legend
        const legend = document.createElement('div');
        legend.className = 'twistiness-legend';
        legend.innerHTML = `
            <div class="twistiness-legend-title">Relative Twistiness</div>
            <div class="twistiness-gradient"></div>
            <div class="twistiness-labels">
                <span>Low</span>
                <span>Medium</span>
                <span>High</span>
            </div>
        `;
        
        // Insert after the Three.js container
        threeContainer.parentElement.insertBefore(legend, threeContainer.nextSibling);
    }
    
    // Expose global functions for dive selection
    window.updateDiveSelector = function(diveNumber) {
        // Update all sliders
        document.querySelectorAll('.dive-slider').forEach(slider => {
            slider.value = diveNumber;
            const valueDisplay = slider.nextElementSibling;
            if (valueDisplay && valueDisplay.classList.contains('dive-slider-value')) {
                valueDisplay.textContent = `Dive ${diveNumber}`;
            }
            
            // Update corresponding select
            const selectId = slider.parentElement.previousElementSibling.id;
            const select = document.getElementById(selectId);
            if (select) {
                select.value = diveNumber;
                
                // Trigger change event
                const event = new Event('change');
                select.dispatchEvent(event);
            }
        });
    };
}); 