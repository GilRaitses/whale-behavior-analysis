/**
 * export_slides.js
 * 
 * This script extracts the modal slides from the whale behavior analysis
 * index.html file and exports them as individual HTML files.
 */

function exportSlides() {
    // Slide IDs and their corresponding export filenames
    const slides = [
        { id: 'title-slide', filename: 'slide1_title.html' },
        { id: 'problem-slide', filename: 'slide2_problem.html' },
        { id: 'solution-slide', filename: 'slide3_solution.html' },
        { id: 'data-slide', filename: 'slide4_data.html' },
        { id: 'results-slide', filename: 'slide5_dimensionality.html' },
        { id: 'challenges-slide', filename: 'slide6_architecture.html' }, 
        { id: 'validation-slide', filename: 'slide7_validation.html' },
        { id: 'plan-slide', filename: 'slide8_conclusions.html' }
    ];
    
    // CSS styles to be included in each exported slide
    const styles = `
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                margin: 0;
                padding: 0;
                color: #fff;
                background-color: #121212;
            }
            .slide {
                padding: 2rem;
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                justify-content: center;
                box-sizing: border-box;
            }
            h2 {
                font-size: 2.5rem;
                margin-bottom: 1rem;
                color: #3498db;
                border-bottom: 2px solid #3498db;
                padding-bottom: 10px;
            }
            h3 {
                color: #5dade2;
                font-size: 1.5rem;
                margin-top: 1.5rem;
                margin-bottom: 0.5rem;
            }
            p, ul, ol {
                line-height: 1.6;
                font-size: 1.2rem;
            }
            .slide-section {
                margin-bottom: 2rem;
            }
            .data-point {
                background-color: #2c3e50;
                border-left: 4px solid #3498db;
                padding: 1rem 1.5rem;
                margin-bottom: 1.5rem;
                border-radius: 0 4px 4px 0;
            }
            .highlight-box {
                background-color: #2c3e50;
                border-radius: 6px;
                padding: 1.5rem;
                margin: 1.5rem 0;
            }
            .metric-point {
                display: inline-block;
                background-color: #3498db;
                color: white;
                padding: 0.5rem 1rem;
                border-radius: 15px;
                margin-right: 1rem;
                margin-bottom: 1rem;
                font-size: 1.1rem;
            }
            .feature-tag {
                display: inline-block;
                background-color: #2c3e50;
                color: #5dade2;
                padding: 0.5rem 1rem;
                border-radius: 4px;
                margin-right: 0.8rem;
                margin-bottom: 0.8rem;
                font-size: 1rem;
                border: 1px solid #3498db;
            }
            ul, ol {
                padding-left: 2rem;
            }
            li {
                margin-bottom: 0.8rem;
            }
        </style>
    `;
    
    // Export each slide
    slides.forEach(slide => {
        const slideElement = document.getElementById(slide.id);
        
        if (slideElement) {
            // Clone the slide content
            const slideContent = slideElement.cloneNode(true);
            
            // Remove the close button
            const closeButton = slideContent.querySelector('.close-modal');
            if (closeButton) {
                closeButton.remove();
            }
            
            // Create the HTML document
            const html = `
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>${slideContent.querySelector('h2').textContent}</title>
                    ${styles}
                </head>
                <body>
                    <div class="slide">
                        ${slideContent.innerHTML}
                    </div>
                </body>
                </html>
            `;
            
            // Create a downloadable link
            const blob = new Blob([html], { type: 'text/html' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = slide.filename;
            a.click();
            
            // Clean up
            URL.revokeObjectURL(url);
        } else {
            console.error(`Slide element with ID "${slide.id}" not found.`);
        }
    });
    
    console.log('All slides exported!');
}

// Export function to global scope
window.exportSlides = exportSlides; 