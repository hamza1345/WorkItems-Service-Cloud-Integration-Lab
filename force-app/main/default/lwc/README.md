# Work Items - Lightning Web Components

## Vue d'ensemble

Ce dossier contient les composants LWC pour la gestion des Work Items. L'architecture suit les bonnes pratiques Salesforce avec séparation claire entre les appels **wire service** (cacheable) et **imperative** (mutations).

---

## Composants

### 1. workItemList

**Purpose**: Liste paginée des Work Items avec filtres et actions

**Features**:
- ✅ **Wire service** pour récupération automatique des données
- ✅ Filtres: Status (combobox) + Search (text)
- ✅ DataTable avec colonnes triables
- ✅ Row actions: View, Edit, Mark Done
- ✅ Auto-refresh lors de DML sur Work_Item__c
- ✅ Extraction et affichage du correlationId en cas d'erreur

**Files**:
- `workItemList.html` - Template avec lightning-card + lightning-datatable
- `workItemList.js` - Controller avec @wire getItems + imperative markDone
- `workItemList.js-meta.xml` - Metadata (exposed on App/Record/Home pages)

**Usage**:
```javascript
// Wire service - auto-refresh
@wire(getItems, { 
    status: '$selectedStatus', 
    searchTerm: '$searchTerm', 
    limitSize: 50 
})
workItems;

// Imperative call - mutations
await markDone({ itemId: recordId });
await refreshApex(this.workItems);
```

---

### 2. workItemForm

**Purpose**: Formulaire de création/édition de Work Items

**Features**:
- ✅ Mode **Create** (recordId=null) ou **Edit** (recordId provided)
- ✅ Utilise `lightning-record-edit-form` pour simplifier les operations CRUD
- ✅ Validation automatique via field-level required attributes
- ✅ Gestion d'erreurs avec extraction du correlationId
- ✅ Events personnalisés: `save`, `cancel`
- ⚠️ Code commenté pour alternative imperative avec `saveItem()`

**Files**:
- `workItemForm.html` - Template avec lightning-record-edit-form
- `workItemForm.js` - Controller avec handleSuccess/handleError
- `workItemForm.js-meta.xml` - Metadata (exposed on App/Record/Home/QuickAction)

**Usage**:
```html
<!-- Create mode -->
<c-work-item-form></c-work-item-form>

<!-- Edit mode -->
<c-work-item-form record-id={recordId}></c-work-item-form>

<!-- Listen to events -->
<c-work-item-form onsave={handleSave} oncancel={handleCancel}></c-work-item-form>
```

---

## Wire Service vs Imperative Calls

### ✅ Wire Service (cacheable=true)

**When to use**:
- **Read-only operations** (SELECT)
- Data that should **auto-refresh** on DML
- Data that can be **cached** client-side

**Example: workItemList.js**
```javascript
import { wire } from 'lwc';
import getItems from '@salesforce/apex/WorkItemController.getItems';

@wire(getItems, { 
    status: '$selectedStatus',     // Reactive property
    searchTerm: '$searchTerm',     // Reactive property
    limitSize: 50 
})
workItems; // { data, error, loading }

// Auto-refresh when:
// 1. Reactive properties change ($selectedStatus, $searchTerm)
// 2. DML occurs on Work_Item__c
// 3. refreshApex(this.workItems) is called
```

**Benefits**:
- 🚀 **Auto-refresh** on data changes
- 💾 **Client-side cache** (performance)
- 🔄 **Reactive** to property changes
- 📱 **Offline support** (Salesforce Mobile)

**Limitations**:
- ❌ Only for `@AuraEnabled(cacheable=true)` methods
- ❌ Cannot use for mutations (INSERT/UPDATE/DELETE)
- ❌ Parameters must be primitives or serializable

---

### ⚡ Imperative Calls (non-cacheable)

**When to use**:
- **Mutations** (INSERT, UPDATE, DELETE)
- **User actions** (button clicks)
- **Conditional calls** (call only when needed)

**Example: workItemList.js**
```javascript
import markDone from '@salesforce/apex/WorkItemController.markDone';
import { refreshApex } from '@salesforce/apex';

async handleMarkDone(recordId) {
    try {
        // Imperative call (mutation)
        await markDone({ itemId: recordId });
        
        // Manually refresh wire service
        await refreshApex(this.workItems);
        
        // Show success toast
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'Work Item marked as Done',
            variant: 'success'
        }));
    } catch (error) {
        // Handle error (extract correlationId if present)
        const message = error.body?.message || 'Unknown error';
        const match = message.match(/\[Réf: (.+)\]/);
        const correlationId = match ? match[1] : null;
        
        // Show error with correlationId
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
        
        console.error('Error:', error);
        if (correlationId) {
            console.error('Correlation ID:', correlationId);
        }
    }
}
```

**Benefits**:
- ✅ Full control over **when** to call
- ✅ Works with **non-cacheable** methods
- ✅ Can handle **complex logic** before/after call
- ✅ **Manual refresh** with `refreshApex()`

