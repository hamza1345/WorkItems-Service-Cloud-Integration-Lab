/**
 * Utility function to flush all pending promises in tests
 * Useful for waiting for async operations (API calls, setTimeout, etc.) to complete
 *
 * @returns {Promise} - resolves when all promises are processed
 *
 * Example:
 *   await flushPromises();
 *   expect(element.textContent).toBe('Expected value');
 */
export const flushPromises = () => {
    return new Promise((resolve) => setImmediate(resolve));
};

/**
 * Wait for DOM updates after property changes
 * Combines flushPromises with LWC's nextCycle
 *
 * @returns {Promise} - resolves after DOM updates
 */
export const waitForDomUpdates = async () => {
    await flushPromises();
    // Additional microtask cycle for LWC reactivity
    return new Promise((resolve) => requestAnimationFrame(resolve));
};

/**
 * Helper to create mock data for testing
 *
 * @param {Object} defaults - default values
 * @param {Object} overrides - values to override defaults
 * @returns {Object} - merged object
 */
export const createMockData = (defaults = {}, overrides = {}) => {
    return { ...defaults, ...overrides };
};
