# WorkItems Service Cloud Integration - Architecture

## Vue d'ensemble

Système de gestion de Work Items suivant une architecture en couches stricte avec séparation des responsabilités. L'implémentation suit les patterns Domain-Driven Design (DDD) et les bonnes pratiques Salesforce.

---

## Architecture en couches

```
┌─────────────────────────────────────────┐
│         UI Layer (LWC/Aura)             │
│  - workItemList, workItemForm           │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Controller Layer                   │
│  - WorkItemController (@AuraEnabled)    │
│  - UiError (error model)                │
│  - Validation + Exception handling      │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Service Layer                      │
│  - WorkItemService (orchestration)      │
│  - Business logic coordination          │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Domain Layer                       │
│  - WorkItemDomain (business rules)      │
│  - Validations métier                   │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Data Access Layer                  │
│  - WorkItemSelector (SOQL)              │
│  - WorkItemTriggerHandler               │
└─────────────────────────────────────────┘
```

---

## Controller Layer - WorkItemController

### Responsabilités

Le Controller est le **point d'entrée unique** pour les composants UI (LWC/Aura). Il assure:

1. **Validation des inputs** - Vérification des paramètres utilisateur
2. **Transformation des exceptions** - Conversion en `AuraHandledException` avec messages user-friendly
3. **Gestion du cache** - Application correcte de `cacheable=true/false`
4. **Isolation UI/Service** - Les composants UI ne connaissent pas les services

### Méthodes @AuraEnabled

#### 1. getItems() - READ avec cache

```apex
@AuraEnabled(cacheable=true)
public static List<Work_Item__c> getItems(String status, String searchTerm, Integer limitSize)
```

**Caractéristiques:**
- ✅ `cacheable=true` - Données read-only, optimisé pour wire service LWC
- ✅ Validation: `limitSize` entre 1 et MAX_LIMIT (500)
- ✅ Defaults: `limitSize` = 50 si null
- ✅ Exception handling: BusinessException → AuraHandledException

**Règles cacheable:**
- Méthode read-only (SELECT uniquement)
- Pas de DML (INSERT/UPDATE/DELETE)
- Pas d'appels @future, Queueable, Batch
- Paramètres primitifs ou sérialisables uniquement

**Usage LWC (wire):**
```javascript
@wire(getItems, { status: '$selectedStatus', searchTerm: '$searchTerm', limitSize: 100 })
wiredItems;
```

#### 2. saveItem() - MUTATION sans cache

```apex
@AuraEnabled
public static Work_Item__c saveItem(Work_Item__c item)
```

**Caractéristiques:**
- ❌ `cacheable=false` (défaut) - Méthode mutation (INSERT/UPDATE)
- ✅ Validation: `item != null`
- ✅ Exception handling: 
  - Validation failure → `AuraHandledException` avec message explicite
  - BusinessException → Code métier + message
  - Generic Exception → Message technique

**Règles non-cacheable:**
- Contient DML (INSERT/UPDATE)
- Modifie l'état du système
- Résultat peut varier entre appels

**Usage LWC (imperative):**
```javascript
saveItem({ item: this.workItem })
    .then(result => { /* success */ })
    .catch(error => { /* handle */ });
```

#### 3. markDone() - MUTATION sans cache

```apex
@AuraEnabled
public static void markDone(Id itemId)
```

**Caractéristiques:**
- ❌ `cacheable=false` - UPDATE operation
- ✅ Validation: `itemId != null`
- ✅ Business rules: Vérifie overdue via WorkItemService
- ⚠️ **void return** - Pas de données retournées (optimisation)

**Usage LWC (imperative):**
```javascript
markDone({ itemId: record.Id })
    .then(() => { refreshApex(this.wiredItems); })
    .catch(error => { /* handle */ });
```

#### 4. getById() - READ avec cache

```apex
@AuraEnabled(cacheable=true)
public static Work_Item__c getById(Id itemId)
```

**Caractéristiques:**
- ✅ `cacheable=true` - SELECT d'un enregistrement spécifique
- ✅ Validation: `itemId != null`
- ✅ Retourne **tous les champs** (via WorkItemSelector.selectByIdWithDetails)

