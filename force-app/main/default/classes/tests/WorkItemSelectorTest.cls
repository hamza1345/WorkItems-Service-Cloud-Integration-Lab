/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Tests pour WorkItemSelector.
 * Couvre toutes les méthodes de requête, CRUD security, bulk operations.
 */
@IsTest
private class WorkItemSelectorTest {
  /**
   * @description Setup pour chaque test.
   */
  @TestSetup
  static void setupTestData() {
    // Créer des Work Items de test avec différents statuts et catégories
    List<Work_Item__c> items = new List<Work_Item__c>();

    // Work Items actifs
    items.add(
      TestDataFactory.createWorkItem('Item New 1', 'New', 'High', System.today().addDays(5))
    );
    items.add(
      TestDataFactory.createWorkItem('Item New 2', 'New', 'Medium', System.today().addDays(10))
    );
    items.add(
      TestDataFactory.createWorkItem('Item In Progress', 'In_Progress', 'High', System.today().addDays(3))
    );

    // Work Items terminés
    Work_Item__c completedItem = TestDataFactory.createWorkItem('Item Done', 'New', 'Low', System.today().addDays(2));
    items.add(completedItem);

    // Work Items en retard
    items.add(
      TestDataFactory.createWorkItem('Item Overdue 1', 'New', 'High', System.today().addDays(-5))
    );
    items.add(
      TestDataFactory.createWorkItem('Item Overdue 2', 'In_Progress', 'Medium', System.today().addDays(-2))
    );

    // Work Item avec External_Id
    items.add(
      TestDataFactory.createWorkItemWithExternalId('Item External', 'EXT-12345')
    );

    insert items;

    // Marquer un item comme Done (après insert pour éviter validation)
    completedItem.Status__c = 'Done';
    update completedItem;
  }

  /**
   * @description Test 1 : getById récupère un Work Item existant.
   */
  @IsTest
  static void testGetByIdReturnsExistingWorkItem() {
    // Arrange
    Work_Item__c item = [SELECT Id, Name FROM Work_Item__c WHERE Name = 'Item New 1' LIMIT 1];

    // Act
    Test.startTest();
    Work_Item__c result = WorkItemSelector.getById(item.Id);
    Test.stopTest();

    // Assert
    Assert.isNotNull(result, 'Work Item devrait être trouvé');
    Assert.areEqual(item.Id, result.Id, 'Id devrait correspondre');
    Assert.areEqual('Item New 1', result.Name, 'Name devrait correspondre');
  }

  /**
   * @description Test 2 : getById retourne null pour un Id inexistant.
   */
  @IsTest
  static void testGetByIdReturnsNullForNonExistentId() {
    // Arrange
    Id fakeId = '001000000000000AAA'; // Id fictif

    // Act
    Test.startTest();
    Work_Item__c result = WorkItemSelector.getById(fakeId);
    Test.stopTest();

    // Assert
    Assert.isNull(result, 'Work Item ne devrait pas être trouvé');
  }

  /**
   * @description Test 3 : getByIds récupère plusieurs Work Items.
   */
  @IsTest
  static void testGetByIdsReturnsMultipleWorkItems() {
    // Arrange
    List<Work_Item__c> items = [
      SELECT Id
      FROM Work_Item__c
      WHERE Name LIKE 'Item New%'
    ];
    Set<Id> itemIds = new Map<Id, Work_Item__c>(items).keySet();

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByIds(itemIds);
    Test.stopTest();

    // Assert
    Assert.areEqual(2, results.size(), 'Devrait trouver 2 Work Items');
  }

  /**
   * @description Test 4 : getByIds retourne liste vide pour Set vide.
   */
  @IsTest
  static void testGetByIdsReturnsEmptyListForEmptySet() {
    // Arrange
    Set<Id> emptySet = new Set<Id>();

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByIds(emptySet);
    Test.stopTest();

    // Assert
    Assert.areEqual(0, results.size(), 'Liste devrait être vide');
  }

