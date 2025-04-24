// Main JavaScript for whale behavior analysis

// Wait for DOM content to load
document.addEventListener('DOMContentLoaded', function() {
    // Initialize dive frames functionality
    initFrameViewer();
    
    // Initialize smooth scrolling
    initSmoothScrolling();
});

// Dive frames viewer functionality
function initFrameViewer() {
    const frameSlider = document.getElementById('frame-slider');
    const currentFrame = document.getElementById('current-frame');
    const frameNumber = document.getElementById('frame-number');
    const prevButton = document.getElementById('prev-frame');
    const nextButton = document.getElementById('next-frame');
    const playButton = document.getElementById('play-frames');
    
    // Skip if elements don't exist (might be on a different page)
    if (!frameSlider || !currentFrame) return;
    
    let currentFrameIndex = 1;
    let isPlaying = false;
    let playInterval;
    
    function updateFrame(index) {
        currentFrameIndex = index;
        
        // Format the frame number with leading zeros
        const formattedIndex = String(index).padStart(3, '0');
        
        // Update the image source - use correct path to dive frames
        currentFrame.src = `assets/dive_frames/dive_${formattedIndex}.png`;
        
        // Update the frame number display
        frameNumber.textContent = index;
        
        // Update the slider value
        frameSlider.value = index;
    }
    
    prevButton.addEventListener('click', () => {
        if (currentFrameIndex > 1) {
            updateFrame(currentFrameIndex - 1);
        }
    });
    
    nextButton.addEventListener('click', () => {
        if (currentFrameIndex < 128) {
            updateFrame(currentFrameIndex + 1);
        }
    });
    
    frameSlider.addEventListener('input', () => {
        updateFrame(parseInt(frameSlider.value));
    });
    
    playButton.addEventListener('click', () => {
        if (isPlaying) {
            clearInterval(playInterval);
            playButton.textContent = 'Play';
            isPlaying = false;
        } else {
            playButton.textContent = 'Pause';
            isPlaying = true;
            playInterval = setInterval(() => {
                if (currentFrameIndex < 128) {
                    updateFrame(currentFrameIndex + 1);
                } else {
                    updateFrame(1);
                }
            }, 500);
        }
    });
}

// Smooth scrolling for navigation
function initSmoothScrolling() {
    document.querySelectorAll('nav a').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                window.scrollTo({
                    top: targetElement.offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// Add active class to current section in navbar
window.addEventListener('scroll', function() {
    const sections = document.querySelectorAll('section');
    const navLinks = document.querySelectorAll('nav a');
    
    let currentSection = '';
    
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        
        if (window.pageYOffset >= sectionTop - 200) {
            currentSection = '#' + section.getAttribute('id');
        }
    });
    
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === currentSection) {
            link.classList.add('active');
        }
    });
});

// Lazy loading for images
function lazyLoadImages() {
    const images = document.querySelectorAll('img[data-src]');
    
    images.forEach(img => {
        img.setAttribute('src', img.getAttribute('data-src'));
        img.onload = () => {
            img.removeAttribute('data-src');
        };
    });
}

// Check for WebGL support
function checkWebGLSupport() {
    try {
        const canvas = document.createElement('canvas');
        return !!window.WebGLRenderingContext && 
            (canvas.getContext('webgl') || canvas.getContext('experimental-webgl'));
    } catch(e) {
        return false;
    }
}

// Display fallback content if WebGL is not supported
if (!checkWebGLSupport()) {
    const webglElements = document.querySelectorAll('.webgl-content');
    webglElements.forEach(element => {
        element.innerHTML = '<div class="webgl-error">Your browser does not support WebGL, which is required for 3D visualizations. Please try a different browser or update your current one.</div>';
    });
} 