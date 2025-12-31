import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveItem from '@salesforce/apex/WorkItemController.saveItem';

export default class WorkItemForm extends LightningElement {
    @api recordId; // If provided, edit mode; otherwise, create mode
    isLoading = false;
    errorMessage = '';
    correlationId = '';

    /**
     * Computed property: Card title based on mode
     */
    get cardTitle() {
        return this.recordId ? 'Edit Work Item' : 'New Work Item';
    }

    /**
     * Handle form submission
     * Note: Using lightning-record-edit-form for simplicity,
     * but could use imperative saveItem() for more control
     */
    handleSubmit(event) {
        this.isLoading = true;
        this.errorMessage = '';
        this.correlationId = '';

        // Note: lightning-record-edit-form handles the actual save
        // This is just for UI feedback
    }

    /**
     * Handle successful save
     */
    handleSuccess(event) {
        this.isLoading = false;
        const recordId = event.detail.id;

        // Show success toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: this.recordId 
                    ? 'Work Item updated successfully' 
                    : 'Work Item created successfully',
                variant: 'success'
            })
        );

        // Dispatch custom event for parent component
        this.dispatchEvent(new CustomEvent('save', {
            detail: { recordId }
        }));

        // Reset form if creating new record
        if (!this.recordId) {
            this.resetForm();
        }
    }

    /**
     * Handle save error
     */
    handleError(event) {
        this.isLoading = false;

        // Extract error message and correlation ID
        const error = event.detail;
        let message = 'An error occurred while saving';
        let correlationId = '';

        if (error && error.detail) {
            message = error.detail;
        } else if (error && error.message) {
            message = error.message;
        }

        // Extract correlation ID from message format: "Message [Réf: abc1-2345]"
        const match = message.match(/\[Réf: (.+)\]/);
        if (match) {
            correlationId = match[1];
        }

        this.errorMessage = message;
        this.correlationId = correlationId;

        // Show error toast
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error',
                mode: 'sticky'
            })
        );

        console.error('Save error:', error);
        if (correlationId) {
            console.error('Correlation ID:', correlationId);
        }
    }

    /**
     * Handle cancel button
     */
    handleCancel() {
        // Dispatch custom event for parent component
        this.dispatchEvent(new CustomEvent('cancel'));

        // Reset form
        if (!this.recordId) {
            this.resetForm();
        }
    }

    /**
     * Reset form fields
     */
    resetForm() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        this.errorMessage = '';
        this.correlationId = '';
    }

    /**
     * Alternative: Use imperative saveItem() for more control
     * Uncomment below if you want to use WorkItemController.saveItem() directly
     */
    /*
    async handleSubmitImperative(event) {
        event.preventDefault(); // Prevent default form submission
        
        const fields = event.detail.fields;
        const workItem = {
            Id: this.recordId || null,
            Title__c: fields.Title__c,
            Description__c: fields.Description__c,
            Status__c: fields.Status__c,
            Priority__c: fields.Priority__c,
            Due_Date__c: fields.Due_Date__c,
            Owner__c: fields.Owner__c
        };

        this.isLoading = true;
        this.errorMessage = '';
        this.correlationId = '';

        try {
            const result = await saveItem({ item: workItem });
            
            this.isLoading = false;
            
            // Show success toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: this.recordId ? 'Work Item updated' : 'Work Item created',
                    variant: 'success'
                })
            );

            // Dispatch save event
            this.dispatchEvent(new CustomEvent('save', {
                detail: { recordId: result.Id }
            }));

            // Reset form
            if (!this.recordId) {
                this.resetForm();
            }
        } catch (error) {
            this.isLoading = false;

            // Extract error message and correlation ID
            const message = error.body?.message || 'Unknown error';
            const match = message.match(/\[Réf: (.+)\]/);
            const correlationId = match ? match[1] : null;

            this.errorMessage = message;
            this.correlationId = correlationId;

            // Show error toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );

            console.error('Save error:', error);
            if (correlationId) {
                console.error('Correlation ID:', correlationId);
            }
        }
    }
    */
}