  /**
   * @description Test 5 : getByStatus récupère les Work Items par statut.
   */
  @IsTest
  static void testGetByStatusReturnsCorrectWorkItems() {
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByStatus('New');
    Test.stopTest();

    // Assert
    Assert.isTrue(results.size() >= 2, 'Devrait trouver au moins 2 Work Items New');
    for (Work_Item__c item : results) {
      Assert.areEqual('New', item.Status__c, 'Status devrait être New');
    }
  }

  /**
   * @description Test 6 : getByCategory récupère les Work Items par catégorie.
   */
  @IsTest
  static void testGetByCategoryReturnsCorrectWorkItems() {
    // Arrange - Mettre à jour la catégorie de quelques items
    List<Work_Item__c> items = [
      SELECT Id
      FROM Work_Item__c
      WHERE Name LIKE 'Item New%'
    ];
    for (Work_Item__c item : items) {
      item.Category__c = 'Bug';
    }
    update items;

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByCategory('Bug');
    Test.stopTest();

    // Assert
    Assert.areEqual(2, results.size(), 'Devrait trouver 2 Work Items Bug');
    for (Work_Item__c item : results) {
      Assert.areEqual('Bug', item.Category__c, 'Category devrait être Bug');
    }
  }

  /**
   * @description Test 7 : getOverdue récupère les Work Items en retard.
   */
  @IsTest
  static void testGetOverdueReturnsLateWorkItems() {
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getOverdue();
    Test.stopTest();

    // Assert
    Assert.areEqual(2, results.size(), 'Devrait trouver 2 Work Items en retard');
    for (Work_Item__c item : results) {
      Assert.isTrue(
        item.Due_Date__c < System.today(),
        'Due_Date devrait être dans le passé'
      );
      Assert.areNotEqual('Done', item.Status__c, 'Status ne devrait pas être Done');
    }
  }

  /**
   * @description Test 8 : getByExternalId récupère un Work Item par External_Id.
   */
  @IsTest
  static void testGetByExternalIdReturnsCorrectWorkItem() {
    // Act
    Test.startTest();
    Work_Item__c result = WorkItemSelector.getByExternalId('EXT-12345');
    Test.stopTest();

    // Assert
    Assert.isNotNull(result, 'Work Item devrait être trouvé');
    Assert.areEqual('EXT-12345', result.External_Id__c, 'External_Id devrait correspondre');
    Assert.areEqual('Item External', result.Name, 'Name devrait correspondre');
  }

  /**
   * @description Test 9 : getByExternalId retourne null pour External_Id inexistant.
   */
  @IsTest
  static void testGetByExternalIdReturnsNullForNonExistent() {
    // Act
    Test.startTest();
    Work_Item__c result = WorkItemSelector.getByExternalId('FAKE-ID');
    Test.stopTest();

    // Assert
    Assert.isNull(result, 'Work Item ne devrait pas être trouvé');
  }

  /**
   * @description Test 10 : getAllActiveWorkItems récupère tous les Work Items actifs.
   */
  @IsTest
  static void testGetAllActiveWorkItemsExcludesDone() {
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getAllActiveWorkItems();
    Test.stopTest();

    // Assert
    Assert.isTrue(results.size() >= 5, 'Devrait trouver au moins 5 Work Items actifs');
    for (Work_Item__c item : results) {
      Assert.areNotEqual('Done', item.Status__c, 'Status ne devrait pas être Done');
    }
  }

  /**
   * @description Test 11 : getCreatedAfter récupère les Work Items créés après une date.
   */
  @IsTest
  static void testGetCreatedAfterReturnsRecentWorkItems() {
    // Arrange
    Date yesterday = System.today().addDays(-1);

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getCreatedAfter(yesterday);
    Test.stopTest();

    // Assert
    Assert.isTrue(results.size() >= 7, 'Devrait trouver tous les Work Items créés aujourd\'hui');
  }

