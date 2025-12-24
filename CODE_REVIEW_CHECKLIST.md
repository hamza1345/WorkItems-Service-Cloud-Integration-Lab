# ✅ Apex Code Review Checklist

Avant de merger une PR, vérifier que le code respecte ces critères.

## 🛡️ Sécurité

- [ ] Classe a un sharing model (`with sharing`, `without sharing`, ou `inherited sharing`)
- [ ] Toutes les requêtes SOQL/DML précédées d'une validation CRUD
- [ ] Pas d'injection SQL (toutes les variables bindées)
- [ ] Pas de hardcoded IDs, usernames, ou URLs sensibles
- [ ] Configuration en CustomMetadata/CustomSettings, pas en code
- [ ] Pas de credentials stockées en clair

## 📊 Performance

- [ ] Pas de `System.debug()` en code de production
- [ ] SOQL centralisé en une seule méthode
- [ ] Caching implémenté pour lookups répétés
- [ ] `SObjectDescribeOptions.DEFERRED` utilisé
- [ ] Pas de SOQL/DML dans boucles
- [ ] Pas d'appels API dans boucles
- [ ] Governor limits considérés (batch, bulk ops)

## 📝 Documentation & Code

- [ ] Chaque méthode publique a JavaDoc avec `@description`
- [ ] Chaque classe a JavaDoc avec `@author` et `@version`
- [ ] Pas d'espaces blancs en fin de ligne
- [ ] Indentation cohérente (4 espaces)
- [ ] Noms de variables explicites (pas `i`, `x`, `temp`)
- [ ] Constantes en UPPER_CASE
- [ ] Noms de classes : PascalCase
- [ ] Noms de méthodes : camelCase

## 🧪 Tests

- [ ] Classe de test existe (`*Test.cls`)
- [ ] Coverage minimum 80% (vérifier avec `sfdx force:apex:test:report`)
- [ ] Tests couvrent cas normal et cas d'erreur
- [ ] Tests isolés (pas de dépendance entre tests)
- [ ] `@TestVisible` utilisé pour reset cache
- [ ] Assertions claires (pas de `Assert.isTrue(true)`)
- [ ] Test naming: `testScenario()` (ex: `testSafeFallbackDefaults()`)

## 🏗️ Architecture

- [ ] Pas de hardcoding de config/règles métier
- [ ] SOQL séparé de la logique métier
- [ ] Exception handling clair (catch specific exceptions)
- [ ] Safe fallbacks pour null/missing data
- [ ] Pas de couplage dur entre classes
- [ ] Services stateless quand possible

## ✨ Bonne pratiques Salesforce

- [ ] CustomMetadata pour config, pas Custom Settings statiques
- [ ] FeatureFlags.cls utilisé pour toggles
- [ ] Logging centralisé (utilise Logger util)
- [ ] Batch/Queueable pour bulk operations
- [ ] Scheduled jobs pour automations async
- [ ] Limits vérifiés (List size, query count, etc)

## 🔄 Git & Deployment

- [ ] Branch créée depuis `develop`
- [ ] Commit messages descriptifs (ex: "feat: Add CRUD validation to FeatureFlags")
- [ ] Pas de merge conflicts
- [ ] CI/CD pipeline passe ✅
- [ ] Code analyzer (PMD, SonarQube) approuve
- [ ] Formaté avec prettier/prettier-plugin-apex

## 📋 Avant de Merger

- [ ] Au moins 1 review approuvé
- [ ] Tous les tests passent localement
- [ ] Aucun breaking change
- [ ] Documentation mise à jour si nécessaire
- [ ] Labels GitHub appliqués (bug, feature, hotfix, etc)

---

## 🚀 Quick Commands

```bash
# Lancer les tests
npm run test:unit

# Vérifier coverage
sfdx force:apex:test:report -u devEdition

# Formater le code
npm run prettier

# Linter
npm run lint

# PMD analysis
sf scanner:run --target force-app/

# Deploy to org
sf project deploy start -d force-app/ -l NoTestRun
```

---

## 🎓 Learning Resources

- **FeatureFlags.cls** - Exemple de classe senior respectant tous les critères
- **.copilot-instructions.md** - Guide complet des bonnes pratiques
- **.copilot.json** - Configuration pour Copilot

**Questions?** Consulte `.copilot-instructions.md` ou demande au team lead.
