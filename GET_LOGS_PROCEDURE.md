# Procédure Simple pour Récupérer les Logs Salesforce

## 📋 Résumé
Cette procédure explique comment télécharger et analyser les logs de debug de votre org Salesforce en utilisant Salesforce CLI.

---

## ✅ Étape 1 : Lister tous les logs disponibles

Ouvrez PowerShell et exécutez :

```powershell
##ici on se posionne sur le repertoire : 

cd "c:\Project\salesforce_ant_57.0\sample\work\WorkItems-Service-Cloud-Integration-Lab"

## on recupere les log 

sf apex log list --target-org devEdition
 

 

## ✅ Étape 1b : Lister SEULEMENT Id, Start Time, et Log User

Si vous voulez **juste ces 3 colonnes**, utilisez cette commande powershell:

  
 
 
 
sf apex log list --target-org devEdition --json | ConvertFrom-Json | Select-Object -ExpandProperty result | Format-Table -Property Id, StartTime, LogUser -AutoSize
 

**Résultat attendu** :
 
Id                  StartTime                 LogUser
--                  ---------                 -------
07Lfj000003bBxFEAU  2025-12-24T12:56:57+0000  Hamza AMARI
 
 

 

## ✅ Étape 1c : Lister SEULEMENT les logs d'AUJOURD'HUI

Si vous avez beaucoup de logs et voulez **juste ceux d'aujourd'hui** :

 
```powershell
sf apex log list --target-org devEdition --json | ConvertFrom-Json | Select-Object -ExpandProperty result | Where-Object {$_.StartTime -like "$(Get-Date -Format 'yyyy-MM-dd')*"} | Format-Table -Property Id, StartTime, LogUser -AutoSize
```

**Résultat** : Affiche SEULEMENT les logs créés aujourd'hui
```
Id                  StartTime                 LogUser
--                  ---------                 -------
07Lfj000003bBxFEAU  2025-12-24T12:56:57+0000  Hamza AMARI
07Lfj000003b7QbEAI  2025-12-24T12:29:59+0000  Hamza AMARI
```

**Variantes utiles** :

```powershell
# Logs d'hier
$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
sf apex log list --target-org devEdition --json | ConvertFrom-Json | Select-Object -ExpandProperty result | Where-Object {$_.StartTime -like "$yesterday*"} | Format-Table Id, StartTime, LogUser

# Logs des 3 derniers jours
$threeAgo = (Get-Date).AddDays(-3).ToString("yyyy-MM-dd")
sf apex log list --target-org devEdition --json | ConvertFrom-Json | Select-Object -ExpandProperty result | Where-Object {$_.StartTime -ge "$threeAgo"} | Format-Table Id, StartTime, LogUser

# Logs des 2 dernières heures
$twoHoursAgo = (Get-Date).AddHours(-2).ToString("yyyy-MM-ddTHH:mm:ss")
sf apex log list --target-org devEdition --json | ConvertFrom-Json | Select-Object -ExpandProperty result | Where-Object {$_.StartTime -gt $twoHoursAgo} | Format-Table Id, StartTime, LogUser
```

---

## ✅ Étape 1d : Script complet - Récupérer TOUS les logs d'aujourd'hui

Voici un script qui télécharge **tous les logs du jour actuel** en une seule commande :

```powershell
# Configuration
$today = (Get-Date).ToString("yyyy-MM-dd")
$outputDir = "logs"

# SAISIR LE NOMBRE DE LOGS À RÉCUPÉRER
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Combien de logs voulez-vous récupérer?║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
$limitLogsInput = Read-Host "Nombre de logs (par défaut: 5)"
$limitLogs = if ([string]::IsNullOrEmpty($limitLogsInput)) { 5 } else { [int]$limitLogsInput }

Write-Host "✓ Limite définie à: $limitLogs logs" -ForegroundColor Yellow

# Créer le dossier s'il n'existe pas
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

# Récupérer les logs d'aujourd'hui
Write-Host "📥 Récupération des logs du $today (max: $limitLogs)..." -ForegroundColor Green

$logsToday = sf apex log list --target-org devEdition --json | `
    ConvertFrom-Json | `
    Select-Object -ExpandProperty result | `
    Where-Object {$_.StartTime -like "$today*"} | `
    Select-Object -First $limitLogs

if ($logsToday.Count -eq 0) {
    Write-Host "❌ Aucun log trouvé pour aujourd'hui" -ForegroundColor Yellow
} else {
    Write-Host "✓ Trouvé $($logsToday.Count) log(s) à traiter" -ForegroundColor Green
    Write-Host ""
    
    # Télécharger chaque log
    $counter = 1
    foreach ($log in $logsToday) {
        $filename = "logs/debug-log-$($log.Id).txt"
        Write-Host "  [$counter/$($logsToday.Count)] ⬇️  $($log.Id) ($($log.StartTime))" -ForegroundColor Cyan
        sf apex get log --log-id $log.Id --target-org devEdition | Out-File $filename
        $counter++
    }
    
    Write-Host ""
    Write-Host "✓ Tous les logs téléchargés dans: $outputDir/" -ForegroundColor Green
    Write-Host "📊 Total de fichiers: $(Get-ChildItem $outputDir -File | Measure-Object).Count" -ForegroundColor Cyan
}
```

---

Avant de télécharger, créez le dossier `logs/` s'il n'existe pas :

```powershell
New-Item -ItemType Directory -Path logs -Force | Out-Null
```

---

## ✅ Étape 3 : Récupérer un log spécifique

Téléchargez le **premier log** (le plus récent) en utilisant son ID :

```powershell
# Remplacez 07Lfj000003bBxFEAU par l'ID du log que vous voulez
sf apex get log --log-id 07Lfj000003bBxFEAU --target-org devEdition | Out-File logs/debug-log-first.txt
```

**Résultat** : Le fichier `logs/debug-log-first.txt` est créé avec le contenu complet du log.

---

## ✅ Étape 4 (Optionnel) : Récupérer plusieurs logs

Pour récupérer **N logs** en une seule commande :

```powershell
# Récupérer les 5 derniers logs
sf apex log list --target-org devEdition | Select-Object -First 5 -Skip 1 | ForEach-Object {
    $logId = $_.Id
    $outputFile = "logs/debug-log-$logId.txt"
    Write-Host "Téléchargement du log : $logId..."
    sf apex get log --log-id $logId --target-org devEdition | Out-File $outputFile
}
```

---

## 🔍 Étape 5 : Analyser les logs

### Option A : Ouvrir dans VS Code
```powershell
# Ouvrir le log dans VS Code
code logs/debug-log-first.txt
```

### Option B : Rechercher un pattern spécifique
```powershell
# Chercher "INFO" dans le log
Select-String -Path "logs/debug-log-first.txt" -Pattern "INFO" | Select-Object -First 20

