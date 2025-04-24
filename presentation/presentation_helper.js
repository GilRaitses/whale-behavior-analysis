// Markdown formatting helper
document.addEventListener('DOMContentLoaded', async function() {
    const markdownContainers = document.querySelectorAll('.markdown-content');
    
    // Load and format all markdown content containers
    for (const container of markdownContainers) {
        const mdFile = container.getAttribute('data-md-file');
        try {
            const response = await fetch(mdFile);
            if (!response.ok) {
                throw new Error(`Failed to load ${mdFile}: ${response.status} ${response.statusText}`);
            }
            const mdContent = await response.text();
            const formattedHTML = formatMarkdown(mdContent);
            container.innerHTML = formattedHTML;
        } catch (error) {
            console.error('Error loading markdown:', error);
            container.innerHTML = `<div class="error-message">Failed to load content: ${error.message}</div>`;
        }
    }
    
    // Enhanced markdown formatting with proper styling
    function formatMarkdown(markdown) {
        // Handle headers
        let html = markdown
            .replace(/^# (.*$)/gm, '<h1 class="tech-header tech-header-1">$1</h1>')
            .replace(/^## (.*$)/gm, '<h2 class="tech-header tech-header-2">$1</h2>')
            .replace(/^### (.*$)/gm, '<h3 class="tech-header tech-header-3">$1</h3>')
            .replace(/^#### (.*$)/gm, '<h4 class="tech-header tech-header-4">$1</h4>');
        
        // Handle code blocks with syntax highlighting
        html = html.replace(/```([\w]*)\n([\s\S]*?)```/gm, function(match, language, code) {
            return `<pre class="code-block ${language}"><code>${encodeHTML(code.trim())}</code></pre>`;
        });
        
        // Handle inline code
        html = html.replace(/`([^`]+)`/g, '<code class="inline-code">$1</code>');
        
        // Handle lists
        html = html.replace(/^\s*[\-\*]\s+(.*$)/gm, '<li class="tech-list-item">$1</li>');
        html = html.replace(/(<li class="tech-list-item">.*<\/li>\n)+/g, '<ul class="tech-list">$&</ul>');
        
        // Handle ordered lists
        html = html.replace(/^\s*(\d+)\.\s+(.*$)/gm, '<li class="tech-ordered-list-item">$2</li>');
        html = html.replace(/(<li class="tech-ordered-list-item">.*<\/li>\n)+/g, '<ol class="tech-ordered-list">$&</ol>');
        
        // Handle emphasis
        html = html.replace(/\*\*(.*?)\*\*/g, '<strong class="tech-bold">$1</strong>');
        html = html.replace(/\*(.*?)\*/g, '<em class="tech-italic">$1</em>');
        
        // Handle links
        html = html.replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" class="tech-link" target="_blank">$1</a>');
        
        // Handle tables
        html = html.replace(/^\|(.*)\|$/gm, '<tr>$1</tr>');
        html = html.replace(/\|([^|]+)\|/g, '<td class="tech-table-cell">$1</td>');
        
        // Wrap tables with table tags
        html = html.replace(/(<tr>.*<\/tr>\n)+/g, function(match) {
            // Extract header row
            const rows = match.split('\n').filter(row => row.trim() !== '');
            if (rows.length > 0) {
                // Convert first row to header
                const headerRow = rows[0].replace(/<td class="tech-table-cell">/g, '<th class="tech-table-header">').replace(/<\/td>/g, '</th>');
                // Join all rows
                const tableContent = headerRow + '\n' + rows.slice(1).join('\n');
                return '<table class="tech-table"><thead>' + headerRow + '</thead><tbody>' + rows.slice(2).join('\n') + '</tbody></table>';
            }
            return '<table class="tech-table">' + match + '</table>';
        });
        
        // Handle paragraphs
        html = html.replace(/^([^<].*[^>])$/gm, '<p class="tech-paragraph">$1</p>');
        
        // Clean up any empty paragraphs
        html = html.replace(/<p class="tech-paragraph"><\/p>/g, '');
        
        return html;
    }
    
    // Helper to encode HTML entities
    function encodeHTML(str) {
        return str.replace(/&/g, '&amp;')
                 .replace(/</g, '&lt;')
                 .replace(/>/g, '&gt;')
                 .replace(/"/g, '&quot;')
                 .replace(/'/g, '&#039;');
    }
}); 