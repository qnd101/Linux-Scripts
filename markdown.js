let lastKey = '';

window.addEventListener('keydown', (e) => {
    const scrollAmount = 100;

    switch (e.key) {
        case 'j':
            window.scrollBy({ top: scrollAmount, behavior: 'smooth' });
            break;
        case 'k':
            window.scrollBy({ top: -scrollAmount, behavior: 'smooth' });
            break;
        case 'G':
            // Shift + g: Scroll to the very bottom
            window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
            break;
        case 'g':
            // Check if this is the second 'g' in a 'gg' sequence
            if (lastKey === 'g') {
                window.scrollTo({ top: 0, behavior: 'smooth' });
                lastKey = ''; // Reset after successful sequence
            } else {
                lastKey = 'g'; // Store the first 'g'
                // Optional: Clear the 'g' after 500ms if no second 'g' is pressed
                setTimeout(() => { if (lastKey === 'g') lastKey = ''; }, 500);
            }
            return; // Exit early so 'g' is handled specifically
    }

    // Reset sequence tracker if any other key is pressed
    if (e.key !== 'g') {
        lastKey = '';
    }
});
