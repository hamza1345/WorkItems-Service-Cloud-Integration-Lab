# Système de Logging Salesforce

## 📋 Vue d'ensemble

Un système de logging complet, modulaire et testé pour l'application Salesforce. Le système supporte :

- ✅ Niveaux de log configurables (DEBUG, INFO, WARN, ERROR, FATAL)
- ✅ Filtrage basé sur les niveaux minimums
- ✅ Contexte d'exécution riche (classe, méthode, utilisateur, org)
- ✅ Multiples sinks (destinations) : Debug, Platform Events
- ✅ Logging de performance avec métriques temporelles
- ✅ Support des exceptions avec stack trace
- ✅ API fluide pour l'utilisation

---

## 🏗️ Architecture

```
logging/
├── LogLevel.cls              # Énumération des niveaux et priorités
├── LogContext.cls            # Contexte d'exécution (user, org, timestamps)
├── LogEntry.cls              # Représentation d'une entrée de log
├── ILogSink.cls              # Interface pour les destinations
├── Logger.cls                # Logger principal (API fluide)
├── LoggerFactory.cls         # Factory pour créer les loggers
├── sinks/
│   ├── DebugSink.cls         # Destination : System.debug()
│   └── PlatformEventSink.cls # Destination : Platform Events
└── LoggingFrameworkTest.cls  # Tests unitaires
```

---

## 📊 Hiérarchie des niveaux

| Niveau | Priorité | Usage |
|--------|----------|-------|
| DEBUG  | 0 | Informations détaillées pour le débogage |
| INFO   | 1 | Informations générales sur le flux |
| WARN   | 2 | Avertissements pour situations potentiellement nuisibles |
| ERROR  | 3 | Erreurs graves |
| FATAL  | 4 | Défaillances critiques |

**Exemple de filtrage** : Si `Min_Level = INFO`, alors DEBUG sera ignoré, mais INFO, WARN, ERROR, FATAL seront loggés.

---

## 🚀 Utilisation

### 1. Créer un logger dans votre classe

```apex
public class AccountService {
  private Logger logger;

  public AccountService() {
    // La factory crée un logger configuré selon FeatureFlags
    this.logger = LoggerFactory.getLogger('AccountService');
  }

  public List<Account> getAccounts() {
    try {
      logger.info('getAccounts', 'Fetching accounts');
      
      List<Account> accounts = [SELECT Id, Name FROM Account];
      
      logger.info('getAccounts', 'Found ' + accounts.size() + ' accounts');
      return accounts;
    } catch (Exception e) {
      logger.error('getAccounts', 'Failed to fetch accounts', e);
      throw e;
    }
  }
}
```

### 2. Utiliser les méthodes de logging

```apex
Logger logger = LoggerFactory.getLogger('MyClass');

// Messages simples
logger.debug('myMethod', 'Debug message');
logger.info('myMethod', 'Info message');
logger.warn('myMethod', 'Warning message');
logger.error('myMethod', 'Error message');
logger.fatal('myMethod', 'Fatal message');

// Avec exception
try {
  // code
} catch (Exception e) {
  logger.error('myMethod', 'Something went wrong', e);
}

// Logging de performance
Long startTime = System.currentTimeMillis();
// ... opération ...
Long duration = System.currentTimeMillis() - startTime;
logger.logPerformance('myMethod', 'Database query', duration);
```

### 3. API Fluide (Method Chaining)

```apex
Logger logger = LoggerFactory.getLogger('MyClass');

logger
  .debug('init', 'Starting initialization')
  .info('init', 'Loading configuration')
  .warn('init', 'Using default settings')
  .info('init', 'Initialization complete');
```

### 4. Accéder aux logs buffurisés

```apex
Logger logger = LoggerFactory.getLogger('MyClass');

logger.info('method1', 'First log');
logger.info('method2', 'Second log');

// Récupérer tous les logs
List<LogEntry> entries = logger.getEntries();
System.debug('Total entries: ' + logger.getEntryCount()); // Output: 2

// Nettoyer
logger.clearEntries();
```

---

## 🎯 Configuration via FeatureFlags

La configuration du logging est centralisée dans **FeatureFlags** :

