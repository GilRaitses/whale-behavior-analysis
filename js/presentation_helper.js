// Presentation Helper Functions
document.addEventListener('DOMContentLoaded', function() {
    // Markdown loading and formatting
    loadMarkdownContent();
    
    // Additional helper functions
    setupEventHandlers();
    setupInteractivity();
    
    // Function to handle markdown loading
    async function loadMarkdownContent() {
        const markdownContainers = document.querySelectorAll('.markdown-content');
        
        for (const container of markdownContainers) {
            const filePath = container.getAttribute('data-md-file');
            try {
                const response = await fetch(filePath);
                if (!response.ok) {
                    throw new Error(`Failed to load ${filePath}: ${response.status} ${response.statusText}`);
                }
                const text = await response.text();
                
                // Don't parse here - the proper formatting is handled by presentation/presentation_helper.js
                container.innerHTML = `<p>Loading content from ${filePath}...</p>`;
            } catch (error) {
                console.error('Error loading markdown:', error);
                container.innerHTML = `<div class="error-message">Error loading content: ${error.message}</div>`;
            }
        }
    }
    
    // Function to set up event handlers
    function setupEventHandlers() {
        // Add a global message handler for iframe interactions
        window.addEventListener('message', function(event) {
            // Handle messages from iframes
            if (event.data && event.data.type === 'diveSelected') {
                const diveNumber = event.data.diveNumber;
                updateDiveSelections(diveNumber);
            }
        });
        
        // Expose the update function globally
        window.updateDiveSelections = updateDiveSelections;
    }
    
    // Function to update all dive selectors
    function updateDiveSelections(diveNumber) {
        // Update dive selection in all relevant places
        const diveSelects = document.querySelectorAll('#dive-select, #frame-select');
        diveSelects.forEach(select => {
            select.value = diveNumber;
            
            // Trigger change event
            const event = new Event('change');
            select.dispatchEvent(event);
        });
        
        // Update the dive frame
        const selectedFrame = document.getElementById('selected-frame');
        if (selectedFrame) {
            const paddedNumber = diveNumber.toString().padStart(3, '0');
            selectedFrame.src = `assets/dive_frames/dive_${paddedNumber}.png`;
        }
        
        // If Three.js overview is active, update it too
        if (window.selectDiveInOverview) {
            window.selectDiveInOverview(diveNumber - 1); // 0-indexed in Three.js
        }
    }
    
    // Function to add interactive features
    function setupInteractivity() {
        // Make code blocks fancy
        enhanceCodeBlocks();
        
        // Handle tab interactions
        setupTabInteractions();
    }
    
    // Enhance code blocks with syntax highlighting
    function enhanceCodeBlocks() {
        document.querySelectorAll('pre code').forEach(block => {
            // Add line numbers
            const lines = block.innerHTML.split('\n');
            let numberedLines = '';
            lines.forEach((line, index) => {
                if (line.trim() !== '') {
                    numberedLines += `<div class="code-line"><span class="line-number">${index + 1}</span>${line}</div>`;
                } else {
                    numberedLines += `<div class="code-line empty"><span class="line-number">${index + 1}</span></div>`;
                }
            });
            block.innerHTML = numberedLines;
            
            // Add highlighting class
            block.parentElement.classList.add('enhanced');
        });
    }
    
    // Set up tab interactions
    function setupTabInteractions() {
        const tabSets = document.querySelectorAll('.tabs');
        
        tabSets.forEach(tabSet => {
            const tabs = tabSet.querySelectorAll('.tab');
            
            tabs.forEach(tab => {
                tab.addEventListener('click', function() {
                    // Get target content ID
                    const targetId = this.getAttribute('data-target');
                    if (!targetId) return;
                    
                    // Find tab contents container - it's the parent of the tabset's parent
                    const tabContents = tabSet.parentElement.querySelectorAll('.tab-content');
                    
                    // Deactivate all tabs and contents
                    tabs.forEach(t => t.classList.remove('active'));
                    tabContents.forEach(content => content.classList.remove('active'));
                    
                    // Activate selected tab and content
                    this.classList.add('active');
                    const targetContent = document.getElementById(targetId);
                    if (targetContent) {
                        targetContent.classList.add('active');
                    }
                });
            });
        });
    }
}); 