# Chercher "Platform Event" ou "PUBLISH_EVENT"
Select-String -Path "logs/debug-log-first.txt" -Pattern "PUBLISH_EVENT|Platform"

# Chercher les erreurs
Select-String -Path "logs/debug-log-first.txt" -Pattern "ERROR|Exception|Failed"
```

### Option C : Voir la taille du log
```powershell
Get-Item "logs/debug-log-first.txt" | Select-Object -Property Name, @{Name="SizeKB";Expression={[math]::Round($_.Length/1KB,2)}}
```

---

## 📊 Exemple Complet : Workflow d'analyse

```powershell
# 1. Aller au répertoire du projet
cd "c:\Project\salesforce_ant_57.0\sample\work\WorkItems-Service-Cloud-Integration-Lab"

# 2. Lister les logs
Write-Host "=== Logs disponibles ===" -ForegroundColor Green
sf apex log list --target-org devEdition | Select-Object -First 15

# 3. Créer le dossier logs
New-Item -ItemType Directory -Path logs -Force | Out-Null
Write-Host "✓ Dossier 'logs' créé/vérifié" -ForegroundColor Green

# 4. Télécharger le premier log
$firstLogId = (sf apex log list --target-org devEdition | Select-Object -Skip 1 | Select-Object -First 1 | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
Write-Host "Téléchargement du log : $firstLogId..." -ForegroundColor Yellow

sf apex get log --log-id 07Lfj000003bBxFEAU --target-org devEdition | Out-File logs/debug-log-latest.txt
Write-Host "✓ Log téléchargé : logs/debug-log-latest.txt" -ForegroundColor Green

# 5. Afficher les stats
$size = Get-Item "logs/debug-log-latest.txt" | Select-Object -ExpandProperty Length
Write-Host "Taille du log : $([math]::Round($size/1KB,2)) KB" -ForegroundColor Cyan

# 6. Ouvrir dans VS Code
code logs/debug-log-latest.txt
```

---

## 🎯 Commandes rapides utiles

| Action | Commande |
|--------|----------|
| **Lister logs** | `sf apex log list --target-org devEdition` |
| **Récupérer 1 log** | `sf apex get log --log-id <ID> --target-org devEdition` |
| **Compter les lignes** | `(Get-Content logs/debug-log-first.txt).Count` |
| **Chercher un motif** | `Select-String -Path "logs/*.txt" -Pattern "INFO"` |
| **Supprimer les anciens logs** | `Remove-Item logs/*.txt` |
| **Trier par date** | `Get-ChildItem logs/ -File \| Sort-Object LastWriteTime -Descending` |

---

## 🔑 Points clés à retenir

✅ **Les logs contiennent** :
- Tous les appels de méthode (METHOD_ENTRY/EXIT)
- Les assignations de variables (VARIABLE_ASSIGNMENT)
- Les allocations de mémoire (HEAP_ALLOCATE)
- Les debug statements (USER_DEBUG)
- Les événements système (SYSTEM_MODE_ENTER/EXIT)
- Les limites utilisées (LIMIT_USAGE)

✅ **Format du log** : 
```
[HH:MM:SS.mmm] (TIMING_IN_NANOSECONDS) | EVENT_TYPE | ...details...
```

✅ **Pour trouver des infos spécifiques** :
- `USER_DEBUG` = vos System.debug()
- `PUBLISH_EVENT` = événements Platform publiés
- `EXCEPTION` = erreurs levées
- `SOQL_EXECUTE_BEGIN/END` = requêtes SOQL
- `DML_BEGIN/END` = opérations DML

---

## ⚠️ Limitations connues

- Les logs ne persistent que **24 heures** dans Salesforce
- La taille maximale du log est **~2 MB**
- Les Platform Events ne sont **pas loggés en détail** dans ces logs
- Pour tracer les Platform Events, utilisez une **Trigger** sur l'objet événement

---

## 🚀 Prochaines étapes

Après avoir récupéré les logs :

1. **Chercher des patterns** : `USER_DEBUG`, `METHOD_ENTRY`, `EXCEPTION`
2. **Analyser la performance** : Vérifier `LIMIT_USAGE` à la fin
3. **Valider les appels** : Confirmer que vos méthodes sont exécutées
4. **Déboguer les erreurs** : Chercher les stack traces

---

**Version** : 1.0  
**Créée le** : 2025-12-24  
**Auteur** : GitHub Copilot