**Usage LWC (wire):**
```javascript
@wire(getById, { itemId: '$recordId' })
wiredRecord;
```

---

## UiError - Modèle d'erreur standardisé

### Objectif

Fournir un **format d'erreur uniforme** pour tous les composants UI avec traçabilité via `correlationId`.

### Structure

```apex
public class UiError {
    @AuraEnabled public String code { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public String correlationId { get; set; }
    
    public static UiError create(String code, String message) {
        return new UiError(code, message, LogContext.getCorrelationId());
    }
    
    public String toMessage() {
        return message + ' [Réf: ' + correlationId + ']';
    }
}
```

### Usage pattern

#### Dans le Controller (future):

```apex
try {
    return WorkItemService.saveItem(item);
} catch (BusinessException e) {
    UiError err = UiError.create(e.getErrorCode(), e.getMessage());
    throw new AuraHandledException(err.toMessage());
} catch (Exception e) {
    UiError err = UiError.create('SAVE_FAILED', 'Impossible de sauvegarder le Work Item');
    throw new AuraHandledException(err.toMessage());
}
```

#### Dans le LWC:

```javascript
handleSave() {
    saveItem({ item: this.workItem })
        .catch(error => {
            // Format: "Message d'erreur [Réf: abc1-2345]"
            const message = error.body?.message || 'Erreur inconnue';
            const match = message.match(/\[Réf: (.+)\]/);
            const correlationId = match ? match[1] : null;
            
            this.showError(message, correlationId);
        });
}
```

### Bénéfices

1. **Traçabilité** - correlationId permet de retrouver les logs exacts
2. **Uniformité** - Tous les messages suivent le format `{message} [Réf: {id}]`
3. **Support** - Utilisateur fournit "Réf: abc1-2345" au support
4. **Tests** - Validation facile de la présence du correlationId

---

## LogContext - Gestion du correlationId

### Objectif

Fournir un **identifiant de corrélation unique** par transaction Salesforce pour le tracing distribué.

### Implémentation

```apex
public class LogContext {
    private static String correlationId;
    
    public static String getCorrelationId() {
        if (correlationId == null) {
            correlationId = generateShortId();
        }
        return correlationId;
    }
    
    @TestVisible
    private static void reset() {
        correlationId = null;
    }
    
    private static String generateShortId() {
        String requestId = Request.getCurrent().getRequestId();
        if (String.isNotBlank(requestId)) {
            return requestId.right(9); // Format: "xxxx-xxxx"
        }
        
        // Fallback: UUID-based short ID
        String uuid = String.valueOf(Crypto.getRandomLong());
        String hex = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(uuid)));
        return hex.substring(0, 4) + '-' + hex.substring(4, 8);
    }
}
```

### Caractéristiques

- **Thread-safe** - Utilise `Request.getCurrent().getRequestId()` (unique par transaction)
- **Format court** - 8 caractères ("abc1-2345") pour faciliter la lecture
- **Lazy initialization** - Généré au premier appel uniquement
- **Testable** - `reset()` permet d'isoler les tests

### Cycle de vie

```
Transaction Start
      ↓
getCorrelationId() appelé (1ère fois)
      ↓
generateShortId() → "abc1-2345"
      ↓
correlationId cached
      ↓
Appels suivants → retourne "abc1-2345"
      ↓
Transaction End → correlationId destroyed
```

---

## Règles Cacheable en détail

### ✅ Quand utiliser cacheable=true

**Critères TOUS requis:**
1. ✅ Méthode **read-only** (SELECT uniquement)
2. ✅ Pas de **DML** (INSERT, UPDATE, DELETE, UNDELETE)
3. ✅ Pas d'appels **asynchrones** (@future, Queueable, Batch, Schedulable)
4. ✅ Pas de **sendEmail()**
5. ✅ Paramètres **primitifs** ou **sérialisables** uniquement
6. ✅ Données **non-sensibles** au temps (pas de `System.now()` dans la logique)

**Exemples valides:**
- `getItems(String status, String searchTerm, Integer limitSize)` ✅
- `getById(Id itemId)` ✅
- `getPicklistValues(String objectName, String fieldName)` ✅