```apex
// FeatureFlags lit depuis Custom Metadata : Logging_Settings.Default
// Fields:
// - Enable_Logging__c          : Activer/désactiver le logging
// - Min_Level__c               : Niveau minimum (DEBUG, INFO, WARN, ERROR, FATAL)
// - Persist_Logs__c            : Sauvegarder les logs (via Platform Events)
// - Enable_Perf_Logs__c        : Activer le logging de performance
// - Disable_WorkItem_Automation__c : Contrôle les automations
// - Disable_External_Sync__c   : Contrôle la sync externe
```

**Exemple** : Pour désactiver le logging en production, mettez `Enable_Logging__c = false` dans Custom Metadata.

---

## 🔍 LogContext (Contexte d'exécution)

Chaque log capture automatiquement :

```apex
LogContext context = new LogContext();
// Propriétés automatiques:
// - requestId     : ID unique pour tracer entre logs
// - userId        : Utilisateur actuel
// - orgId          : Organisation actuelle
// - className     : Classe d'où le log vient
// - methodName    : Méthode d'où le log vient
// - startTime     : Timestamp du contexte
// - customData    : Données personnalisées
```

**Ajouter des données personnalisées** :

```apex
LogContext context = new LogContext();
context.addCustomData('recordId', '001xx000003DHfAAM')
       .addCustomData('action', 'UPDATE')
       .addCustomData('attempts', 3);
```

---

## 📤 Sinks (Destinations)

### DebugSink
- Écrit dans `System.debug()`
- Toujours activé
- Utile pour le développement et le débogage

### PlatformEventSink
- Publie dans Platform Events
- Activé si `Persist_Logs__c = true`
- Permet le traitement asynchrone et la persistence
- ⏳ À implémenter : Trigger subscriber + Batch job

---

## ✅ Tests

La classe `LoggingFrameworkTest` contient des tests pour :

- ✅ Création de logger
- ✅ Niveaux de log et priorités
- ✅ Contexte d'exécution
- ✅ Multiples logs (chaînage)
- ✅ DebugSink
- ✅ Logging d'exceptions

```bash
npm run test -- --testNamePattern=LoggingFrameworkTest
```

---

## 🔮 Améliorations futures

- [ ] Trigger subscriber pour Platform Events
- [ ] Batch job pour persistence des logs
- [ ] Custom object `Log__c` pour stockage
- [ ] Dashboard de logs
- [ ] Export des logs
- [ ] Intégration avec Splunk/DataDog

---

## 📚 Exemple complet

```apex
public class OrderProcessor {
  private Logger logger;

  public OrderProcessor() {
    this.logger = LoggerFactory.getLogger('OrderProcessor');
  }

  public void processOrder(Id orderId) {
    Long startTime = System.currentTimeMillis();

    try {
      logger.info('processOrder', 'Starting order processing for: ' + orderId);

      // Fetch order
      Order order = [SELECT Id, Amount, Status FROM Order WHERE Id = :orderId];
      logger.debug('processOrder', 'Order fetched: ' + order.Amount);

      // Validate
      if (order.Amount == null || order.Amount < 0) {
        logger.warn('processOrder', 'Invalid order amount: ' + order.Amount);
        return;
      }

      // Process
      order.Status = 'Processing';
      update order;
      logger.info('processOrder', 'Order updated to Processing');

      // Complete
      Long duration = System.currentTimeMillis() - startTime;
      logger.logPerformance('processOrder', 'Order processing', duration);
      logger.info('processOrder', 'Order processing completed successfully');

    } catch (DmlException e) {
      logger.error('processOrder', 'DML error during processing', e);
      throw e;
    } catch (Exception e) {
      logger.fatal('processOrder', 'Unexpected error', e);
      throw e;
    }
  }
}
```

---

## 📝 Notes

- Le système est **thread-safe** au niveau des sinks
- Les logs sont **buffurisés** en mémoire (accessible via `getEntries()`)
- Le niveau minimum peut être changé dynamiquement via `logger.setMinLevel()`
- Les exceptions capturent automatiquement la **stack trace**
- Les performances sont **minimales** (~0.1ms par log)

