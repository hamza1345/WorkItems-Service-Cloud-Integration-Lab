# Work Items Integration Lab - Documentation détaillée

## Table des matières
1. [Vue d'ensemble](#vue-densemble)
2. [Architecture Backend](#architecture-backend)
3. [Architecture Frontend](#architecture-frontend)
4. [Framework de Logging](#framework-de-logging)
5. [Intégrations externes](#intégrations-externes)
6. [Tests et qualité](#tests-et-qualité)
7. [Déploiement](#déploiement)

---

## 1. Vue d'ensemble

Application Salesforce de gestion de Work Items avec synchronisation bidirectionnelle vers systèmes externes (SOAP/REST).

### Fonctionnalités principales
- ✅ Création/modification/suppression de Work Items
- ✅ Workflow de statuts avec validation des transitions
- ✅ Recherche et filtres avancés
- ✅ Synchronisation externe automatique (batch schedulable)
- ✅ Logging persistant avec platform events
- ✅ Interface Lightning moderne et responsive

---

## 2. Architecture Backend

### 2.1 Controller Layer
**WorkItemController.cls**
```apex
@AuraEnabled(cacheable=true)
public static List<Work_Item__c> getItems(String status, String searchTerm, Integer limitSize)

@AuraEnabled
public static Work_Item__c saveItem(Work_Item__c item)

@AuraEnabled
public static void markDone(Id workItemId)
```

**Responsabilités**:
- Validation des entrées utilisateur
- Conversion des exceptions en `AuraHandledException`
- Logging des erreurs via `ControllerLogger`
- Wrapping des résultats dans `UiError` pour le frontend

### 2.2 Service Layer
**WorkItemService.cls**

**Méthodes principales**:
- `createWorkItem()`: Insert avec validation et defaults
- `updateWorkItem()`: Update avec vérification d'existence
- `deleteWorkItem()`: Delete avec règles métier (pas de suppression si Done)
- `getItems()`: Récupération avec filtres et limites
- `markDone()`: Transition de statut spécialisée
- `enqueueExternalSync()`: Déclenche sync externe si feature flag actif

**Pattern Transaction Script**:
```apex
public void createWorkItem(Work_Item__c item) {
    Savepoint sp = Database.setSavepoint();
    try {
        // 1. Validation
        WorkItemDomain.validate(new List<Work_Item__c>{item});
        
        // 2. Business rules
        WorkItemDomain.populateDefaults(new List<Work_Item__c>{item});
        
        // 3. Persistence
        insert item;
        
        // 4. Side effects
        enqueueExternalSync(item.Id);
    } catch (Exception e) {
        Database.rollback(sp);
        throw new BusinessException('Failed to create: ' + e.getMessage());
    }
}
```

### 2.3 Selector Layer
**WorkItemSelector.cls**

**Méthodes de query**:
- `byId()`: Récupération par Id unique
- `byIds()`: Récupération bulk par Set<Id>
- `byStatus()`: Filtrage par statut
- `byCategory()`: Filtrage par catégorie
- `byExternalId()`: Lookup par External_Id__c
- `search()`: Recherche full-text avec status filter et limite
- `getOverdue()`: Items avec Due_Date__c < TODAY
- `getAllActiveWorkItems()`: Tous sauf status = Done
- `getCreatedAfter()`: Delta queries pour sync

**Pattern SOQL Builder**:
```apex
private List<Work_Item__c> queryWorkItems(String whereClause, Integer limitSize) {
    String query = 'SELECT ' + String.join(FIELDS, ', ') +
                   ' FROM Work_Item__c ' +
                   (String.isNotBlank(whereClause) ? ' WHERE ' + whereClause : '') +
                   ' ORDER BY LastModifiedDate DESC' +
                   (limitSize != null ? ' LIMIT ' + limitSize : '');
    return Database.query(query);
}
```

### 2.4 Domain Layer
**WorkItemDomain.cls**

**Règles métier**:
```apex
// Validation
- Name requis
- Status dans liste valide
- Priority dans liste valide
- Due_Date__c >= TODAY si Status = Done

// Defaults
- Status = 'New' si null
- Priority = 'Medium' si null
- Category = 'General' si null

// Business logic
- isOverdue(): Due_Date__c < TODAY && Status != 'Done'
- isDueSoon(): Due_Date__c dans 3 jours
- calculateCompletionPercentage(): % de Work Items Done
- validateStatusTransition(): Transitions autorisées
```

**Transitions de statut autorisées**:
```
New → In Progress, Blocked, Done
In Progress → Blocked, Done
Blocked → In Progress, Done
Done → (aucune transition)
```

### 2.5 Trigger Handler
**WorkItemTriggerHandler.cls**

**Contextes gérés**:
- `beforeInsert`: Validation + populateDefaults
- `beforeUpdate`: Validation transitions + set Completed_On__c
- `beforeDelete`: Empêche suppression si Status = Done
- `afterInsert`: Log création
- `afterUpdate`: Sync externe si status change + log
- `afterDelete`: Log suppression
- `afterUndelete`: Log restauration

**Bypass automation**:
```apex
if (FeatureFlags.checkPermission('Bypass_Work_Item_Automation')) {
    return; // Admin peut bypass
}
```

---

## 3. Architecture Frontend

### 3.1 workItemList (LWC)
**Fichiers**:
- `workItemList.html`: Template avec lightning-datatable
- `workItemList.js`: Controller avec @wire et méthodes d'action
- `workItemList.css`: Styles SLDS customisés
- `workItemList.js-meta.xml`: Configuration Lightning (App, Record, Home pages)

**Fonctionnalités**:
1. **Wire service** pour données réactives:
```javascript
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
    }
}
```

2. **Filtres**:
- Status combobox (All, New, In Progress, Blocked, Done)
- Search input avec debounce 300ms

3. **Actions**:
- Bouton "Mark Done" désactivé si déjà Done
- Refresh manuel avec `refreshApex()`
- Toast notifications (success/error)

4. **Datatable**:
- 7 colonnes: Name, Status, Priority, Category, Due Date, Completed On, Actions
- Sortable
- Row actions conditionnelles

### 3.2 workItemForm (LWC)
**Fichiers**:
- `workItemForm.html`: Formulaire avec lightning-input/combobox
- `workItemForm.js`: Gestion état + validation + save
- `workItemForm.css`: Layout responsive

**Modes**:
- **Create**: Tous champs éditables
- **Edit**: Edition d'un Work Item existant (prop `recordId`)

**Validation côté client**:
```javascript
validateForm() {
    const allValid = [...this.template.querySelectorAll('lightning-input')]
        .reduce((valid, input) => {
            input.reportValidity();
            return valid && input.checkValidity();
        }, true);
    
    // Validation métier supplémentaire
    if (this.workItem.Status__c === 'Done' && 
        this.workItem.Due_Date__c < new Date().toISOString()) {
        // Error
    }
    
    return allValid;
}
```

**Save flow**:
```javascript
handleSave() {
    if (!this.validateForm()) return;
    
    this.isLoading = true;
    saveItem({ item: this.workItem })
        .then(result => {
            this.showToast('Success', 'Work Item saved', 'success');
            this.dispatchEvent(new CustomEvent('save', { 
                detail: result 
            }));
        })
        .catch(error => {
            this.showToast('Error', reduceErrors(error), 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
}
```

---

## 4. Framework de Logging

### 4.1 Architecture
```
Logger (facade)
  ↓
LogContext (context holder)
  ↓
LogEntry (log record builder)
  ↓
LogSink (interface)
  ├─ DebugSink (System.debug)
  └─ PlatformEventSink (App_Log__e)
```

### 4.2 Utilisation
```apex
// Création logger
Logger logger = LoggerFactory.createLogger('WorkItemService');

// Context enrichment
LogContext.getInstance()
    .setTransactionId(Request.getCurrent().getRequestId())
    .setUserId(UserInfo.getUserId())
    .setClassName('WorkItemService')
    .setMethodName('createWorkItem');

// Logging
logger.info('Creating work item', new Map<String, Object>{
    'itemName' => item.Name,
    'category' => item.Category__c
});

// Exception logging
try {
    // business logic
} catch (Exception e) {
    logger.error('Failed to create work item', e);
    throw new BusinessException('ERR_001', 'Creation failed', e);
}
```

### 4.3 Configuration
**Custom Metadata**: `Logging_Settings__mdt`
- `Default.md`: LogLevel = INFO, Sinks = Debug,PlatformEvent
- Configurable par environnement (Dev/QA/Prod)

**Feature Flags**: `Feature_Flag__mdt`
- `persistLogs.md`: Active = true → Logs persistés en base
- Active = false → Logs en mémoire uniquement

### 4.4 Log Persistence
**Platform Event**: `App_Log__e`
```apex
App_Log__e logEvent = new App_Log__e(
    Level__c = 'ERROR',
    Message__c = 'Failed operation',
    Logger_Name__c = 'WorkItemService',
    Transaction_Id__c = 'abc123',
    User_Id__c = UserInfo.getUserId(),
    Exception_Type__c = 'BusinessException',
    Stack_Trace__c = e.getStackTraceString()
);
EventBus.publish(logEvent);
```

**Subscriber**: `App_Log_EventSubscriber`
- Consomme `App_Log__e`
- Insert dans `App_Log__c` (custom object)
- Gestion bulk (200 events/batch)
- Error handling graceful

---

## 5. Intégrations externes

### 5.1 SOAP Client
**SoapClientFacade.cls**

**Opérations**:
- `createExternalWorkItem()`: CREATE
- `updateExternalWorkItem()`: UPDATE
- `deleteExternalWorkItem()`: DELETE
- `getExternalWorkItem()`: READ
- `syncWorkItem()`: Full sync (upsert)

**SOAP Envelope**:
```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Header>
    <Authentication>
      <Username>{username}</Username>
      <Password>{password}</Password>
    </Authentication>
  </soapenv:Header>
  <soapenv:Body>
    <CreateWorkItem>
      <Name>{name}</Name>
      <Status>{status}</Status>
      <Priority>{priority}</Priority>
    </CreateWorkItem>
  </soapenv:Body>
</soapenv:Envelope>
```

**Parsing XML**:
```apex
Dom.Document doc = new Dom.Document();
doc.load(response.getBody());
Dom.XmlNode root = doc.getRootElement();
String externalId = root.getChildElement('Id', null).getText();
```

### 5.2 REST Client
**ExternalRestClient.cls**

**Features**:
- Retry logic avec exponential backoff (3 tentatives max)
- Timeout configurable (120s default)
- Authentication headers automatiques
- Support GET/POST/PUT/DELETE
- Query params encoding
- Error status code validation (200-299 = success)

**Exemple**:
```apex
ExternalRestClient client = new ExternalRestClient('https://api.example.com');
Map<String, Object> body = new Map<String, Object>{
    'name' => 'Work Item 1',
    'status' => 'New'
};
HttpResponse res = client.doPost('/workitems', body);
```

### 5.3 Sync Job
**WorkItemSyncJob.cls** (implements `Database.Batchable<sObject>, Schedulable`)

**Flow**:
1. `start()`: Query Work Items modifiés depuis dernière sync
2. `execute()`: Process batch de 200 records
   - Appel SOAP/REST pour chaque item
   - Update External_Id__c si succès
   - Log erreurs individuelles
3. `finish()`: Log résultats globaux

**Schedule**:
```apex
// Tous les jours à 2h du matin
String cronExp = '0 0 2 * * ?';
System.schedule('Daily Work Item Sync', cronExp, new WorkItemSyncJob());
```

---

## 6. Tests et qualité

### 6.1 Tests Apex

**Statistiques**:
- **Total**: 181 tests
- **Passés**: 175 (97%)
- **Échoués**: 6 (erreurs de compilation dans les tests de logging)
- **Couverture globale**: 63%

**Classes de test par catégorie**:

**Controllers** (100% coverage):
- `WorkItemControllerTest`: 10 tests
  - getItems avec filtres et search
  - saveItem insert/update
  - markDone avec validation

**Services** (67% coverage):
- `WorkItemServiceTest`: 25 tests
  - CRUD operations
  - Bulk operations (200 records)
  - Transaction rollback
  - Feature flag integration

**Selectors** (76% coverage):
- `WorkItemSelectorTest`: 26 tests
  - Query methods
  - Bulk queries
  - Search avec SOSL
  - Limite handling

**Domain** (93% coverage):
- `WorkItemDomainTest`: 13 tests
  - Validation rules
  - Business rules
  - Status transitions
  - Calculated fields

**Triggers** (100% coverage):
- `WorkItemTriggerTest`: 15 tests
  - All contexts (before/after insert/update/delete)
  - Bulk operations (200 records)
  - Bypass automation
  - Validation errors

**Integration**:
- `SoapClientFacadeTest`: 12 tests
- `ExternalRestClientTest`: 12 tests
- `WorkItemSyncJobTest`: 11 tests

**Logging**:
- `LoggerTest`: Erreurs de compilation
- `LogLevelTest`: 12 tests (100%)
- `App_Log_EventSubscriberTest`: 6 tests (76%)

**Pattern de test**:
```apex
@TestSetup
static void setupTestData() {
    List<Work_Item__c> items = new List<Work_Item__c>();
    for (Integer i = 0; i < 200; i++) {
        items.add(new Work_Item__c(
            Name = 'Test Item ' + i,
            Status__c = 'New',
            Priority__c = 'Medium',
            Category__c = 'Bug'
        ));
    }
    insert items;
}

@IsTest
static void testBulkUpdate200WorkItems() {
    // Given
    List<Work_Item__c> items = [SELECT Id FROM Work_Item__c];
    
    // When
    Test.startTest();
    for (Work_Item__c item : items) {
        item.Status__c = 'Done';
    }
    update items;
    Test.stopTest();
    
    // Then
    List<Work_Item__c> updated = [SELECT Status__c, Completed_On__c 
                                    FROM Work_Item__c];
    Assert.areEqual(200, updated.size());
    for (Work_Item__c item : updated) {
        Assert.areEqual('Done', item.Status__c);
        Assert.isNotNull(item.Completed_On__c);
    }
}
```

### 6.2 Tests Jest (LWC)

**workItemListTest.js** - 7 tests (100% passés):

1. ✅ **displays work items from wire service**
   - Vérifie rendu datatable avec données mockées
   - Validation mappage `isCompleted`

2. ✅ **displays error message when wire service fails**
   - Teste affichage erreur via wire
   - Validation format `reduceErrors()`

3. ✅ **updates wire parameters when status filter changes**
   - Change status filter
   - Vérifie re-query automatique

4. ✅ **displays no data message when items array is empty**
   - Wire emit `[]`
   - Vérifie message "No records found"

5. ✅ **marks work item as done and refreshes data**
   - Dispatch rowaction event
   - Vérifie appel `markDone()` Apex

6. ✅ **shows error toast when mark done fails**
   - Mock erreur `markDone()`
   - Vérifie gestion erreur

7. ✅ **debounces search input to avoid excessive wire calls**
   - Vérifie présence search input
   - Validation rendering

**Mocking strategy**:
```javascript
// Wire adapter mock
import { registerApexTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
const getItemsAdapter = registerApexTestWireAdapter(getItems);

// Imperative mock
jest.mock('@salesforce/apex/WorkItemController.markDone', () => ({
    default: jest.fn()
}), { virtual: true });

// refreshApex mock
jest.mock('@salesforce/apex', () => ({
    __esModule: true,
    refreshApex: jest.fn(() => Promise.resolve())
}), { virtual: true });

// Test
it('displays work items', async () => {
    const element = createElement('c-work-item-list', {
        is: WorkItemList
    });
    document.body.appendChild(element);
    
    getItemsAdapter.emit(MOCK_ITEMS);
    await flushPromises();
    
    const datatable = element.shadowRoot.querySelector('lightning-datatable');
    expect(datatable).not.toBeNull();
    expect(datatable.data).toHaveLength(2);
});
```

---

## 7. Déploiement

### 7.1 Commandes Salesforce CLI

**Deploy all**:
```bash
sf project deploy start --source-dir force-app --target-org devEdition
```

**Deploy specific components**:
```bash
# Classes only
sf project deploy start --source-dir force-app/main/default/classes

# LWC only
sf project deploy start --source-dir force-app/main/default/lwc

# Tests
sf apex run test -c -r human -w 10 --target-org devEdition
```

### 7.2 Configuration post-déploiement

1. **Assign Permission Set**: `Work_Item_Manager`
   ```bash
   sf org assign permset --name Work_Item_Manager
   ```

2. **Schedule Sync Job**:
   ```apex
   String cronExp = '0 0 2 * * ?'; // 2 AM daily
   System.schedule('Daily Work Item Sync', cronExp, new WorkItemSyncJob());
   ```

3. **Configure Feature Flags**:
   - Setup → Custom Metadata Types → Feature Flag
   - Edit `persistLogs` → Active = true

4. **Configure Logging**:
   - Setup → Custom Metadata Types → Logging Settings
   - Edit `Default` → Log Level = INFO

### 7.3 Ajout composants à Lightning Pages

**App Builder**:
1. Setup → App Builder
2. Edit "Work Items Home"
3. Ajouter `c:workItemList` en haut de page
4. Ajouter `c:workItemForm` dans sidebar
5. Save & Activate

**Record Page**:
1. Setup → Object Manager → Work Item
2. Lightning Record Pages → New
3. Ajouter `c:workItemForm` (recordId auto-passé)
4. Save & Assign to Work Item Object

---

## 8. Améliorations futures

### Priorité haute
- [ ] Corriger tests Logger/LogContext (compilation errors)
- [ ] Augmenter couverture à 75% minimum
- [ ] Implémenter Toast events dans tests LWC

### Priorité moyenne
- [ ] Ajouter pagination datatable (>2000 records)
- [ ] Implémenter cache Redis pour selectors
- [ ] Ajouter audit trail (Field History Tracking)
- [ ] Dashboard analytics avec charts

### Priorité basse
- [ ] Export CSV depuis datatable
- [ ] Bulk actions (mark done multiple items)
- [ ] Notifications push (Bell icon)
- [ ] Mobile responsive improvements

---

**Dernière mise à jour**: 31 décembre 2025  
**Version**: 1.0.0  
**Auteur**: Hamza (hamza1345)  
**Org**: amerihamza245@agentforce.com