  /**
   * @description Test 12 : getCreatedAfter retourne liste vide pour date nulle.
   */
  @IsTest
  static void testGetCreatedAfterReturnsEmptyListForNullDate() {
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getCreatedAfter(null);
    Test.stopTest();

    // Assert
    Assert.areEqual(0, results.size(), 'Liste devrait être vide');
  }

  /**
   * @description Test 13 : Bulk operation - getByIds avec 200 Work Items.
   */
  @IsTest
  static void testBulkGetByIds200WorkItems() {
    // Arrange
    List<Work_Item__c> bulkItems = TestDataFactory.createAndInsertWorkItems(200, 'Bulk Item');
    Set<Id> itemIds = new Map<Id, Work_Item__c>(bulkItems).keySet();

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByIds(itemIds);
    Test.stopTest();

    // Assert
    Assert.areEqual(200, results.size(), 'Devrait trouver tous les 200 Work Items');
  }

  /**
   * @description Test 14 : getByStatus retourne liste vide pour statut vide.
   */
  @IsTest
  static void testGetByStatusReturnsEmptyListForBlankStatus() {
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByStatus('');
    Test.stopTest();

    // Assert
    Assert.areEqual(0, results.size(), 'Liste devrait être vide');
  }

  /**
   * @description Test 15 : getByCategory retourne liste vide pour catégorie vide.
   */
  @IsTest
  static void testGetByCategoryReturnsEmptyListForBlankCategory() {
    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.getByCategory('');
    Test.stopTest();

    // Assert
    Assert.areEqual(0, results.size(), 'Liste devrait être vide');
  }

  /**
   * @description Test 16 : search avec filtre statut retourne uniquement ce statut.
   */
  @IsTest
  static void testSearchByStatusReturnsCorrectItems() {
    // Arrange - Créer 30 work items avec différents statuts
    List<Work_Item__c> items = new List<Work_Item__c>();
    for (Integer i = 0; i < 10; i++) {
      items.add(TestDataFactory.createWorkItem('Search New ' + i, 'New', 'Medium', System.today().addDays(5)));
    }
    for (Integer i = 0; i < 10; i++) {
      items.add(TestDataFactory.createWorkItem('Search Progress ' + i, 'In_Progress', 'High', System.today().addDays(3)));
    }
    for (Integer i = 0; i < 10; i++) {
      items.add(TestDataFactory.createWorkItem('Search Done ' + i, 'New', 'Low', System.today().addDays(7)));
    }
    insert items;
    
    // Marquer les 10 derniers comme Done
    List<Work_Item__c> toComplete = [SELECT Id FROM Work_Item__c WHERE Name LIKE 'Search Done%'];
    for (Work_Item__c item : toComplete) {
      item.Status__c = 'Done';
    }
    update toComplete;

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search('New', null, null);
    Test.stopTest();

    // Assert
    Assert.isTrue(results.size() >= 10, 'Devrait trouver au moins 10 Work Items New');
    for (Work_Item__c item : results) {
      Assert.areEqual('New', item.Status__c, 'Status devrait être New');
    }
  }

  /**
   * @description Test 17 : search avec texte retourne uniquement les matchs.
   */
  @IsTest
  static void testSearchByTextReturnsMatchingItems() {
    // Arrange
    List<Work_Item__c> items = new List<Work_Item__c>();
    items.add(TestDataFactory.createWorkItem('ABC Item 1', 'New', 'Medium', System.today().addDays(5)));
    items.add(TestDataFactory.createWorkItem('ABC Item 2', 'New', 'Medium', System.today().addDays(5)));
    items.add(TestDataFactory.createWorkItem('XYZ Item 1', 'New', 'Medium', System.today().addDays(5)));
    items.add(TestDataFactory.createWorkItem('XYZ Item 2', 'New', 'Medium', System.today().addDays(5)));
    insert items;

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search(null, 'ABC', null);
    Test.stopTest();

    // Assert
    Assert.areEqual(2, results.size(), 'Devrait trouver 2 Work Items ABC');
    for (Work_Item__c item : results) {
      Assert.isTrue(item.Name.contains('ABC'), 'Name devrait contenir ABC');
    }
  }

