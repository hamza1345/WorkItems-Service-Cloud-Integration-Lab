import { LightningElement, wire, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getItems from '@salesforce/apex/WorkItemController.getItems';
import markDone from '@salesforce/apex/WorkItemController.markDone';
import { reduceErrors } from 'c/utils';

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', type: 'text', sortable: true },
    { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
    { label: 'Priority', fieldName: 'Priority__c', type: 'text', sortable: true },
    { label: 'Category', fieldName: 'Category__c', type: 'text', sortable: true },
    { label: 'Due Date', fieldName: 'Due_Date__c', type: 'date', sortable: true },
    { label: 'Completed On', fieldName: 'Completed_On__c', type: 'date', sortable: true },
    {
        type: 'button',
        typeAttributes: {
            label: 'Mark Done',
            name: 'mark_done',
            variant: 'brand',
            disabled: { fieldName: 'isCompleted' }
        }
    }
];

const STATUS_OPTIONS = [
    { label: 'All', value: '' },
    { label: 'New', value: 'New' },
    { label: 'In Progress', value: 'In Progress' },
    { label: 'Blocked', value: 'Blocked' },
    { label: 'Done', value: 'Done' }
];

const DEBOUNCE_DELAY = 300;

export default class WorkItemList extends LightningElement {
    // Columns
    columns = COLUMNS;
    statusOptions = STATUS_OPTIONS;

    // State
    items = [];
    error = '';
    isLoading = false;
    selectedStatus = '';
    searchKey = '';
    
    @api limitSize = 50;

    // Internal
    _wiredItemsResult;
    _searchTimeout;

    // Wire service - cacheable method with auto-refresh
    @wire(getItems, { 
        status: '$selectedStatus', 
        searchTerm: '$searchKey', 
        limitSize: '$limitSize'
    })
    wiredItems(result) {
        this._wiredItemsResult = result;
        
        if (result.data) {
            this.items = result.data.map(item => ({
                ...item,
                isCompleted: item.Status__c === 'Done'
            }));
            this.error = '';
        } else if (result.error) {
            this.error = reduceErrors(result.error).join(', ');
            this.items = [];
        }
    }

    /**
     * Computed: Check if items exist
     */
    get hasItems() {
        return this.items && this.items.length > 0;
    }

    /**
     * Computed: Check if no data
     */
    get noData() {
        return !this.hasItems && !this.error;
    }

    /**
     * Handle status filter change
     */
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        // Wire service automatically refreshes
    }

    /**
     * Handle search input change with debounce
     */
    handleSearchChange(event) {
        const searchValue = event.target.value;
        
        // Clear previous timeout
        if (this._searchTimeout) {
            clearTimeout(this._searchTimeout);
        }

        // Debounce: wait 300ms before updating searchKey
        this._searchTimeout = setTimeout(() => {
            this.searchKey = searchValue;
            // Wire service automatically refreshes
        }, DEBOUNCE_DELAY);
    }

    /**
     * Handle refresh button click
     */
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this._wiredItemsResult)
            .then(() => {
                this.showToast('Success', 'Data refreshed', 'success');
            })
            .catch(error => {
                this.error = reduceErrors(error).join(', ');
                this.showToast('Error', this.error, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Handle row actions (mark done)
     */
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'mark_done') {
            this.handleMarkDone(row.Id);
        }
    }

    /**
     * Mark work item as done (imperative call)
     */
    handleMarkDone(itemId) {
        this.isLoading = true;

        markDone({ workItemId: itemId })
            .then(() => {
                this.showToast('Success', 'Work Item marked as Done', 'success');
                
                // Refresh wire service data
                return refreshApex(this._wiredItemsResult);
            })
            .catch(error => {
                const errorMessage = reduceErrors(error).join(', ');
                this.error = errorMessage;
                this.showToast('Error', errorMessage, 'error');
                
                // Log for development
                console.error('Error marking done:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: variant === 'error' ? 'sticky' : 'dismissable'
            })
        );
    }
}
