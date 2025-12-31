# Work Items Integration Lab - Documentation technique complète

## Table des matières exhaustive
1. [Introduction et contexte projet](#1-introduction-et-contexte-projet)
2. [Architecture détaillée](#2-architecture-détaillée)
3. [Implémentation Backend (Apex)](#3-implémentation-backend-apex)
4. [Implémentation Frontend (LWC)](#4-implémentation-frontend-lwc)
5. [Framework de Logging](#5-framework-de-logging)
6. [Intégrations externes](#6-intégrations-externes)
7. [Tests et assurance qualité](#7-tests-et-assurance-qualité)
8. [Déploiement et configuration](#8-déploiement-et-configuration)
9. [Performance et optimisation](#9-performance-et-optimisation)
10. [Sécurité](#10-sécurité)
11. [Maintenance et troubleshooting](#11-maintenance-et-troubleshooting)
12. [Annexes](#12-annexes)

---

## 1. Introduction et contexte projet

### 1.1 Objectifs du projet

Ce projet implémente une solution complète de gestion de Work Items dans Salesforce avec les objectifs suivants:

**Objectifs fonctionnels**:
- Gestion complète du cycle de vie des Work Items (CRUD)
- Workflow de statuts avec règles de transition
- Recherche et filtrage avancés
- Synchronisation bidirectionnelle avec systèmes externes
- Notifications et alertes automatiques
- Reporting et analytics

**Objectifs techniques**:
- Architecture scalable (support >10,000 records)
- Code maintenable (patterns enterprise, séparation des couches)
- Testing rigoureux (>75% code coverage cible)
- Performance optimale (bulk operations, SOQL optimization)
- Sécurité renforcée (field-level, record-level, sharing rules)
- Monitoring et observability (logging framework custom)

### 1.2 Technologies utilisées

**Plateforme Salesforce**:
- Salesforce DX (org-based development)
- API Version: 65.0
- Edition: Developer Edition
- Org: amerihamza245@agentforce.com

**Backend**:
- Apex Classes (Controllers, Services, Selectors, Domain)
- Triggers avec handler pattern
- Platform Events pour messaging asynchrone
- Batch Apex & Schedulable pour jobs
- SOAP/REST callouts pour intégrations

**Frontend**:
- Lightning Web Components (LWC)
- Lightning Data Service
- Aura-enabled Apex methods
- SLDS (Salesforce Lightning Design System)

**Testing**:
- Apex Test Framework (@IsTest)
- Jest (JavaScript testing pour LWC)
- sfdx-lwc-jest (LWC testing utilities)

**CI/CD & Tooling**:
- Salesforce CLI (sf command)
- Git (version control)
- npm (package management)
- ESLint (JavaScript linting)
- Prettier (code formatting)

### 1.3 Structure du projet

```
WorkItems-Service-Cloud-Integration-Lab/
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/              # Apex classes
│           │   ├── core/             # Business logic
│           │   │   ├── WorkItemController.cls
│           │   │   ├── WorkItemService.cls
│           │   │   ├── WorkItemSelector.cls
│           │   │   ├── WorkItemDomain.cls
│           │   │   └── BusinessException.cls
│           │   ├── integration/      # External integrations
│           │   │   ├── SoapClientFacade.cls
│           │   │   └── ExternalRestClient.cls
│           │   ├── jobs/             # Batch & Schedulable
│           │   │   └── WorkItemSyncJob.cls
│           │   ├── logging/          # Logging framework
│           │   │   ├── Logger.cls
│           │   │   ├── LogContext.cls
│           │   │   ├── LogEntry.cls
│           │   │   ├── LogLevel.cls
│           │   │   └── LoggerFactory.cls
│           │   ├── sinks/            # Log output strategies
│           │   │   ├── LogSink.cls (interface)
│           │   │   ├── DebugSink.cls
│           │   │   └── PlatformEventSink.cls
│           │   └── tests/            # Test classes
│           │       ├── WorkItemControllerTest.cls
│           │       ├── WorkItemServiceTest.cls
│           │       └── ... (27 test classes)
│           ├── lwc/                  # Lightning Web Components
│           │   ├── workItemList/
│           │   │   ├── workItemList.html
│           │   │   ├── workItemList.js
│           │   │   ├── workItemList.css
│           │   │   ├── workItemList.js-meta.xml
│           │   │   └── __tests__/
│           │   │       └── workItemList.test.js
│           │   ├── workItemForm/
│           │   │   └── ... (similar structure)
│           │   └── utils/            # Shared utilities
│           │       ├── utils.js
│           │       └── errorUtils.js
│           ├── triggers/             # Apex triggers
│           │   └── WorkItemTrigger.trigger
│           ├── objects/              # Custom objects
│           │   ├── Work_Item__c/
│           │   │   ├── Work_Item__c.object-meta.xml
│           │   │   └── fields/
│           │   └── App_Log__c/
│           ├── customMetadata/       # Configuration
│           │   ├── Logging_Settings.Default.md-meta.xml
│           │   └── Feature_Flag.persistLogs.md-meta.xml
│           ├── permissionsets/       # Security
│           │   └── Work_Item_Manager.permissionset-meta.xml
│           └── applications/         # Lightning Apps
│               └── Work_Items.app-meta.xml
├── config/                           # Org configs
│   └── project-scratch-def.json
├── scripts/                          # Utility scripts
│   ├── apex/
│   │   └── performance-audit.apex
│   └── soql/
│       └── account.soql
├── test-results/                     # Test outputs
│   └── test-result-*.json
├── package.json                      # npm dependencies
├── jest.config.js                    # Jest configuration
├── eslint.config.js                  # ESLint rules
├── sfdx-project.json                 # Salesforce project config
└── README.md                         # Project overview
```

---

## 2. Architecture détaillée

### 2.1 Patterns architecturaux appliqués

#### 2.1.1 Separation of Concerns (SoC)

L'application suit une architecture en couches stricte:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (LWC Components, Aura Components)      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Controller Layer                │
│  (Aura-enabled Apex, REST endpoints)    │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Service Layer                   │
│  (Business logic, transactions)         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Domain Layer                    │
│  (Business rules, validation)           │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Selector Layer                  │
│  (Data access, SOQL queries)            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Database Layer                  │
│  (Salesforce Objects, Schema)           │
└─────────────────────────────────────────┘
```

**Responsabilités par couche**:

| Couche | Responsabilité | Ne doit PAS |
|--------|---------------|-------------|
| Controller | Validation entrées, conversion exceptions, orchestration | Contenir logique métier, faire des queries directes |
| Service | Transactions, orchestration processus métier, side-effects | Contenir validation métier, exposer méthodes publiques non-service |
| Domain | Règles métier, validation, calculs | Faire des DML, des queries, appeler services |
| Selector | Queries SOQL, caching, indexing strategy | Contenir logique métier, faire des DML |

#### 2.1.2 Single Responsibility Principle (SRP)

Chaque classe a une responsabilité unique et bien définie:

```apex
// ✅ GOOD: Une classe = une responsabilité
public class WorkItemSelector {
    // Responsabilité: Récupérer des Work Items depuis la base
    public List<Work_Item__c> byId(Id workItemId) { }
    public List<Work_Item__c> byStatus(String status) { }
}

public class WorkItemDomain {
    // Responsabilité: Appliquer les règles métier
    public static void validate(List<Work_Item__c> items) { }
    public static void populateDefaults(List<Work_Item__c> items) { }
}

// ❌ BAD: Multiple responsabilités
public class WorkItemManager {
    public List<Work_Item__c> getWorkItems() { } // Data access
    public void validateWorkItem(Work_Item__c item) { } // Business rules
    public void saveWorkItem(Work_Item__c item) { } // Persistence
    public void syncToExternal(Work_Item__c item) { } // Integration
    // Violation du SRP!
}
```

#### 2.1.3 Dependency Injection (DI)

Utilisation d'interfaces pour réduire le couplage:

```apex
// Interface définit le contrat
public interface LogSink {
    void write(LogEntry entry);
    void flush();
}

// Implémentations multiples
public class DebugSink implements LogSink {
    public void write(LogEntry entry) {
        System.debug(entry.getMessage());
    }
}

public class PlatformEventSink implements LogSink {
    public void write(LogEntry entry) {
        EventBus.publish(entry.toEvent());
    }
}

// Logger utilise l'interface (pas l'implémentation)
public class Logger {
    private List<LogSink> sinks;
    
    public Logger(List<LogSink> sinks) {
        this.sinks = sinks; // Injection de dépendance
    }
    
    public void info(String message) {
        LogEntry entry = new LogEntry(LogLevel.INFO, message);
        for (LogSink sink : sinks) {
            sink.write(entry); // Polymorphisme
        }
    }
}
```

**Avantages**:
- Testabilité: Possibilité de mocker les dépendances
- Flexibilité: Changement d'implémentation sans modifier le code appelant
- Maintenabilité: Moins de couplage entre classes

#### 2.1.4 Factory Pattern

Création centralisée d'objets complexes:

```apex
public class LoggerFactory {
    private static Map<String, Logger> loggerCache = new Map<String, Logger>();
    
    public static Logger createLogger(String name) {
        // Cache pour éviter création multiple
        if (loggerCache.containsKey(name)) {
            return loggerCache.get(name);
        }
        
        // Configuration depuis Custom Metadata
        Logging_Settings__mdt config = getConfiguration();
        
        // Création des sinks selon configuration
        List<LogSink> sinks = new List<LogSink>();
        if (config.Enable_Debug_Sink__c) {
            sinks.add(new DebugSink());
        }
        if (config.Enable_Platform_Event_Sink__c) {
            sinks.add(new PlatformEventSink());
        }
        
        // Création logger
        Logger logger = new Logger(name, config.Log_Level__c, sinks);
        loggerCache.put(name, logger);
        
        return logger;
    }
}

// Utilisation
Logger logger = LoggerFactory.createLogger('WorkItemService');
```

#### 2.1.5 Strategy Pattern

Algorithmes interchangeables via interfaces:

```apex
// Strategy interface
public interface LogSink {
    void write(LogEntry entry);
}

// Context utilise la strategy
public class Logger {
    private List<LogSink> strategies; // Multiple strategies
    
    public void log(LogEntry entry) {
        for (LogSink strategy : strategies) {
            strategy.write(entry); // Délégation à la strategy
        }
    }
}

// Client configure la strategy
List<LogSink> sinks = new List<LogSink>{
    new DebugSink(),
    new PlatformEventSink()
};
Logger logger = new Logger('MyLogger', LogLevel.INFO, sinks);
```

### 2.2 Diagrammes d'architecture

#### 2.2.1 Diagramme de composants

```
┌──────────────────────────────────────────────────────────┐
│                    Lightning Experience                  │
│  ┌────────────────┐         ┌─────────────────────────┐ │
│  │ workItemList   │         │   workItemForm          │ │
│  │  (LWC)         │         │   (LWC)                 │ │
│  └────────┬───────┘         └──────────┬──────────────┘ │
└───────────┼────────────────────────────┼─────────────────┘
            │                            │
            │ @wire / imperative calls   │
            │                            │
            ▼                            ▼
┌──────────────────────────────────────────────────────────┐
│               WorkItemController (@AuraEnabled)          │
│  • getItems(status, searchTerm, limitSize)              │
│  • saveItem(item)                                        │
│  • markDone(workItemId)                                  │
└────────────────────────┬─────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────┐
│                  WorkItemService                         │
│  • createWorkItem()      • getItems()                    │
│  • updateWorkItem()      • markDone()                    │
│  • deleteWorkItem()      • enqueueExternalSync()         │
└───┬──────────────────┬───────────────────┬───────────────┘
    │                  │                   │
    │                  │                   └─────────────┐
    │                  ▼                                 │
    │         ┌──────────────────┐                      │
    │         │ WorkItemDomain   │                      │
    │         │  • validate()    │                      │
    │         │  • defaults()    │                      │
    │         └──────────────────┘                      │
    │                                                    │
    ▼                                                    ▼
┌──────────────────┐                          ┌──────────────────┐
│ WorkItemSelector │                          │ SoapClientFacade │
│  • byId()        │                          │  • syncWorkItem()│
│  • search()      │                          └──────────────────┘
└──────────────────┘
```

#### 2.2.2 Diagramme de séquence - Create Work Item

```
User → LWC → Controller → Service → Domain → Selector → Database

User: Click "Save"
  │
  ├──> LWC.handleSave()
  │      │
  │      ├──> validateForm()
  │      │      │
  │      │      └──> return true
  │      │
  │      ├──> WorkItemController.saveItem(item)
  │      │      │
  │      │      ├──> WorkItemService.createWorkItem(item)
  │      │      │      │
  │      │      │      ├──> Savepoint sp = Database.setSavepoint()
  │      │      │      │
  │      │      │      ├──> WorkItemDomain.validate([item])
  │      │      │      │      │
  │      │      │      │      └──> Check required fields
  │      │      │      │
  │      │      │      ├──> WorkItemDomain.populateDefaults([item])
  │      │      │      │      │
  │      │      │      │      └──> Set Status='New', Priority='Medium'
  │      │      │      │
  │      │      │      ├──> insert item
  │      │      │      │      │
  │      │      │      │      └──> Database: INSERT Work_Item__c
  │      │      │      │
  │      │      │      ├──> enqueueExternalSync(item.Id)
  │      │      │      │      │
  │      │      │      │      └──> Queueable job enqueued
  │      │      │      │
  │      │      │      └──> return item
  │      │      │
  │      │      └──> return item (to LWC)
  │      │
  │      └──> showToast('Success')
  │
  └──> Dispatch 'save' event
```

---

## 3. Implémentation Backend (Apex)

### 3.1 Controller Layer

#### 3.1.1 WorkItemController.cls

**Rôle**: Point d'entrée pour les composants Lightning, expose 3 méthodes @AuraEnabled.

**Code complet**:
```apex
public with sharing class WorkItemController {
    
    private static final Logger LOGGER = LoggerFactory.createLogger('WorkItemController');
    
    /**
     * Récupère la liste des Work Items avec filtres optionnels
     * @param status Statut à filtrer (optionnel)
     * @param searchTerm Terme de recherche (optionnel)
     * @param limitSize Nombre max de résultats (default 50)
     * @return Liste des Work Items
     */
    @AuraEnabled(cacheable=true)
    public static List<Work_Item__c> getItems(String status, String searchTerm, Integer limitSize) {
        try {
            LOGGER.info('Getting work items', new Map<String, Object>{
                'status' => status,
                'searchTerm' => searchTerm,
                'limitSize' => limitSize
            });
            
            WorkItemService service = new WorkItemService();
            List<Work_Item__c> items = service.getItems(status, searchTerm, limitSize);
            
            LOGGER.info('Retrieved ' + items.size() + ' work items');
            return items;
            
        } catch (Exception e) {
            LOGGER.error('Failed to get work items', e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * Sauvegarde un Work Item (insert ou update selon Id)
     * @param item Work Item à sauvegarder
     * @return Work Item sauvegardé avec Id
     */
    @AuraEnabled
    public static Work_Item__c saveItem(Work_Item__c item) {
        try {
            LOGGER.info('Saving work item', new Map<String, Object>{
                'itemId' => item.Id,
                'itemName' => item.Name
            });
            
            WorkItemService service = new WorkItemService();
            Work_Item__c savedItem;
            
            if (item.Id == null) {
                savedItem = service.createWorkItem(item);
            } else {
                savedItem = service.updateWorkItem(item);
            }
            
            LOGGER.info('Work item saved successfully', new Map<String, Object>{
                'itemId' => savedItem.Id
            });
            
            return savedItem;
            
        } catch (BusinessException e) {
            LOGGER.error('Business error saving work item', e);
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            LOGGER.error('Unexpected error saving work item', e);
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }
    
    /**
     * Marque un Work Item comme Done
     * @param workItemId Id du Work Item
     */
    @AuraEnabled
    public static void markDone(Id workItemId) {
        try {
            if (workItemId == null) {
                throw new AuraHandledException('Work Item Id cannot be null');
            }
            
            LOGGER.info('Marking work item as done', new Map<String, Object>{
                'itemId' => workItemId
            });
            
            WorkItemService service = new WorkItemService();
            service.markDone(workItemId);
            
            LOGGER.info('Work item marked as done successfully');
            
        } catch (BusinessException e) {
            LOGGER.error('Business error marking done', e);
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            LOGGER.error('Unexpected error marking done', e);
            throw new AuraHandledException('Failed to mark item as done: ' + e.getMessage());
        }
    }
}
```

**Caractéristiques techniques**:

1. **with sharing**: Respect des sharing rules Salesforce
2. **@AuraEnabled**: Méthodes accessibles depuis LWC
3. **cacheable=true**: Pour `getItems()` → wire service peut cacher
4. **Error handling**:
   - Try-catch sur toutes les méthodes
   - Conversion exceptions en `AuraHandledException`
   - Logging systématique des erreurs
5. **Validation**: Check null sur paramètres critiques
6. **Logging**: Info au début/fin, error en cas d'exception

**Tests associés**: `WorkItemControllerTest.cls`
- 10 tests couvrant tous les chemins
- Mock du service layer
- Validation des exceptions AuraHandled

### 3.2 Service Layer

#### 3.2.1 WorkItemService.cls

**Rôle**: Orchestration des processus métier, gestion des transactions.

**Code principal**:
```apex
public class WorkItemService {
    
    private WorkItemSelector selector;
    private static final Logger LOGGER = LoggerFactory.createLogger('WorkItemService');
    
    public WorkItemService() {
        this.selector = new WorkItemSelector();
    }
    
    // Pour testing (dependency injection)
    @TestVisible
    private WorkItemService(WorkItemSelector selector) {
        this.selector = selector;
    }
    
    /**
     * Crée un nouveau Work Item
     */
    public Work_Item__c createWorkItem(Work_Item__c item) {
        if (item == null) {
            throw new BusinessException('ERR_NULL_ITEM', 'Work Item cannot be null');
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            // 1. Validation métier
            WorkItemDomain.validate(new List<Work_Item__c>{item});
            
            // 2. Application des defaults
            WorkItemDomain.populateDefaults(new List<Work_Item__c>{item});
            
            // 3. Vérification unicité External_Id si présent
            if (String.isNotBlank(item.External_Id__c)) {
                Work_Item__c existing = selector.byExternalId(item.External_Id__c);
                if (existing != null) {
                    throw new BusinessException(
                        'ERR_DUPLICATE_EXTERNAL_ID',
                        'A Work Item with this External Id already exists'
                    );
                }
            }
            
            // 4. Persistence
            insert item;
            
            LOGGER.info('Work Item created', new Map<String, Object>{
                'itemId' => item.Id,
                'itemName' => item.Name
            });
            
            // 5. Side effects asynchrones
            enqueueExternalSync(item.Id);
            
            return item;
            
        } catch (Exception e) {
            Database.rollback(sp);
            LOGGER.error('Failed to create work item', e);
            throw new BusinessException('ERR_CREATE_FAILED', 
                'Failed to create work item: ' + e.getMessage(), e);
        }
    }
    
    /**
     * Met à jour un Work Item existant
     */
    public Work_Item__c updateWorkItem(Work_Item__c item) {
        if (item == null || item.Id == null) {
            throw new BusinessException('ERR_INVALID_UPDATE', 
                'Work Item and Id cannot be null for update');
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            // 1. Vérifier existence
            Work_Item__c existing = selector.byId(item.Id);
            if (existing == null) {
                throw new BusinessException('ERR_NOT_FOUND', 
                    'Work Item not found with Id: ' + item.Id);
            }
            
            // 2. Validation métier
            WorkItemDomain.validate(new List<Work_Item__c>{item});
            
            // 3. Validation transition de statut
            if (item.Status__c != existing.Status__c) {
                WorkItemDomain.validateStatusTransition(
                    existing.Status__c, 
                    item.Status__c
                );
            }
            
            // 4. Update
            update item;
            
            LOGGER.info('Work Item updated', new Map<String, Object>{
                'itemId' => item.Id,
                'oldStatus' => existing.Status__c,
                'newStatus' => item.Status__c
            });
            
            // 5. Side effects
            if (item.Status__c != existing.Status__c) {
                enqueueExternalSync(item.Id);
            }
            
            return item;
            
        } catch (Exception e) {
            Database.rollback(sp);
            LOGGER.error('Failed to update work item', e);
            throw new BusinessException('ERR_UPDATE_FAILED', 
                'Failed to update work item: ' + e.getMessage(), e);
        }
    }
    
    /**
     * Supprime un Work Item (règle métier: pas de suppression si Done)
     */
    public void deleteWorkItem(Id workItemId) {
        if (workItemId == null) {
            throw new BusinessException('ERR_NULL_ID', 'Work Item Id cannot be null');
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            Work_Item__c item = selector.byId(workItemId);
            if (item == null) {
                throw new BusinessException('ERR_NOT_FOUND', 
                    'Work Item not found');
            }
            
            // Règle métier: Pas de suppression si Done
            if (item.Status__c == 'Done') {
                throw new BusinessException('ERR_DELETE_DONE', 
                    'Cannot delete Work Item with status Done');
            }
            
            delete item;
            
            LOGGER.info('Work Item deleted', new Map<String, Object>{
                'itemId' => workItemId
            });
            
        } catch (Exception e) {
            Database.rollback(sp);
            LOGGER.error('Failed to delete work item', e);
            throw new BusinessException('ERR_DELETE_FAILED', 
                'Failed to delete work item: ' + e.getMessage(), e);
        }
    }
    
    /**
     * Récupère des Work Items avec filtres
     */
    public List<Work_Item__c> getItems(String status, String searchTerm, Integer limitSize) {
        // Normalisation limite
        if (limitSize == null || limitSize <= 0) {
            limitSize = 50; // Default
        }
        if (limitSize > 2000) {
            limitSize = 2000; // Max
        }
        
        if (String.isNotBlank(searchTerm) || String.isNotBlank(status)) {
            return selector.search(status, searchTerm, limitSize);
        } else {
            return selector.recent(limitSize);
        }
    }
    
    /**
     * Marque un Work Item comme Done
     */
    public void markDone(Id workItemId) {
        if (workItemId == null) {
            throw new BusinessException('ERR_NULL_ID', 
                'Work Item Id cannot be null');
        }
        
        Savepoint sp = Database.setSavepoint();
        
        try {
            Work_Item__c item = selector.byId(workItemId);
            if (item == null) {
                throw new BusinessException('ERR_NOT_FOUND', 
                    'Work Item not found');
            }
            
            // Validation transition
            WorkItemDomain.validateStatusTransition(item.Status__c, 'Done');
            
            item.Status__c = 'Done';
            item.Completed_On__c = Date.today();
            update item;
            
            LOGGER.info('Work Item marked as done', new Map<String, Object>{
                'itemId' => workItemId
            });
            
            enqueueExternalSync(workItemId);
            
        } catch (Exception e) {
            Database.rollback(sp);
            LOGGER.error('Failed to mark done', e);
            throw new BusinessException('ERR_MARK_DONE_FAILED', 
                'Failed to mark work item as done: ' + e.getMessage(), e);
        }
    }
    
    /**
     * Enqueue synchronisation externe (si feature flag activé)
     */
    private void enqueueExternalSync(Id workItemId) {
        if (FeatureFlags.isActive('externalSync')) {
            // Queueable pour ne pas bloquer la transaction
            System.enqueueJob(new ExternalSyncQueueable(workItemId));
        }
    }
}
```

**Patterns implémentés**:
1. **Transaction Script**: Chaque méthode = une transaction complète
2. **Savepoint/Rollback**: Garantie atomicité
3. **Fail-fast**: Validation au début, exception immédiate si invalide
4. **Separation of Concerns**: Délégation validation → Domain, queries → Selector
5. **Defensive Programming**: Check null systématique, normalisation inputs

### 3.3 Selector Layer

#### 3.3.1 WorkItemSelector.cls

**Rôle**: Encapsulation de toutes les queries SOQL, optimisation performance.

**Code complet**:
```apex
public class WorkItemSelector {
    
    // Fields list pour éviter duplication
    private static final List<String> FIELDS = new List<String>{
        'Id', 'Name', 'Status__c', 'Priority__c', 'Category__c',
        'Description__c', 'Due_Date__c', 'Completed_On__c', 'External_Id__c',
        'CreatedDate', 'CreatedById', 'LastModifiedDate', 'LastModifiedById'
    };
    
    private static final Integer DEFAULT_LIMIT = 50;
    private static final Integer MAX_LIMIT = 2000;
    
    /**
     * Récupération par Id unique
     */
    public Work_Item__c byId(Id workItemId) {
        if (workItemId == null) {
            return null;
        }
        
        List<Work_Item__c> items = byIds(new Set<Id>{workItemId});
        return items.isEmpty() ? null : items[0];
    }
    
    /**
     * Récupération bulk par Ids
     */
    public List<Work_Item__c> byIds(Set<Id> workItemIds) {
        if (workItemIds == null || workItemIds.isEmpty()) {
            return new List<Work_Item__c>();
        }
        
        return [
            SELECT Id, Name, Status__c, Priority__c, Category__c,
                   Description__c, Due_Date__c, Completed_On__c, External_Id__c
            FROM Work_Item__c
            WHERE Id IN :workItemIds
        ];
    }
    
    /**
     * Filtrage par statut
     */
    public List<Work_Item__c> byStatus(String status) {
        if (String.isBlank(status)) {
            return new List<Work_Item__c>();
        }
        
        return queryWorkItems('Status__c = :status', null);
    }
    
    /**
     * Filtrage par catégorie
     */
    public List<Work_Item__c> byCategory(String category) {
        if (String.isBlank(category)) {
            return new List<Work_Item__c>();
        }
        
        return queryWorkItems('Category__c = :category', null);
    }
    
    /**
     * Lookup par External Id
     */
    public Work_Item__c byExternalId(String externalId) {
        if (String.isBlank(externalId)) {
            return null;
        }
        
        List<Work_Item__c> items = [
            SELECT Id, Name, Status__c, External_Id__c
            FROM Work_Item__c
            WHERE External_Id__c = :externalId
            LIMIT 1
        ];
        
        return items.isEmpty() ? null : items[0];
    }
    
    /**
     * Recherche combinée (status + texte)
     */
    public List<Work_Item__c> search(String status, String searchTerm, Integer limitSize) {
        limitSize = normalizeLimitSize(limitSize);
        
        String query = 'SELECT ' + String.join(FIELDS, ', ') +
                       ' FROM Work_Item__c';
        
        List<String> conditions = new List<String>();
        
        // Filtre status
        if (String.isNotBlank(status)) {
            conditions.add('Status__c = :status');
        }
        
        // Filtre texte (SOQL LIKE)
        if (String.isNotBlank(searchTerm)) {
            String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            conditions.add('(Name LIKE :searchPattern OR ' +
                          'Description__c LIKE :searchPattern OR ' +
                          'Category__c LIKE :searchPattern)');
        }
        
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        query += ' ORDER BY LastModifiedDate DESC';
        query += ' LIMIT :limitSize';
        
        return Database.query(query);
    }
    
    /**
     * Work Items les plus récents
     */
    public List<Work_Item__c> recent(Integer limitSize) {
        limitSize = normalizeLimitSize(limitSize);
        
        return [
            SELECT Id, Name, Status__c, Priority__c, Category__c,
                   Due_Date__c, Completed_On__c, LastModifiedDate
            FROM Work_Item__c
            ORDER BY LastModifiedDate DESC
            LIMIT :limitSize
        ];
    }
    
    /**
     * Work Items en retard
     */
    public List<Work_Item__c> getOverdue() {
        Date today = Date.today();
        
        return [
            SELECT Id, Name, Status__c, Priority__c, Due_Date__c
            FROM Work_Item__c
            WHERE Due_Date__c < :today
            AND Status__c != 'Done'
            ORDER BY Due_Date__c ASC
        ];
    }
    
    /**
     * Tous les Work Items actifs (pas Done)
     */
    public List<Work_Item__c> getAllActiveWorkItems() {
        return [
            SELECT Id, Name, Status__c, Priority__c, Category__c, Due_Date__c
            FROM Work_Item__c
            WHERE Status__c != 'Done'
            ORDER BY Priority__c DESC, Due_Date__c ASC
        ];
    }
    
    /**
     * Delta query pour synchronisation
     */
    public List<Work_Item__c> getCreatedAfter(Datetime sinceDate) {
        if (sinceDate == null) {
            return new List<Work_Item__c>();
        }
        
        return [
            SELECT Id, Name, Status__c, Priority__c, Category__c,
                   External_Id__c, LastModifiedDate
            FROM Work_Item__c
            WHERE LastModifiedDate > :sinceDate
            ORDER BY LastModifiedDate ASC
        ];
    }
    
    // Helper: Normalisation limite
    private Integer normalizeLimitSize(Integer limitSize) {
        if (limitSize == null || limitSize <= 0) {
            return DEFAULT_LIMIT;
        }
        if (limitSize > MAX_LIMIT) {
            return MAX_LIMIT;
        }
        return limitSize;
    }
    
    // Helper: Query générique
    private List<Work_Item__c> queryWorkItems(String whereClause, Integer limitSize) {
        String query = 'SELECT ' + String.join(FIELDS, ', ') +
                       ' FROM Work_Item__c';
        
        if (String.isNotBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }
        
        query += ' ORDER BY LastModifiedDate DESC';
        
        if (limitSize != null) {
            query += ' LIMIT ' + limitSize;
        }
        
        return Database.query(query);
    }
}
```

**Optimisations SOQL**:
1. **Field list constante**: Évite erreurs typo, facilite maintenance
2. **Selective queries**: WHERE clauses sur champs indexés (Status__c, External_Id__c)
3. **LIMIT systématique**: Protection contre requêtes massives
4. **ORDER BY LastModifiedDate**: Utilise index automatique
5. **Bulk-ready**: Méthode `byIds()` accepte Set<Id>

**Tests**: `WorkItemSelectorTest.cls` (26 tests, 76% coverage)

### 3.4 Domain Layer

#### 3.4.1 WorkItemDomain.cls

**Rôle**: Encapsulation des règles métier pures, sans side-effects.

**Code complet**:
```apex
public class WorkItemDomain {
    
    // Constantes métier
    private static final List<String> VALID_STATUSES = new List<String>{
        'New', 'In Progress', 'Blocked', 'Done'
    };
    
    private static final List<String> VALID_PRIORITIES = new List<String>{
        'Low', 'Medium', 'High', 'Critical'
    };
    
    private static final Map<String, List<String>> ALLOWED_TRANSITIONS = new Map<String, List<String>>{
        'New' => new List<String>{'In Progress', 'Blocked', 'Done'},
        'In Progress' => new List<String>{'Blocked', 'Done'},
        'Blocked' => new List<String>{'In Progress', 'Done'},
        'Done' => new List<String>{} // Aucune transition depuis Done
    };
    
    /**
     * Validation métier des Work Items
     * @throws BusinessException si validation échoue
     */
    public static void validate(List<Work_Item__c> items) {
        if (items == null || items.isEmpty()) {
            return;
        }
        
        List<String> errors = new List<String>();
        
        for (Work_Item__c item : items) {
            // Required: Name
            if (String.isBlank(item.Name)) {
                errors.add('Work Item Name is required');
            }
            
            // Valid Status
            if (String.isNotBlank(item.Status__c) && 
                !VALID_STATUSES.contains(item.Status__c)) {
                errors.add('Invalid Status: ' + item.Status__c);
            }
            
            // Valid Priority
            if (String.isNotBlank(item.Priority__c) && 
                !VALID_PRIORITIES.contains(item.Priority__c)) {
                errors.add('Invalid Priority: ' + item.Priority__c);
            }
            
            // Business rule: Done items must have Due Date >= today
            if (item.Status__c == 'Done' && 
                item.Due_Date__c != null && 
                item.Due_Date__c < Date.today()) {
                errors.add('Cannot mark as Done a Work Item with past due date');
            }
        }
        
        if (!errors.isEmpty()) {
            throw new BusinessException('VALIDATION_ERROR', 
                String.join(errors, '; '));
        }
    }
    
    /**
     * Application des valeurs par défaut
     */
    public static void populateDefaults(List<Work_Item__c> items) {
        if (items == null || items.isEmpty()) {
            return;
        }
        
        for (Work_Item__c item : items) {
            if (String.isBlank(item.Status__c)) {
                item.Status__c = 'New';
            }
            
            if (String.isBlank(item.Priority__c)) {
                item.Priority__c = 'Medium';
            }
            
            if (String.isBlank(item.Category__c)) {
                item.Category__c = 'General';
            }
        }
    }
    
    /**
     * Application des règles métier (appelé depuis trigger)
     */
    public static void applyBusinessRules(List<Work_Item__c> items) {
        if (items == null || items.isEmpty()) {
            return;
        }
        
        for (Work_Item__c item : items) {
            // Auto-set Completed_On si Status = Done
            if (item.Status__c == 'Done' && item.Completed_On__c == null) {
                item.Completed_On__c = Date.today();
            }
            
            // Clear Completed_On si Status != Done
            if (item.Status__c != 'Done' && item.Completed_On__c != null) {
                item.Completed_On__c = null;
            }
        }
    }
    
    /**
     * Validation des transitions de statut
     */
    public static void validateStatusTransition(String oldStatus, String newStatus) {
        if (oldStatus == newStatus) {
            return; // Pas de transition
        }
        
        if (!ALLOWED_TRANSITIONS.containsKey(oldStatus)) {
            throw new BusinessException('INVALID_TRANSITION', 
                'Unknown old status: ' + oldStatus);
        }
        
        List<String> allowedNextStatuses = ALLOWED_TRANSITIONS.get(oldStatus);
        if (!allowedNextStatuses.contains(newStatus)) {
            throw new BusinessException('INVALID_TRANSITION', 
                'Cannot transition from ' + oldStatus + ' to ' + newStatus);
        }
    }
    
    /**
     * Calculer le % de complétion
     */
    public static Decimal calculateCompletionPercentage(List<Work_Item__c> items) {
        if (items == null || items.isEmpty()) {
            return 0;
        }
        
        Integer totalCount = items.size();
        Integer doneCount = 0;
        
        for (Work_Item__c item : items) {
            if (item.Status__c == 'Done') {
                doneCount++;
            }
        }
        
        return (Decimal)doneCount / (Decimal)totalCount * 100;
    }
    
    /**
     * Check si Work Item est en retard
     */
    public static Boolean isOverdue(Work_Item__c item) {
        return item.Due_Date__c != null && 
               item.Due_Date__c < Date.today() && 
               item.Status__c != 'Done';
    }
    
    /**
     * Check si Work Item doit être fait bientôt (3 jours)
     */
    public static Boolean isDueSoon(Work_Item__c item) {
        if (item.Due_Date__c == null || item.Status__c == 'Done') {
            return false;
        }
        
        Integer daysUntilDue = Date.today().daysBetween(item.Due_Date__c);
        return daysUntilDue >= 0 && daysUntilDue <= 3;
    }
}
```

**Caractéristiques**:
1. **Stateless**: Méthodes statiques sans état
2. **Pure functions**: Pas de side-effects (pas de DML, pas de callouts)
3. **Single Source of Truth**: Règles métier centralisées
4. **Testable**: Facile à tester car pas de dépendances
5. **Réutilisable**: Appelable depuis Service, Trigger, Batch

**Tests**: `WorkItemDomainTest.cls` (13 tests, 93% coverage)

---

[Continue dans la partie 2...]