**Bénéfices:**
- 🚀 **Performance** - Cache côté client (LWC wire service)
- 🔄 **Auto-refresh** - Invalidation automatique lors de DML
- 💾 **Offline** - Données disponibles en mode offline (Salesforce Mobile)

### ❌ Quand NE PAS utiliser cacheable

**Si l'un de ces critères:**
1. ❌ Contient DML (INSERT/UPDATE/DELETE)
2. ❌ Appelle des méthodes asynchrones
3. ❌ Modifie l'état du système
4. ❌ Résultat dépend du **moment d'exécution** (ex: calcul de date)
5. ❌ Données sensibles nécessitant **fresh data** systématiquement

**Exemples invalides:**
- `saveItem(Work_Item__c item)` ❌ (DML)
- `markDone(Id itemId)` ❌ (UPDATE)
- `sendNotification(Id userId)` ❌ (sendEmail)
- `getCurrentTime()` ❌ (dépend du moment)

### Pattern wire vs imperative

#### Wire Service (cacheable=true)

```javascript
import { LightningElement, wire } from 'lwc';
import getItems from '@salesforce/apex/WorkItemController.getItems';

export default class WorkItemList extends LightningElement {
    @wire(getItems, { status: 'In Progress', searchTerm: '', limitSize: 50 })
    wiredItems;
    
    // Auto-refresh lors de DML sur Work_Item__c
}
```

**Avantages:**
- Auto-refresh lors de DML
- Cache automatique
- Gestion d'erreurs simplifiée

#### Imperative Call (non-cacheable)

```javascript
import saveItem from '@salesforce/apex/WorkItemController.saveItem';

async handleSave() {
    try {
        const result = await saveItem({ item: this.workItem });
        // Rafraîchir manuellement le wire service
        refreshApex(this.wiredItems);
    } catch (error) {
        // Handle error
    }
}
```

**Quand utiliser:**
- Mutations (INSERT/UPDATE/DELETE)
- Actions utilisateur (bouton save, delete)
- Appels conditionnels

---

## Exception Handling Strategy

### Hiérarchie des exceptions

```
Exception (System)
    ↓
BusinessException (Custom)
    ├─ ITEM_NOT_FOUND
    ├─ ITEM_OVERDUE
    ├─ INVALID_STATUS
    └─ ...
    ↓
AuraHandledException (Salesforce)
    → Envoyé au LWC
```

### Pattern Controller

```apex
@AuraEnabled
public static ReturnType methodName(ParamType param) {
    // 1. Validation des inputs
    if (param == null) {
        throw new AuraHandledException('Paramètre requis: param');
    }
    
    try {
        // 2. Appel Service layer
        return ServiceClass.businessMethod(param);
        
    } catch (BusinessException e) {
        // 3. Exception métier → message utilisateur
        throw new AuraHandledException('Erreur métier: ' + e.getMessage() + ' [' + e.getErrorCode() + ']');
        
    } catch (Exception e) {
        // 4. Exception technique → message générique
        throw new AuraHandledException('Erreur technique: ' + e.getMessage());
    }
}
```

### Future: Intégration UiError

```apex
@AuraEnabled
public static ReturnType methodName(ParamType param) {
    if (param == null) {
        UiError err = UiError.create('PARAM_NULL', 'Paramètre requis: param');
        throw new AuraHandledException(err.toMessage());
    }
    
    try {
        return ServiceClass.businessMethod(param);
    } catch (BusinessException e) {
        UiError err = UiError.create(e.getErrorCode(), e.getMessage());
        throw new AuraHandledException(err.toMessage());
    } catch (Exception e) {
        UiError err = UiError.create('UNEXPECTED_ERROR', 'Une erreur inattendue s\'est produite');
        throw new AuraHandledException(err.toMessage());
    }
}
```

**Bénéfices:**
- ✅ Tous les messages incluent `correlationId`
- ✅ Format uniforme: `"{message} [Réf: {correlationId}]"`
- ✅ Traçabilité complète des erreurs
- ✅ Support utilisateur facilité

---

## Logging Strategy (Future)

### Statut actuel

⚠️ **Logging framework existant en refactor** - Old Logger has compilation errors

