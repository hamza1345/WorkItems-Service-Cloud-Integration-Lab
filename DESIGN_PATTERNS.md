# 🏗️ Design Patterns du Framework de Logging

## 📊 Patterns Utilisés

| Pattern | Classe | Rôle |
|---------|--------|------|
| **Factory** | LoggerFactory | Crée les loggers avec configuration cohérente |
| **Strategy** | ILogSink | Destinations multiples (DebugSink, PlatformEventSink) |
| **Fluent API** | Logger | Interface élégante avec method chaining |
| **Singleton** | FeatureFlags | Cache global pour configuration |
| **Immutable** | LogEntry | Données protégées après création |

---

## 1️⃣ Factory Pattern 🏭

**Objectif**: Centraliser la création et configuration des Logger pour garantir la cohérence.

**Comment**: `LoggerFactory.getLogger('MyClass')` crée un Logger avec les paramètres de FeatureFlags (minLevel, persistEnabled).

**Avantage**: Pas de répétition, tous les loggers configurés identiquement.

```apex
Logger logger1 = LoggerFactory.getLogger('UserController');
Logger logger2 = LoggerFactory.getLogger('AccountController');
// Tous deux héritent la config: minLevel = INFO, persist = false
```

---

## 2️⃣ Strategy Pattern 🎯

**Objectif**: Permettre plusieurs destinations (console, base de données, email) sans modifier Logger.

**Comment**: Interface `ILogSink` avec implémentations `DebugSink` et `PlatformEventSink`. Logger délègue à chaque stratégie.

**Avantage**: Ajouter une nouvelle destination (ex: EmailSink) sans toucher le code existant.

```apex
for (ILogSink sink : sinks) {
  sink.write(entry); // Polymorphisme
}
```

---

## 3️⃣ Fluent API Pattern 🔗

**Objectif**: Interface élégante et lisible avec chaînage de méthodes.

**Comment**: Chaque méthode (`debug()`, `info()`, `warn()`) retourne `this`.

**Avantage**: Code expressif et compact.

```apex
logger
  .debug('method', 'Starting')
  .info('method', 'Processing')
  .error('method', 'Failed');
```

---

## 4️⃣ Singleton Pattern 🔐

**Objectif**: Cache la configuration pour éviter requêtes SOQL répétées.

**Comment**: `FeatureFlags` utilise une variable `static` initialisée une seule fois.

**Avantage**: Performance (1 requête SOQL au lieu de 100).

```apex
// Appel 1: Requête SOQL
Logger logger1 = LoggerFactory.getLogger('Class1');

// Appels 2-100: Cache utilisé (pas de requête SOQL)
Logger logger2 = LoggerFactory.getLogger('Class2');
```

---

## 5️⃣ Immutable Object Pattern 📦

**Objectif**: Protéger les LogEntry après création pour éviter mutations dangereuses.

**Comment**: Pas de setters publics, seulement getters et constructeur.

**Avantage**: Sécurité et thread-safety garanties.

```apex
LogEntry entry = new LogEntry('INFO', 'Message', context);
// entry.setMessage('Hack'); ❌ Impossible!
entry.getMessage(); // ✅ Sûr
```

---

## 🎯 Résumé

le  framework combine 5 patterns pour:
- ✅ Cohérence (Factory)
- ✅ Extensibilité (Strategy)
- ✅ Lisibilité (Fluent API)
- ✅ Performance (Singleton)
- ✅ Sécurité (Immutable)
