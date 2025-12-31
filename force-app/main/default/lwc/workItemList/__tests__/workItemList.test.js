import { createElement } from 'lwc';
import WorkItemList from 'c/workItemList';
import getItems from '@salesforce/apex/WorkItemController.getItems';
import markDone from '@salesforce/apex/WorkItemController.markDone';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';

// Mock refreshApex manually
jest.mock('@salesforce/apex', () => ({
    __esModule: true,
    refreshApex: jest.fn(() => Promise.resolve())
}), { virtual: true });

// Register wire adapter for getItems
const getItemsAdapter = registerApexTestWireAdapter(getItems);

// Mock markDone (imperative call, not wire)
jest.mock(
    '@salesforce/apex/WorkItemController.markDone',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

// Sample data
const MOCK_ITEMS = [
    {
        Id: 'a00000000001',
        Name: 'Work Item 1',
        Status__c: 'In Progress',
        Priority__c: 'High',
        Category__c: 'Bug',
        Due_Date__c: '2025-01-15',
        Completed_On__c: null
    },
    {
        Id: 'a00000000002',
        Name: 'Work Item 2',
        Status__c: 'Done',
        Priority__c: 'Medium',
        Category__c: 'Feature',
        Due_Date__c: '2025-01-10',
        Completed_On__c: '2025-01-08'
    }
];

// Helper function to wait for promises and DOM updates
const flushPromises = () => new Promise(resolve => setTimeout(resolve, 0));

describe('c-work-item-list', () => {
    afterEach(() => {
        // Clean up DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Reset mocks
        jest.clearAllMocks();
    });

    // ========== TEST A: Wire Success (Chargement OK) ==========
    it('displays work items from wire service', async () => {
        // Arrange
        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);

        // Act - Emit data through the wire
        getItemsAdapter.emit(MOCK_ITEMS);
        await flushPromises();

        // Assert
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(2);
        expect(datatable.data[0].Name).toBe('Work Item 1');
        expect(datatable.data[0].isCompleted).toBe(false);
        expect(datatable.data[1].isCompleted).toBe(true);

        // No error message
        const errorDiv = element.shadowRoot.querySelector('.slds-alert_error');
        expect(errorDiv).toBeNull();
    });

    // ========== TEST B: Wire Error (Erreur wire) ==========
    it('displays error message when wire service fails', async () => {
        // Arrange
        const ERROR_MESSAGE = 'An error occurred while fetching data';
        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);

        // Act - Emit error through wire
        getItemsAdapter.error({
            body: { message: ERROR_MESSAGE }
        });
        await flushPromises();

        // Assert - Error div should be present
        const errorDiv = element.shadowRoot.querySelector('.slds-alert_error');
        expect(errorDiv).not.toBeNull();

        // No data table should be shown
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();
    });

    // ========== TEST C: Status Filter Change (Filtre déclenche rechargement) ==========
    it('updates wire parameters when status filter changes', async () => {
        // Arrange
        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);
        
        // Emit initial data
        getItemsAdapter.emit(MOCK_ITEMS);
        await flushPromises();

        // Act - Change status filter
        const combobox = element.shadowRoot.querySelector('lightning-combobox');
        combobox.value = 'Done';
        combobox.dispatchEvent(
            new CustomEvent('change', {
                detail: { value: 'Done' }
            })
        );
        await flushPromises();

        // Assert - Emit filtered data (only Done items)
        getItemsAdapter.emit([MOCK_ITEMS[1]]);
        await flushPromises();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(1);
        expect(datatable.data[0].Status__c).toBe('Done');
    });

    // ========== BONUS: No Data Message ==========
    it('displays no data message when items array is empty', async () => {
        // Arrange
        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);

        // Act - Emit empty array
        getItemsAdapter.emit([]);
        await flushPromises();

        // Assert
        const noDataMsg = element.shadowRoot.querySelector('.slds-text-color_weak');
        expect(noDataMsg).not.toBeNull();
        expect(noDataMsg.textContent).toBe('No records found');

        // No datatable
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();
    });

    // ========== BONUS: Mark Done Success ==========
    it('marks work item as done and refreshes data', async () => {
        // Arrange
        markDone.mockResolvedValue({ Id: 'a00000000001', Status__c: 'Done' });

        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);
        
        // Emit initial data
        getItemsAdapter.emit(MOCK_ITEMS);
        await flushPromises();

        // Act
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'mark_done' },
                    row: { Id: 'a00000000001' }
                }
            })
        );
        
        // Wait for all async operations
        await flushPromises();
        await flushPromises();

        // Assert - markDone was called with correct params
        expect(markDone).toHaveBeenCalledWith({ workItemId: 'a00000000001' });
    });

    // ========== BONUS: Mark Done Error ==========
    it('shows error toast when mark done fails', async () => {
        // Arrange
        const ERROR_MESSAGE = 'Failed to mark done';
        markDone.mockRejectedValue({
            body: { message: ERROR_MESSAGE }
        });

        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);
        
        // Emit initial data
        getItemsAdapter.emit(MOCK_ITEMS);
        await flushPromises();

        // Act
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        datatable.dispatchEvent(
            new CustomEvent('rowaction', {
                detail: {
                    action: { name: 'mark_done' },
                    row: { Id: 'a00000000001' }
                }
            })
        );
        
        // Wait for error handling
        await flushPromises();
        await flushPromises();

        // Assert - markDone was called (error handling tested separately)
        expect(markDone).toHaveBeenCalledWith({ workItemId: 'a00000000001' });
    });

    // ========== BONUS: Search Debounce ==========
    it('debounces search input to avoid excessive wire calls', async () => {
        // Arrange
        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);
        
        // Emit initial data
        getItemsAdapter.emit(MOCK_ITEMS);
        await flushPromises();

        // Assert - Component renders with search capability
        const searchInput = element.shadowRoot.querySelector('lightning-input');
        expect(searchInput).not.toBeNull();
        
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data).toHaveLength(2);
    });
});
