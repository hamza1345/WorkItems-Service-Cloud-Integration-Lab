/**
 * @description Script pour auditer performances WorkItemService
 * Exécuter dans Execute Anonymous Apex
 * 
 * Scénarios testés:
 * 1. Création bulk 200 Work Items
 * 2. getItems() avec filtres
 * 3. markDone() sur 10 items
 */

// Activer logging temporairement (optionnel)
System.debug('=== DÉBUT AUDIT PERFORMANCES ===');

// --- SCÉNARIO 1: Création bulk 200 Work Items ---
System.debug('\n--- SCÉNARIO 1: Création 200 Work Items ---');
Long startTime1 = System.currentTimeMillis();
Integer cpuStart1 = Limits.getCpuTime();
Integer soqlStart1 = Limits.getQueries();

List<Work_Item__c> bulkItems = new List<Work_Item__c>();
for (Integer i = 0; i < 200; i++) {
  bulkItems.add(new Work_Item__c(
    Name = 'Perf Test Item ' + i,
    Description__c = 'Performance audit test',
    Category__c = 'Development',
    Priority__c = (Math.mod(i, 3) == 0) ? 'High' : 'Medium',
    Due_Date__c = System.today().addDays(i),
    Status__c = 'New'
  ));
}
insert bulkItems;

Long elapsedTime1 = System.currentTimeMillis() - startTime1;
Integer cpuUsed1 = Limits.getCpuTime() - cpuStart1;
Integer soqlUsed1 = Limits.getQueries() - soqlStart1;

System.debug('✅ 200 Work Items créés en ' + elapsedTime1 + 'ms');
System.debug('   CPU Time: ' + cpuUsed1 + 'ms');
System.debug('   SOQL Queries: ' + soqlUsed1);
System.debug('   Rows: ' + Limits.getQueryRows());

// --- SCÉNARIO 2: getItems() avec statut New ---
System.debug('\n--- SCÉNARIO 2: getItems(status=New, limit=50) ---');
Long startTime2 = System.currentTimeMillis();
Integer cpuStart2 = Limits.getCpuTime();
Integer soqlStart2 = Limits.getQueries();

List<Work_Item__c> results = WorkItemService.getItems('New', null, 50);

Long elapsedTime2 = System.currentTimeMillis() - startTime2;
Integer cpuUsed2 = Limits.getCpuTime() - cpuStart2;
Integer soqlUsed2 = Limits.getQueries() - soqlStart2;

System.debug('✅ ' + results.size() + ' Work Items récupérés en ' + elapsedTime2 + 'ms');
System.debug('   CPU Time: ' + cpuUsed2 + 'ms');
System.debug('   SOQL Queries: ' + soqlUsed2);

// --- SCÉNARIO 3: getItems() recherche par texte ---
System.debug('\n--- SCÉNARIO 3: getItems(searchTerm=Perf) ---');
Long startTime3 = System.currentTimeMillis();
Integer cpuStart3 = Limits.getCpuTime();
Integer soqlStart3 = Limits.getQueries();

List<Work_Item__c> searchResults = WorkItemService.getItems(null, 'Perf', 50);

Long elapsedTime3 = System.currentTimeMillis() - startTime3;
Integer cpuUsed3 = Limits.getCpuTime() - cpuStart3;
Integer soqlUsed3 = Limits.getQueries() - soqlStart3;

System.debug('✅ ' + searchResults.size() + ' Work Items trouvés en ' + elapsedTime3 + 'ms');
System.debug('   CPU Time: ' + cpuUsed3 + 'ms');
System.debug('   SOQL Queries: ' + soqlUsed3);

// --- SCÉNARIO 4: markDone() sur 10 items ---
System.debug('\n--- SCÉNARIO 4: markDone() x10 ---');
Long startTime4 = System.currentTimeMillis();
Integer cpuStart4 = Limits.getCpuTime();
Integer soqlStart4 = Limits.getQueries();

List<Work_Item__c> itemsToMark = [SELECT Id FROM Work_Item__c WHERE Name LIKE 'Perf Test Item%' LIMIT 10];
Integer successCount = 0;
for (Work_Item__c item : itemsToMark) {
  try {
    WorkItemService.markDone(item.Id);
    successCount++;
  } catch (Exception e) {
    System.debug('⚠️ Erreur markDone: ' + e.getMessage());
  }
}

Long elapsedTime4 = System.currentTimeMillis() - startTime4;
Integer cpuUsed4 = Limits.getCpuTime() - cpuStart4;
Integer soqlUsed4 = Limits.getQueries() - soqlStart4;

System.debug('✅ ' + successCount + ' Work Items marqués Done en ' + elapsedTime4 + 'ms');
System.debug('   CPU Time: ' + cpuUsed4 + 'ms');
System.debug('   SOQL Queries: ' + soqlUsed4);

// --- RÉSUMÉ GLOBAL ---
System.debug('\n=== RÉSUMÉ AUDIT PERFORMANCES ===');
System.debug('Total CPU Time: ' + Limits.getCpuTime() + 'ms / ' + Limits.getLimitCpuTime() + 'ms');
System.debug('Total SOQL Queries: ' + Limits.getQueries() + ' / ' + Limits.getLimitQueries());
System.debug('Total Query Rows: ' + Limits.getQueryRows() + ' / ' + Limits.getLimitQueryRows());
System.debug('Total DML Statements: ' + Limits.getDmlStatements() + ' / ' + Limits.getLimitDmlStatements());
System.debug('Total DML Rows: ' + Limits.getDmlRows() + ' / ' + Limits.getLimitDmlRows());

System.debug('\n=== FIN AUDIT PERFORMANCES ===');
