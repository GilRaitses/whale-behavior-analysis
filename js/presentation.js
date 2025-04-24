document.addEventListener('DOMContentLoaded', function() {
    // Navigation highlighting
    const navLinks = document.querySelectorAll('nav a');
    const sections = document.querySelectorAll('section');
    
    // Handle section navigation and highlighting
    function highlightNavigation() {
        let scrollPosition = window.scrollY;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop - 100;
            const sectionHeight = section.offsetHeight;
            const sectionId = section.getAttribute('id');
            
            if (scrollPosition >= sectionTop && scrollPosition < sectionTop + sectionHeight) {
                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === `#${sectionId}`) {
                        link.classList.add('active');
                    }
                });
            }
        });
    }
    
    window.addEventListener('scroll', highlightNavigation);
    
    // Tab functionality
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const targetId = tab.getAttribute('data-target');
            const tabContents = document.querySelectorAll('.tab-content');
            const targetContent = document.getElementById(targetId);
            
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            
            tabContents.forEach(content => content.classList.remove('active'));
            targetContent.classList.add('active');
        });
    });
    
    // Visualization controls
    const vizButtons = document.querySelectorAll('.viz-btn');
    vizButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const vizType = btn.getAttribute('data-viz');
            loadVisualization(vizType);
            
            vizButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
        });
    });
    
    // Dive selector
    const diveSelect = document.getElementById('dive-select');
    if (diveSelect) {
        diveSelect.addEventListener('change', updateVisualization);
    }
    
    // Feature toggles
    const featureToggles = document.querySelectorAll('.feature-toggle');
    featureToggles.forEach(toggle => {
        toggle.addEventListener('click', () => {
            toggle.classList.toggle('active');
            updateVisualization();
        });
    });
    
    // Load visualization based on type and settings
    function loadVisualization(type) {
        const vizFrame = document.getElementById('viz-frame');
        const diveSelect = document.getElementById('dive-select');
        let diveId = diveSelect ? diveSelect.value : '1';
        
        // Pad the dive ID with zeros if needed
        diveId = diveId.toString().padStart(3, '0');
        
        if (type === 'overview') {
            vizFrame.src = 'dashboard/overview.html';
        } else if (type === 'metrics') {
            vizFrame.src = 'dashboard/metrics.html';
        } else if (type === 'energetics') {
            vizFrame.src = 'dashboard/energetics.html';
        } else if (type === 'dive') {
            vizFrame.src = `visualizations/dive_${diveId}.html`;
        }
    }
    
    // Update visualization based on current settings
    function updateVisualization() {
        const activeVizBtn = document.querySelector('.viz-btn.active');
        const vizType = activeVizBtn ? activeVizBtn.getAttribute('data-viz') : 'overview';
        loadVisualization(vizType);
    }
    
    // Load markdown content
    async function loadMarkdownContent() {
        const markdownContainers = document.querySelectorAll('.markdown-content');
        
        for (const container of markdownContainers) {
            const filePath = container.getAttribute('data-md-file');
            try {
                const response = await fetch(filePath);
                const text = await response.text();
                
                // Very basic markdown parsing (for a production site, use a real MD parser)
                let html = text
                    .replace(/^# (.*$)/gm, '<h1>$1</h1>')
                    .replace(/^## (.*$)/gm, '<h2>$1</h2>')
                    .replace(/^### (.*$)/gm, '<h3>$1</h3>')
                    .replace(/\*\*(.*)\*\*/gm, '<strong>$1</strong>')
                    .replace(/\*(.*)\*/gm, '<em>$1</em>')
                    .replace(/```([^`]*)```/gm, '<pre><code>$1</code></pre>');
                
                container.innerHTML = html;
            } catch (error) {
                console.error('Error loading markdown:', error);
                container.innerHTML = '<p>Error loading content</p>';
            }
        }
    }
    
    // Initialize the page
    function initPage() {
        // Set default active tab
        const defaultTab = document.querySelector('.tab');
        if (defaultTab) {
            defaultTab.click();
        }
        
        // Load initial visualization
        const defaultVizBtn = document.querySelector('.viz-btn');
        if (defaultVizBtn) {
            defaultVizBtn.click();
        } else {
            loadVisualization('overview');
        }
        
        // Load markdown content
        loadMarkdownContent();
    }
    
    // Initialize the page
    initPage();
}); 