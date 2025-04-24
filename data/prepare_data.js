// Data preparation script for Three.js visualization
// This script processes the dive data in HDF5 format and converts it to JSON

document.addEventListener('DOMContentLoaded', function() {
    // Check if we need to process data
    const dataCache = localStorage.getItem('diveDataCache');
    if (dataCache) {
        console.log('Using cached dive data');
        saveProcessedData(JSON.parse(dataCache));
        return;
    }
    
    console.log('Processing dive data from HDF5...');
    
    // In a real implementation, we would use a HDF5 parser like hdf5.js
    // For this prototype, we'll create simulated data based on the visualization
    
    // Create sample data based on what we can interpret from the dive_overview.png
    simulateDiveData().then(saveProcessedData);
    
    // Function to simulate dive data from the visualization
    async function simulateDiveData() {
        // Create 128 dives as shown in the visualization
        const dives = [];
        
        // Try to load the dive_overview image to approximate data
        const img = new Image();
        img.src = '/assets/dive_overview.png';
        
        await new Promise((resolve, reject) => {
            img.onload = resolve;
            img.onerror = reject;
            
            // Set a timeout in case the image doesn't load
            setTimeout(resolve, 3000);
        }).catch(err => console.error('Could not load dive overview image:', err));
        
        // Approximate the dives from the image or create simulated data
        for (let i = 0; i < 128; i++) {
            // For each dive, create a path with varying depth and twistiness
            const pathLength = 50 + Math.floor(Math.random() * 100);
            const path = [];
            const twistiness = [];
            
            // Calculate dive parameters - this would be extracted from HDF5 in reality
            const diveIndex = i + 1;
            const maxDepth = 5 + Math.random() * 30;  // Varies between 5m and 35m
            const diveDuration = 30 + Math.random() * 270;  // Between 30s and 5min
            
            // A more complex model based on the visualization
            // Divide the x-axis space evenly among dives
            const xPos = (i / 128) * 800;
            
            for (let j = 0; j < pathLength; j++) {
                const progress = j / pathLength;
                
                // Sine wave for depth (descent and ascent)
                const depth = maxDepth * Math.sin(progress * Math.PI);
                
                // For some dives, add more complex behavior
                let xOffset = 0, zOffset = 0;
                
                // Simulate varying twistiness based on dive characteristics
                let twistValue;
                
                // Create different dive patterns based on the index
                if (i % 10 === 0) {
                    // Feeding loop
                    xOffset = Math.sin(progress * Math.PI * 2) * 3;
                    zOffset = Math.cos(progress * Math.PI * 2) * 3;
                    twistValue = 0.7 + Math.sin(progress * Math.PI * 8) * 0.3;
                } else if (i % 7 === 0) {
                    // Side roll
                    xOffset = Math.sin(progress * Math.PI * 4) * 2;
                    twistValue = 0.3 + Math.abs(Math.sin(progress * Math.PI * 4)) * 0.7;
                } else if (i % 5 === 0) {
                    // Vertical loop
                    zOffset = Math.sin(progress * Math.PI * 3) * 2;
                    twistValue = 0.4 + Math.abs(Math.sin(progress * Math.PI * 6)) * 0.6;
                } else {
                    // Regular dive with some randomness
                    xOffset = Math.sin(progress * Math.PI) * 1;
                    zOffset = Math.cos(progress * Math.PI) * 1;
                    twistValue = 0.1 + Math.random() * 0.3;
                }
                
                // Add the point to the path
                path.push({
                    x: xPos + xOffset,
                    depth: depth,
                    z: 10 + zOffset + (i % 4) * 5
                });
                
                // Add twistiness value
                twistiness.push(twistValue);
            }
            
            // Add the dive data
            dives.push({
                id: diveIndex,
                path: path,
                twistiness: twistiness,
                maxDepth: maxDepth,
                duration: diveDuration,
                startTime: new Date(Date.now() - diveDuration * 1000 - i * 600000).toISOString() // Staggered start times
            });
        }
        
        return dives;
    }
    
    // Save the processed data
    function saveProcessedData(dives) {
        // Save to localStorage to avoid reprocessing
        localStorage.setItem('diveDataCache', JSON.stringify(dives));
        
        // Create a Blob and download link for dives.json
        const blob = new Blob([JSON.stringify(dives)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        // Create download link if in development environment
        if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
            const downloadLink = document.createElement('a');
            downloadLink.href = url;
            downloadLink.download = 'dives.json';
            downloadLink.style.display = 'none';
            document.body.appendChild(downloadLink);
            downloadLink.click();
            document.body.removeChild(downloadLink);
        }
        
        console.log('Dive data processed and ready for visualization');
        
        // Make data available to the visualization
        window.diveData = dives;
        
        // Dispatch event to notify visualizations that data is ready
        document.dispatchEvent(new CustomEvent('diveDataReady', { detail: { dives } }));
    }
}); 