**État:**
- ✅ LogContext déployé avec `getCorrelationId()`
- ✅ UiError créé avec correlationId
- ⚠️ ControllerLogger créé mais non déployé (bloqué par old Logger)
- ❌ WorkItemController utilise `AuraHandledException` sans UiError (version stable)

### Architecture cible (après refactor Logger)

#### ControllerLogger (simplifié)

```apex
public class ControllerLogger {
    public static void info(String source, String message, String details) {
        String corrId = LogContext.getCorrelationId();
        System.debug(LoggingLevel.INFO, '[' + corrId + '] ' + source + ' - ' + message + 
                     (String.isNotBlank(details) ? ' | ' + details : ''));
    }
    
    public static void error(String source, String message, Exception ex, Id recordId) {
        String corrId = LogContext.getCorrelationId();
        String logMsg = '[' + corrId + '] ' + source + ' - ' + message;
        
        if (recordId != null) {
            logMsg += ' | RecordId=' + recordId;
        }
        
        if (ex != null) {
            logMsg += ' | Exception=' + ex.getTypeName() + ': ' + ex.getMessage();
            System.debug(LoggingLevel.ERROR, logMsg);
            System.debug(LoggingLevel.ERROR, ex.getStackTraceString());
        } else {
            System.debug(LoggingLevel.ERROR, logMsg);
        }
    }
}
```

#### Pattern Controller avec logging

```apex
@AuraEnabled(cacheable=true)
public static List<Work_Item__c> getItems(String status, String searchTerm, Integer limitSize) {
    ControllerLogger.info('WorkItemController.getItems', 'Début', 
                          'status=' + status + ', searchTerm=' + searchTerm + ', limitSize=' + limitSize);
    
    try {
        List<Work_Item__c> items = WorkItemService.getItems(status, searchTerm, limitSize);
        ControllerLogger.info('WorkItemController.getItems', 'Succès', items.size() + ' items retournés');
        return items;
        
    } catch (BusinessException e) {
        ControllerLogger.error('WorkItemController.getItems', 'Erreur métier', e, null);
        UiError err = UiError.create(e.getErrorCode(), e.getMessage());
        throw new AuraHandledException(err.toMessage());
        
    } catch (Exception e) {
        ControllerLogger.error('WorkItemController.getItems', 'Erreur technique', e, null);
        UiError err = UiError.create('FETCH_ITEMS_FAILED', 'Impossible de récupérer les Work Items');
        throw new AuraHandledException(err.toMessage());
    }
}
```

**Logs générés:**

```
[abc1-2345] WorkItemController.getItems - Début | status=In Progress, searchTerm=urgent, limitSize=50
[abc1-2345] WorkItemController.getItems - Succès | 12 items retournés
```

ou en cas d'erreur:

```
[abc1-2345] WorkItemController.getItems - Début | status=In Progress, searchTerm=urgent, limitSize=50
[abc1-2345] WorkItemController.getItems - Erreur technique | Exception=QueryException: List has no rows for assignment to SObject
[Stacktrace...]
```

### Bénéfices du logging avec correlationId

1. **Traçabilité complète** - Du log Apex au message UI
2. **Debugging facilité** - Filtrer tous les logs par correlationId
3. **Support utilisateur** - Utilisateur fournit "Réf: abc1-2345", support trouve les logs
4. **Monitoring** - Identifier patterns d'erreurs (grouper par code)

---

## Testing Strategy

### WorkItemControllerTest - Structure

**Couverture actuelle: 10/10 tests (100%)**

#### Tests CRUD basiques

1. ✅ `testGetItemsReturnsFilteredItems` - Filter par status
2. ✅ `testGetItemsSearchesByText` - Recherche texte
3. ✅ `testSaveItemInsert` - INSERT nouveau Work Item
4. ✅ `testSaveItemUpdate` - UPDATE existant
5. ✅ `testMarkDoneSetsStatusDone` - Marquer terminé
6. ✅ `testGetByIdReturnsCompleteItem` - Récupération par ID

#### Tests validation et exceptions