**Limitations**:
- ❌ No auto-refresh (must call `refreshApex()` manually)
- ❌ No client-side cache
- ❌ More boilerplate (try/catch, error handling)

---

## Error Handling with correlationId

### Pattern actuel (sans UiError intégré)

Le Controller retourne des exceptions au format:
```
"Erreur métier: {message} [{errorCode}]"
"Erreur technique: {message}"
```

**Extraction du correlationId** (future):
```javascript
catch (error) {
    const message = error.body?.message || 'Unknown error';
    
    // Extract correlationId from format: "Message [Réf: abc1-2345]"
    const match = message.match(/\[Réf: (.+)\]/);
    const correlationId = match ? match[1] : null;
    
    // Display error with correlationId
    this.errorMessage = message;
    this.correlationId = correlationId;
    
    // Log for support
    console.error('Error:', error);
    if (correlationId) {
        console.error('Correlation ID:', correlationId);
    }
}
```

### Pattern futur (avec UiError)

Une fois UiError intégré dans WorkItemController, le format sera uniforme:
```
"Message d'erreur [Réf: abc1-2345]"
```

**Exemple workItemList.js**:
```javascript
handleMarkDone(recordId) {
    markDone({ itemId: recordId })
        .then(() => {
            // Success
            refreshApex(this.workItems);
        })
        .catch(error => {
            // Extract correlationId
            const message = error.body?.message || 'Unknown error';
            const match = message.match(/\[Réf: (.+)\]/);
            const correlationId = match ? match[1] : null;
            
            // Show error toast with correlationId visible
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: correlationId 
                    ? `${message}` 
                    : 'Unable to mark Work Item as Done',
                variant: 'error',
                mode: 'sticky'
            }));
        });
}
```

**Benefits**:
- ✅ Utilisateur voit: "Erreur métier: Item overdue [Réf: abc1-2345]"
- ✅ Support peut filtrer les logs par "abc1-2345"
- ✅ Traçabilité complète UI → Controller → Service → Domain

---

## Reactive Properties

### Pattern avec $

Les propriétés précédées de `$` dans `@wire` sont **reactives** - le wire service se rafraîchit automatiquement quand elles changent.

**Example**:
```javascript
export default class WorkItemList extends LightningElement {
    selectedStatus = '';  // Reactive property
    searchTerm = '';      // Reactive property

    @wire(getItems, { 
        status: '$selectedStatus',   // $ prefix = reactive
        searchTerm: '$searchTerm'    // $ prefix = reactive
    })
    workItems;

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        // Wire service automatically calls getItems() with new status
    }
}
```

**Without $ prefix**:
```javascript
@wire(getItems, { 
    status: 'selectedStatus',   // NO $ = static value "selectedStatus"
    searchTerm: 'searchTerm'    // NO $ = static value "searchTerm"
})
workItems;
// Wire calls getItems(status="selectedStatus", searchTerm="searchTerm")
// Does NOT react to property changes
```

---

## Lightning Data Service (LDS) vs Apex

### lightning-record-edit-form (LDS)

**Used in**: `workItemForm`

**Benefits**:
- ✅ **No Apex required** for basic CRUD
- ✅ **Auto-validation** via field-level metadata
- ✅ **Auto-refresh** other components using same record
- ✅ **Offline support** (Salesforce Mobile)
- ✅ **Less code** (no try/catch, error handling simplified)

**Example**:
```html
<lightning-record-edit-form
    object-api-name="Work_Item__c"
    record-id={recordId}
    onsuccess={handleSuccess}
    onerror={handleError}
>
    <lightning-input-field field-name="Title__c" required></lightning-input-field>
    <lightning-input-field field-name="Status__c" required></lightning-input-field>
    <lightning-button type="submit" label="Save"></lightning-button>
</lightning-record-edit-form>
```

### Apex Imperative Call

**Alternative pattern**: Use `WorkItemController.saveItem()` for more control

**When to use**:
- Complex validation before save
- Need to call business logic (WorkItemService)
- Need correlationId in response
- Custom error handling

**Example (commented in workItemForm.js)**:
```javascript
async handleSubmitImperative(event) {
    event.preventDefault();
    
    const fields = event.detail.fields;
    const workItem = {
        Id: this.recordId || null,
        Title__c: fields.Title__c,
        Status__c: fields.Status__c,
        // ...
    };

    try {
        const result = await saveItem({ item: workItem });
        // Handle success
    } catch (error) {
        // Extract correlationId
        const message = error.body?.message || 'Unknown error';
        const match = message.match(/\[Réf: (.+)\]/);
        const correlationId = match ? match[1] : null;
        // Handle error
    }
}
```

---

## Testing Patterns

### Jest Tests (à créer)

**Test structure**:
```
lwc/
  workItemList/
    __tests__/
      workItemList.test.js
  workItemForm/
    __tests__/
      workItemForm.test.js
```

