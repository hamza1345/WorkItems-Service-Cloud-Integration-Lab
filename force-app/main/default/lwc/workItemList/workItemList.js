import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getItems from '@salesforce/apex/WorkItemController.getItems';
import markDone from '@salesforce/apex/WorkItemController.markDone';

const COLUMNS = [
    { label: 'Title', fieldName: 'Title__c', type: 'text', sortable: true },
    { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
    { label: 'Priority', fieldName: 'Priority__c', type: 'text', sortable: true },
    { label: 'Due Date', fieldName: 'Due_Date__c', type: 'date', sortable: true },
    { label: 'Owner', fieldName: 'Owner__c', type: 'text' },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View', name: 'view' },
                { label: 'Edit', name: 'edit' },
                { label: 'Mark Done', name: 'mark_done' }
            ]
        }
    }
];

const STATUS_OPTIONS = [
    { label: 'All', value: '' },
    { label: 'Open', value: 'Open' },
    { label: 'In Progress', value: 'In Progress' },
    { label: 'Blocked', value: 'Blocked' },
    { label: 'Done', value: 'Done' }
];

export default class WorkItemList extends LightningElement {
    columns = COLUMNS;
    statusOptions = STATUS_OPTIONS;
    selectedStatus = '';
    searchTerm = '';

    // Wire service - cacheable method with auto-refresh
    @wire(getItems, { 
        status: '$selectedStatus', 
        searchTerm: '$searchTerm', 
        limitSize: 50 
    })
    workItems;

    /**
     * Computed property: Check if no data available
     */
    get noData() {
        return this.workItems.data && this.workItems.data.length === 0;
    }

    /**
     * Handle status filter change
     */
    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        // Wire service automatically refreshes
    }

    /**
     * Handle search input change
     */
    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        // Wire service automatically refreshes
    }

    /**
     * Handle row actions (view, edit, mark done)
     */
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view':
                this.handleView(row.Id);
                break;
            case 'edit':
                this.handleEdit(row.Id);
                break;
            case 'mark_done':
                this.handleMarkDone(row.Id);
                break;
            default:
                break;
        }
    }

    /**
     * Navigate to record detail page
     */
    handleView(recordId) {
        // TODO: Navigate to record page
        // NavigationMixin or lightning-record-view-form
        console.log('View record:', recordId);
    }

    /**
     * Open edit modal
     */
    handleEdit(recordId) {
        // TODO: Open edit modal with workItemForm
        console.log('Edit record:', recordId);
    }

    /**
     * Mark work item as done (imperative call)
     */
    async handleMarkDone(recordId) {
        try {
            await markDone({ itemId: recordId });
            
            // Refresh wire service data
            await refreshApex(this.workItems);
            
            // Show success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Work Item marked as Done',
                    variant: 'success'
                })
            );
        } catch (error) {
            // Extract correlation ID if present
            const message = error.body?.message || 'Unknown error';
            const match = message.match(/\[Réf: (.+)\]/);
            const correlationId = match ? match[1] : null;

            // Show error toast with correlation ID
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: correlationId 
                        ? `${message}` 
                        : 'Unable to mark Work Item as Done',
                    variant: 'error',
                    mode: 'sticky'
                })
            );

            console.error('Error marking done:', error);
            if (correlationId) {
                console.error('Correlation ID:', correlationId);
            }
        }
    }
}