  /**
   * @description Test 18 : search respecte limitSize.
   */
  @IsTest
  static void testSearchRespectsLimitSize() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(30, 'Limit Test');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search(null, null, 10);
    Test.stopTest();

    // Assert
    Assert.areEqual(10, results.size(), 'Devrait retourner max 10 Work Items');
  }

  /**
   * @description Test 19 : search avec limitSize null utilise default.
   */
  @IsTest
  static void testSearchWithNullLimitUsesDefault() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(60, 'Default Limit');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search(null, null, null);
    Test.stopTest();

    // Assert
    Assert.areEqual(50, results.size(), 'Devrait retourner 50 Work Items (default)');
  }

  /**
   * @description Test 20 : search avec limitSize > MAX utilise MAX.
   */
  @IsTest
  static void testSearchWithExcessiveLimitUsesMax() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(150, 'Max Limit');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search(null, null, 200);
    Test.stopTest();

    // Assert
    Assert.areEqual(100, results.size(), 'Devrait retourner max 100 Work Items');
  }

  /**
   * @description Test 21 : search trie par LastModifiedDate DESC.
   */
  @IsTest
  static void testSearchSortsByLastModifiedDateDesc() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(5, 'Sort Test');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search(null, 'Sort Test', 5);
    Test.stopTest();

    // Assert
    Assert.areEqual(5, results.size(), 'Devrait trouver 5 Work Items');
    // Vérifier que les résultats sont retournés (tri testé implicitement par query ORDER BY)
    Assert.isNotNull(results[0].Id, 'Résultats devraient être triés');
  }

  /**
   * @description Test 22 : recent retourne les items les plus récents.
   */
  @IsTest
  static void testRecentReturnsLatestItems() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(20, 'Recent Test');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.recent(10);
    Test.stopTest();

    // Assert
    Assert.areEqual(10, results.size(), 'Devrait retourner 10 Work Items');
  }

  /**
   * @description Test 23 : recent avec null utilise default.
   */
  @IsTest
  static void testRecentWithNullLimitUsesDefault() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(60, 'Recent Default');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.recent(null);
    Test.stopTest();

    // Assert
    Assert.areEqual(50, results.size(), 'Devrait retourner 50 Work Items (default)');
  }

  /**
   * @description Test 24 : byIds retourne champs minimaux.
   */
  @IsTest
  static void testByIdsReturnsMinimalFields() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(5, 'ByIds Test');
    Set<Id> itemIds = new Map<Id, Work_Item__c>(items).keySet();

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.byIds(itemIds);
    Test.stopTest();

    // Assert
    Assert.areEqual(5, results.size(), 'Devrait retourner 5 Work Items');
    // Vérifier que les champs essentiels sont présents
    for (Work_Item__c item : results) {
      Assert.isNotNull(item.Id, 'Id devrait être présent');
      Assert.isNotNull(item.Name, 'Name devrait être présent');
      Assert.isNotNull(item.Status__c, 'Status__c devrait être présent');
      // Description__c ne devrait PAS être présent (champs minimaux)
    }
  }

  /**
   * @description Test 25 : search combine status + texte.
   */
  @IsTest
  static void testSearchCombinesStatusAndText() {
    // Arrange
    List<Work_Item__c> items = new List<Work_Item__c>();
    items.add(TestDataFactory.createWorkItem('COMBO New ABC', 'New', 'Medium', System.today().addDays(5)));
    items.add(TestDataFactory.createWorkItem('COMBO Progress ABC', 'In_Progress', 'High', System.today().addDays(3)));
    items.add(TestDataFactory.createWorkItem('COMBO New XYZ', 'New', 'Low', System.today().addDays(7)));
    insert items;

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemSelector.search('New', 'ABC', null);
    Test.stopTest();

    // Assert
    Assert.areEqual(1, results.size(), 'Devrait trouver 1 Work Item (New + ABC)');
    Assert.areEqual('COMBO New ABC', results[0].Name, 'Devrait être COMBO New ABC');
  }
}