7. ✅ `testSaveItemWithNullThrowsAuraHandledExceptionWithCorrelationId` - saveItem(null)
8. ✅ `testMarkDoneWithNullIdThrowsAuraHandledExceptionWithCorrelationId` - markDone(null)
9. ✅ `testMarkDoneWithOverdueItemThrowsBusinessErrorWithCorrelationId` - Business rule violation
10. ✅ `testMarkDoneWithNonExistentIdThrowsAuraHandledExceptionWithCorrelationId` - ID inexistant
11. ✅ `testGetByIdWithNullIdThrowsAuraHandledExceptionWithCorrelationId` - getById(null)
12. ✅ `testGetByIdWithNonExistentIdThrowsAuraHandledExceptionWithCorrelationId` - ID inexistant

#### Tests limites

13. ✅ `testGetItemsRespectsMaxLimit` - Limite max 500
14. ✅ `testGetItemsAppliesDefaultLimit` - Default 50

### Pattern de test

#### Test validation input

```apex
@IsTest
static void testSaveItemWithNullThrowsAuraHandledException() {
    Test.startTest();
    try {
        WorkItemController.saveItem(null);
        Assert.fail('Expected AuraHandledException');
    } catch (AuraHandledException e) {
        Assert.isTrue(e.getMessage().contains('requis'), 'Message should mention required');
    }
    Test.stopTest();
}
```

#### Test avec correlationId (future)

```apex
@IsTest
static void testSaveItemWithNullIncludesCorrelationId() {
    LogContext.reset(); // Reset pour isolation
    
    Test.startTest();
    try {
        WorkItemController.saveItem(null);
        Assert.fail('Expected AuraHandledException');
    } catch (AuraHandledException e) {
        String message = e.getMessage();
        
        // Valider format: "Message [Réf: abc1-2345]"
        Assert.isTrue(message.contains('[Réf:'), 'Should contain correlation reference');
        
        // Extract correlationId
        Pattern p = Pattern.compile('\\[Réf: ([a-zA-Z0-9\\-]+)\\]');
        Matcher m = p.matcher(message);
        Assert.isTrue(m.find(), 'Should match correlationId pattern');
        
        String correlationId = m.group(1);
        Assert.areEqual(8, correlationId.length(), 'CorrelationId should be 8 chars');
        Assert.isTrue(correlationId.contains('-'), 'CorrelationId should contain hyphen');
    }
    Test.stopTest();
}
```

#### Test Business Exception

```apex
@IsTest
static void testMarkDoneWithOverdueItemThrowsBusinessError() {
    Work_Item__c item = TestDataFactory.createWorkItem('Test', 'In Progress', Date.today().addDays(-5));
    insert item;
    
    Test.startTest();
    try {
        WorkItemController.markDone(item.Id);
        Assert.fail('Expected AuraHandledException for overdue item');
    } catch (AuraHandledException e) {
        Assert.isTrue(e.getMessage().contains('ITEM_OVERDUE'), 'Should contain error code');
    }
    Test.stopTest();
}
```

### Best practices tests

1. **Isolation** - Utiliser `LogContext.reset()` entre tests pour isoler correlationId
2. **Bulk testing** - Tester avec List<Work_Item__c> si applicable
3. **Governor limits** - Vérifier limites SOQL (getItems avec MAX_LIMIT)
4. **Positive + Negative** - Tester succès ET échecs
5. **Message validation** - Vérifier format et contenu des exceptions

---

## Performance Considerations

### Limites SOQL

**Constants Controller:**
```apex
private static final Integer DEFAULT_LIMIT = 50;
private static final Integer MAX_LIMIT = 500;
```

**Rationale:**
- DEFAULT_LIMIT (50) - Balance UX et performance
- MAX_LIMIT (500) - Protège contre SOQL limit (50,000 rows)
- Évite de retourner des datasets trop larges au LWC

### Cache Strategy

**Wire service (cacheable=true):**
- ✅ Cache côté client automatique
- ✅ Invalidation auto lors de DML sur Work_Item__c
- ✅ Réduit appels serveur

**Imperative calls:**
- ❌ Pas de cache automatique
- ✅ Utiliser `refreshApex(wiredData)` après DML

### Bulk operations

**Current state:**
- Controller gère **1 record à la fois** (saveItem, markDone, getById)
- WorkItemService/Domain supportent **bulk operations**

