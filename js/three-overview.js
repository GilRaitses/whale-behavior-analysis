// Three.js Dive Overview Visualization
document.addEventListener('DOMContentLoaded', function() {
    // Check if the overview container exists
    const overviewContainer = document.getElementById('three-overview');
    if (!overviewContainer) return;
    
    // Set up scene
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0a0a0f);
    
    // Set up camera
    const camera = new THREE.PerspectiveCamera(75, overviewContainer.clientWidth / overviewContainer.clientHeight, 0.1, 1000);
    camera.position.set(50, 20, 100);
    
    // Set up renderer
    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(overviewContainer.clientWidth, overviewContainer.clientHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    overviewContainer.appendChild(renderer.domElement);
    
    // Add OrbitControls
    const controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.screenSpacePanning = false;
    controls.minDistance = 10;
    controls.maxDistance = 200;
    controls.maxPolarAngle = Math.PI / 2;
    
    // Add ambient light
    const ambientLight = new THREE.AmbientLight(0x404040, 1);
    scene.add(ambientLight);
    
    // Add directional light
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(1, 1, 1);
    scene.add(directionalLight);
    
    // Grid helper
    const gridHelper = new THREE.GridHelper(100, 20, 0x444444, 0x222222);
    scene.add(gridHelper);
    
    // Axes helper
    const axesHelper = new THREE.AxesHelper(5);
    scene.add(axesHelper);
    
    // Create color scale for twistiness
    const colorScale = (value) => {
        // Rainbow scale from blue (0) to red (1)
        if (value < 0.25) {
            // Blue to Cyan
            return new THREE.Color(0, value * 4, 1);
        } else if (value < 0.5) {
            // Cyan to Green
            return new THREE.Color(0, 1, 1 - (value - 0.25) * 4);
        } else if (value < 0.75) {
            // Green to Yellow
            return new THREE.Color((value - 0.5) * 4, 1, 0);
        } else {
            // Yellow to Red
            return new THREE.Color(1, 1 - (value - 0.75) * 4, 0);
        }
    };
    
    // Display dive data
    let dives = [];
    let selectedDive = null;
    let diveObjects = [];
    
    // Create three.js objects from dive data
    function createDiveObjects(divesData) {
        // Clear any existing objects
        diveObjects.forEach(obj => scene.remove(obj));
        diveObjects = [];
        
        divesData.forEach((dive, index) => {
            // Create a line geometry for the dive
            const points = dive.path.map(p => new THREE.Vector3(p.x, -p.depth, p.z));
            const geometry = new THREE.BufferGeometry().setFromPoints(points);
            
            // Create colors array for each point based on twistiness
            const colors = [];
            dive.twistiness.forEach(t => {
                const color = colorScale(t);
                colors.push(color.r, color.g, color.b);
            });
            
            // Add colors to geometry
            geometry.setAttribute('color', new THREE.Float32BufferAttribute(colors, 3));
            
            // Create line material with vertex colors
            const material = new THREE.LineBasicMaterial({ 
                vertexColors: true,
                linewidth: 2
            });
            
            // Create line and add to scene
            const line = new THREE.Line(geometry, material);
            line.userData = { diveIndex: index };
            scene.add(line);
            diveObjects.push(line);
        });
    }
    
    // Select dive
    function selectDive(index) {
        // Reset all materials
        diveObjects.forEach(obj => {
            obj.material.linewidth = 2;
            obj.material.opacity = 0.7;
            obj.material.transparent = true;
        });
        
        // Highlight selected dive
        if (index !== null && index >= 0 && index < diveObjects.length) {
            selectedDive = index;
            const selectedObj = diveObjects[index];
            selectedObj.material.linewidth = 4;
            selectedObj.material.opacity = 1;
            
            // Update selection info
            if (window.updateDiveSelector) {
                window.updateDiveSelector(index + 1); // 1-based UI index
            }
            
            // Center camera on selected dive
            const divePoints = selectedObj.geometry.attributes.position;
            const center = new THREE.Vector3();
            
            for (let i = 0; i < divePoints.count; i++) {
                center.x += divePoints.getX(i);
                center.y += divePoints.getY(i);
                center.z += divePoints.getZ(i);
            }
            
            center.divideScalar(divePoints.count);
            
            // Animate camera to position
            new TWEEN.Tween(controls.target)
                .to({ x: center.x, y: center.y, z: center.z }, 1000)
                .easing(TWEEN.Easing.Cubic.Out)
                .start();
        } else {
            selectedDive = null;
        }
    }
    
    // Handle window resize
    function onWindowResize() {
        camera.aspect = overviewContainer.clientWidth / overviewContainer.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(overviewContainer.clientWidth, overviewContainer.clientHeight);
    }
    
    window.addEventListener('resize', onWindowResize, false);
    
    // Raycaster for dive selection
    const raycaster = new THREE.Raycaster();
    raycaster.params.Line.threshold = 1;
    const mouse = new THREE.Vector2();
    
    // Mouse click to select dive
    overviewContainer.addEventListener('click', function(event) {
        // Calculate mouse position in normalized device coordinates
        const rect = renderer.domElement.getBoundingClientRect();
        mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
        
        // Raycast to find intersected dive
        raycaster.setFromCamera(mouse, camera);
        const intersects = raycaster.intersectObjects(diveObjects);
        
        if (intersects.length > 0) {
            const diveIndex = intersects[0].object.userData.diveIndex;
            selectDive(diveIndex);
        }
    });
    
    // Load dive data
    fetch('data/dives.json')
        .then(response => response.json())
        .then(data => {
            dives = data;
            createDiveObjects(dives);
            
            // Expose functions to window for external access
            window.selectDiveInOverview = selectDive;
        })
        .catch(error => {
            console.error('Error loading dive data:', error);
            
            // Create sample data for demonstration if needed
            const sampleDives = Array(128).fill().map((_, i) => {
                // Create a randomized dive path
                const pathLength = 50 + Math.floor(Math.random() * 100);
                const path = [];
                const twistiness = [];
                
                const startX = (i % 10) * 10;
                const startZ = Math.floor(i / 10) * 10;
                
                for (let j = 0; j < pathLength; j++) {
                    const progress = j / pathLength;
                    const depth = 35 * Math.sin(progress * Math.PI);
                    
                    // Add some randomness to x,z movement
                    const twist = Math.random();
                    twistiness.push(twist);
                    
                    path.push({
                        x: startX + Math.sin(progress * 10 + i) * 2,
                        depth: depth,
                        z: startZ + Math.cos(progress * 10 + i) * 2
                    });
                }
                
                return { path, twistiness };
            });
            
            dives = sampleDives;
            createDiveObjects(dives);
            
            // Expose functions to window for external access
            window.selectDiveInOverview = selectDive;
        });
    
    // Animation loop
    function animate() {
        requestAnimationFrame(animate);
        TWEEN.update();
        controls.update();
        renderer.render(scene, camera);
    }
    
    animate();
}); 