**Example test - workItemList.test.js**:
```javascript
import { createElement } from 'lwc';
import WorkItemList from 'c/workItemList';
import getItems from '@salesforce/apex/WorkItemController.getItems';

// Mock Apex import
jest.mock(
    '@salesforce/apex/WorkItemController.getItems',
    () => ({
        default: jest.fn()
    }),
    { virtual: true }
);

describe('c-work-item-list', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('displays work items from wire service', async () => {
        // Arrange
        const MOCK_DATA = [
            { Id: '001', Title__c: 'Test Item 1', Status__c: 'Open' },
            { Id: '002', Title__c: 'Test Item 2', Status__c: 'In Progress' }
        ];
        getItems.mockResolvedValue(MOCK_DATA);

        // Act
        const element = createElement('c-work-item-list', {
            is: WorkItemList
        });
        document.body.appendChild(element);

        // Wait for wire service
        await Promise.resolve();

        // Assert
        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeTruthy();
        expect(datatable.data).toEqual(MOCK_DATA);
    });

    it('filters by status', async () => {
        // Test status change triggers wire refresh
    });

    it('handles errors with correlationId', async () => {
        // Mock error with correlationId format
        const ERROR_MESSAGE = 'Erreur métier [Réf: abc1-2345]';
        getItems.mockRejectedValue({
            body: { message: ERROR_MESSAGE }
        });

        // Test error display with correlationId extraction
    });
});
```

---

## Deployment Checklist

### 1. Deploy Apex Classes
```bash
sf project deploy start --source-dir force-app/main/default/classes/core/WorkItemController.cls
```

### 2. Deploy LWC Components
```bash
sf project deploy start --source-dir force-app/main/default/lwc/workItemList
sf project deploy start --source-dir force-app/main/default/lwc/workItemForm
```

### 3. Add to App/Page
- Go to **Lightning App Builder**
- Drag `workItemList` onto Home page or App page
- Drag `workItemForm` onto Record page or as modal

### 4. Assign Permissions
- Ensure users have access to `WorkItemController` Apex class
- Grant CRUD/FLS on `Work_Item__c` object

---

## Architecture Diagram

```
┌──────────────────────────────────────┐
│         LWC Layer                    │
│  - workItemList (wire + imperative)  │
│  - workItemForm (LDS + imperative)   │
└────────────┬─────────────────────────┘
             │
             │ @wire getItems (cacheable)
             │ imperative markDone/saveItem
             │
┌────────────▼─────────────────────────┐
│      WorkItemController              │
│  @AuraEnabled methods                │
│  - getItems (cacheable=true)         │
│  - saveItem                          │
│  - markDone                          │
│  - getById (cacheable=true)          │
└────────────┬─────────────────────────┘
             │
┌────────────▼─────────────────────────┐
│      WorkItemService                 │
│  Business logic orchestration        │
└────────────┬─────────────────────────┘
             │
┌────────────▼─────────────────────────┐
│      WorkItemDomain                  │
│  Business rules & validations        │
└────────────┬─────────────────────────┘
             │
┌────────────▼─────────────────────────┐
│      WorkItemSelector                │
│  SOQL queries                        │
└──────────────────────────────────────┘
```

---

## Best Practices

### 1. Wire Service
- ✅ Use for read-only operations
- ✅ Use reactive properties with `$` prefix
- ✅ Handle `{ data, error, loading }` states
- ✅ Call `refreshApex()` after mutations

### 2. Imperative Calls
- ✅ Use for mutations (INSERT/UPDATE/DELETE)
- ✅ Always use try/catch
- ✅ Extract correlationId from error messages
- ✅ Show toast notifications for user feedback

### 3. Error Handling
- ✅ Display user-friendly messages
- ✅ Extract and display correlationId
- ✅ Log errors with correlationId for support
- ✅ Use `mode: 'sticky'` for errors

### 4. Performance
- ✅ Limit data returned (use limitSize parameter)
- ✅ Use wire service for caching
- ✅ Debounce search inputs (if needed)
- ✅ Use pagination for large datasets

### 5. Security
- ✅ Validate inputs in Apex Controller
- ✅ Use `with sharing` on all Apex classes
- ✅ Check CRUD/FLS permissions
- ✅ Sanitize search terms (prevent SOQL injection)

---

## Future Enhancements

### 1. Pagination
```javascript
// Add pagination controls to workItemList
currentPage = 1;
pageSize = 50;

handleNextPage() {
    this.currentPage++;
    // Refresh wire with offset
}
```

### 2. Bulk Actions
```javascript
// Add checkbox selection to datatable
selectedRows = [];

handleBulkMarkDone() {
    const itemIds = this.selectedRows.map(row => row.Id);
    // Call bulk markDone method
}
```

### 3. Real-time Updates
```javascript
// Subscribe to Platform Events for real-time updates
import { subscribe } from 'lightning/empApi';

connectedCallback() {
    subscribe('/event/Work_Item_Updated__e', -1, this.handleEvent);
}

handleEvent(event) {
    // Refresh wire service when events received
    refreshApex(this.workItems);
}
```

### 4. Advanced Filters
```javascript
// Add more filter options
filterByPriority = '';
filterByOwner = '';
filterByDateRange = { start: null, end: null };
```

---

*Document créé le 2024-12-31 dans le cadre de JOUR 5.5 - LWC Scaffolding*