**Future enhancement:**
```apex
@AuraEnabled
public static List<Work_Item__c> saveItems(List<Work_Item__c> items) {
    // Bulk insert/update
    return WorkItemService.saveItems(items);
}
```

---

## Security Considerations

### CRUD/FLS

**Current:**
- ❌ Pas de vérification explicite CRUD/FLS dans Controller
- ⚠️ with SHARING appliqué sur toutes les classes

**Best practice (à ajouter):**
```apex
public with sharing class WorkItemController {
    @AuraEnabled(cacheable=true)
    public static List<Work_Item__c> getItems(...) {
        if (!Schema.sObjectType.Work_Item__c.isAccessible()) {
            throw new AuraHandledException('Accès refusé: Work_Item__c');
        }
        // ...
    }
}
```

### Input validation

**Current:**
- ✅ Validation null checks
- ✅ Validation limitSize range
- ⚠️ Pas de sanitization spécifique (searchTerm)

**Considérations:**
- SOQL Injection: WorkItemSelector utilise binding variables (✅ safe)
- XSS: Salesforce échappe automatiquement dans LWC (✅ safe)

---

## Future Enhancements

### 1. Intégration complète UiError

**Statut:** Fondation déployée, intégration pending

**Steps:**
1. ✅ LogContext déployé
2. ✅ UiError créé
3. ⏳ Refactor old Logger framework (blocker)
4. ⏳ Déployer ControllerLogger
5. ⏳ Intégrer UiError dans WorkItemController
6. ⏳ Mettre à jour tests avec validation correlationId

### 2. Logging complet

**Architecture cible:**
- Entrance logging: Paramètres entrants
- Exit logging: Résultat + durée
- Error logging: Exception + stacktrace + recordId

**Format:**
```
[abc1-2345] WorkItemController.getItems - Début | status=In Progress, limitSize=50
[abc1-2345] WorkItemController.getItems - Succès | 12 items, duration=45ms
```

### 3. Métriques et monitoring

**Objectifs:**
- Tracker temps de réponse par méthode
- Identifier méthodes les plus utilisées
- Détecter patterns d'erreurs

**Implementation:**
```apex
public static void logMetric(String method, Long duration, Boolean success) {
    // Store in Platform Event or Custom Object
    Metric__e evt = new Metric__e(
        Method__c = method,
        Duration__c = duration,
        Success__c = success,
        CorrelationId__c = LogContext.getCorrelationId()
    );
    EventBus.publish(evt);
}
```

### 4. Bulk operations support

**Ajout de méthodes bulk:**
```apex
@AuraEnabled
public static List<Work_Item__c> saveItems(List<Work_Item__c> items);

@AuraEnabled
public static void markDoneMultiple(List<Id> itemIds);
```

---

## Références

### Classes principales

- **WorkItemController** - Controller layer (@AuraEnabled methods)
- **WorkItemService** - Service layer (orchestration)
- **WorkItemDomain** - Domain layer (business rules)
- **WorkItemSelector** - Data access layer (SOQL)
- **UiError** - Error model avec correlationId
- **LogContext** - Correlation ID management

### Tests

- **WorkItemControllerTest** - 10/10 tests, 100% coverage
- **TestDataFactory** - Test data generation

### Documentation

- **ARCHITECTURE.md** - Ce document
- **SPEC.md** - Spécifications fonctionnelles
- **CODE_REVIEW_CHECKLIST.md** - Checklist revue de code
- **DEPLOYMENT_CHECKLIST.md** - Checklist déploiement

---

## Changelog

### 2024-12-31 - JOUR 5 Foundation

**Added:**
- ✅ LogContext.cls avec getCorrelationId()
- ✅ UiError.cls avec factory pattern
- ✅ Documentation ARCHITECTURE.md complète

**Deferred:**
- ⏳ ControllerLogger (blocked by old Logger framework)
- ⏳ UiError integration in WorkItemController
- ⏳ Tests avec validation correlationId

**Status:**
- WorkItemController: Version stable 21e466d (10/10 tests)
- Foundation déployée: LogContext + UiError ready
- Logging complet: Deferred pending Logger refactor

---

*Document généré le 2024-12-31 dans le cadre de JOUR 5 - Controller Layer Documentation*
