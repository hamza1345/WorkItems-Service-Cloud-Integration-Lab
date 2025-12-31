/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Tests pour WorkItemService.
 * Couvre l'orchestration métier, transactions, validations, gestion d'erreurs.
 */
@IsTest
private class WorkItemServiceTest {
  /**
   * @description Setup pour chaque test.
   */
  @TestSetup
  static void setupTestData() {
    // Mock FeatureFlags pour activer l'automation
    Logging_Settings__mdt mockSettings = new Logging_Settings__mdt(
      Enable_Logging__c = true,
      Persist_Logs__c = false,
      Disable_Automation__c = false
    );
    FeatureFlags.hasInitialized = false;
    FeatureFlags.cachedSettings = mockSettings;
    FeatureFlags.hasInitialized = true;
  }

  /**
   * @description Test 1 : createWorkItem crée un nouveau Work Item avec succès.
   */
  @IsTest
  static void testCreateWorkItemSuccess() {
    // Act
    Test.startTest();
    Work_Item__c result = WorkItemService.createWorkItem(
      'Test Work Item',
      'Description test',
      'Development',
      'High',
      System.today().addDays(7)
    );
    Test.stopTest();

    // Assert
    Assert.isNotNull(result, 'Work Item devrait être créé');
    Assert.isNotNull(result.Id, 'Work Item devrait avoir un Id');
    Assert.areEqual('Test Work Item', result.Name);
    Assert.areEqual('New', result.Status__c, 'Status devrait être New par défaut');
    Assert.areEqual('High', result.Priority__c);
  }

  /**
   * @description Test 2 : createWorkItemWithExternalId crée avec External_Id.
   */
  @IsTest
  static void testCreateWorkItemWithExternalIdSuccess() {
    // Act
    Test.startTest();
    Work_Item__c result = WorkItemService.createWorkItemWithExternalId(
      'External Work Item',
      'From external system',
      'EXT-12345'
    );
    Test.stopTest();

    // Assert
    Assert.isNotNull(result, 'Work Item devrait être créé');
    Assert.areEqual('EXT-12345', result.External_Id__c);
    Assert.areEqual('External Work Item', result.Name);
  }

  /**
   * @description Test 3 : createWorkItemWithExternalId rejette les doublons.
   */
  @IsTest
  static void testCreateWorkItemWithExternalIdRejectsDuplicate() {
    // Arrange
    WorkItemService.createWorkItemWithExternalId(
      'First Item',
      'Description',
      'EXT-999'
    );

    // Act & Assert
    try {
      Test.startTest();
      WorkItemService.createWorkItemWithExternalId(
        'Duplicate Item',
        'Description',
        'EXT-999'
      );
      Test.stopTest();
      Assert.fail('Une exception devrait être levée pour External_Id dupliqué');
    } catch (WorkItemService.WorkItemServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('existe déjà'),
        'Message devrait mentionner doublon'
      );
    }
  }

  /**
   * @description Test 4 : updateWorkItem met à jour les champs avec succès.
   */
  @IsTest
  static void testUpdateWorkItemSuccess() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Update',
      'Original description',
      'Bug',
      'Low',
      System.today().addDays(5)
    );

    Map<String, Object> updates = new Map<String, Object>{
      'Priority__c' => 'High',
      'Description__c' => 'Updated description'
    };

    // Act
    Test.startTest();
    Work_Item__c result = WorkItemService.updateWorkItem(item.Id, updates);
    Test.stopTest();

    // Assert
    Assert.areEqual('High', result.Priority__c, 'Priority devrait être High');
    Assert.areEqual(
      'Updated description',
      result.Description__c,
      'Description devrait être mise à jour'
    );
  }

  /**
   * @description Test 5 : updateWorkItem rejette Work Item inexistant.
   */
  @IsTest
  static void testUpdateWorkItemRejectsNonExistent() {
    // Arrange
    Id fakeId = '001000000000000AAA';
    Map<String, Object> updates = new Map<String, Object>{
      'Priority__c' => 'High'
    };

    // Act & Assert
    try {
      Test.startTest();
      WorkItemService.updateWorkItem(fakeId, updates);
      Test.stopTest();
      Assert.fail('Une exception devrait être levée pour Id inexistant');
    } catch (WorkItemService.WorkItemServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('non trouvé'),
        'Message devrait mentionner Work Item non trouvé'
      );
    }
  }

  /**
   * @description Test 6 : updateStatus change le statut avec succès.
   */
  @IsTest
  static void testUpdateStatusSuccess() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Status Change',
      'Description',
      'Development',
      'Medium',
      System.today().addDays(10)
    );

    // Act
    Test.startTest();
    Work_Item__c result = WorkItemService.updateStatus(item.Id, 'In_Progress');
    Test.stopTest();

    // Assert
    Assert.areEqual('In_Progress', result.Status__c, 'Status devrait être In_Progress');
  }

  /**
   * @description Test 7 : updateStatus remplit Completed_On quand Done.
   */
  @IsTest
  static void testUpdateStatusToDoneSetsCompletedOn() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Complete',
      'Description',
      'Development',
      'Medium',
      System.today().addDays(10)
    );

    // Passer d'abord en In_Progress (transition valide)
    WorkItemService.updateStatus(item.Id, 'In_Progress');

    // Act
    Test.startTest();
    Work_Item__c result = WorkItemService.updateStatus(item.Id, 'Done');
    Test.stopTest();

    // Assert
    Assert.areEqual('Done', result.Status__c, 'Status devrait être Done');
    Assert.isNotNull(
      result.Completed_On__c,
      'Completed_On devrait être rempli'
    );
  }

  /**
   * @description Test 8 : completeWorkItem marque comme Done.
   */
  @IsTest
  static void testCompleteWorkItemSuccess() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Completion',
      'Description',
      'Development',
      'Medium',
      System.today().addDays(10)
    );

    // Passer d'abord en In_Progress (transition valide)
    WorkItemService.updateStatus(item.Id, 'In_Progress');

    // Act
    Test.startTest();
    Work_Item__c result = WorkItemService.completeWorkItem(item.Id);
    Test.stopTest();

    // Assert
    Assert.areEqual('Done', result.Status__c, 'Status devrait être Done');
    Assert.isNotNull(result.Completed_On__c, 'Completed_On devrait être rempli');
  }

  /**
   * @description Test 9 : deleteWorkItem supprime avec succès.
   */
  @IsTest
  static void testDeleteWorkItemSuccess() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Delete',
      'Description',
      'Development',
      'Medium',
      System.today().addDays(10)
    );

    // Act
    Test.startTest();
    WorkItemService.deleteWorkItem(item.Id);
    Test.stopTest();

    // Assert
    Work_Item__c deleted = WorkItemSelector.getById(item.Id);
    Assert.isNull(deleted, 'Work Item devrait être supprimé');
  }

  /**
   * @description Test 10 : deleteWorkItem rejette suppression de Work Item Done.
   */
  @IsTest
  static void testDeleteWorkItemRejectsDone() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Delete Done',
      'Description',
      'Development',
      'Medium',
      System.today().addDays(10)
    );
    // Passer d'abord en In_Progress puis Done (transitions valides)
    WorkItemService.updateStatus(item.Id, 'In_Progress');
    WorkItemService.completeWorkItem(item.Id);

    // Act & Assert
    try {
      Test.startTest();
      WorkItemService.deleteWorkItem(item.Id);
      Test.stopTest();
      Assert.fail('Une exception devrait être levée pour Work Item Done');
    } catch (WorkItemService.WorkItemServiceException e) {
      Assert.isTrue(
        e.getMessage().contains('terminé'),
        'Message devrait mentionner Work Item terminé'
      );
    }
  }

  /**
   * @description Test 11 : bulkUpdateWorkItems met à jour plusieurs Work Items.
   */
  @IsTest
  static void testBulkUpdateWorkItemsSuccess() {
    // Arrange
    List<Work_Item__c> items = new List<Work_Item__c>();
    for (Integer i = 0; i < 5; i++) {
      items.add(
        WorkItemService.createWorkItem(
          'Bulk Item ' + i,
          'Description',
          'Development',
          'Low',
          System.today().addDays(10)
        )
      );
    }

    Set<Id> itemIds = new Map<Id, Work_Item__c>(items).keySet();
    Map<String, Object> updates = new Map<String, Object>{
      'Priority__c' => 'High'
    };

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemService.bulkUpdateWorkItems(
      itemIds,
      updates
    );
    Test.stopTest();

    // Assert
    Assert.areEqual(5, results.size(), 'Devrait mettre à jour 5 Work Items');
    for (Work_Item__c item : results) {
      Assert.areEqual('High', item.Priority__c, 'Priority devrait être High');
    }
  }

  /**
   * @description Test 12 : bulkUpdateWorkItems avec 200 Work Items.
   */
  @IsTest
  static void testBulkUpdate200WorkItems() {
    // Arrange
    List<Work_Item__c> items = TestDataFactory.createAndInsertWorkItems(
      200,
      'Bulk Item'
    );
    Set<Id> itemIds = new Map<Id, Work_Item__c>(items).keySet();
    Map<String, Object> updates = new Map<String, Object>{
      'Category__c' => 'Enhancement'
    };

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemService.bulkUpdateWorkItems(
      itemIds,
      updates
    );
    Test.stopTest();

    // Assert
    Assert.areEqual(200, results.size(), 'Devrait mettre à jour 200 Work Items');
    for (Work_Item__c item : results) {
      Assert.areEqual(
        'Enhancement',
        item.Category__c,
        'Category devrait être Enhancement'
      );
    }
  }

  /**
   * @description Test 13 : getOverdueWorkItems récupère les Work Items en retard.
   */
  @IsTest
  static void testGetOverdueWorkItemsSuccess() {
    // Arrange
    TestDataFactory.createAndInsertWorkItems(3, 'Overdue Item');
    
    // Mettre à jour les dates pour les rendre en retard
    List<Work_Item__c> items = [SELECT Id FROM Work_Item__c];
    for (Work_Item__c item : items) {
      item.Due_Date__c = System.today().addDays(-5);
    }
    update items;

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemService.getOverdueWorkItems();
    Test.stopTest();

    // Assert
    Assert.areEqual(3, results.size(), 'Devrait trouver 3 Work Items en retard');
  }

  /**
   * @description Test 14 : getActiveWorkItems récupère les Work Items actifs.
   */
  @IsTest
  static void testGetActiveWorkItemsSuccess() {
    // Arrange
    TestDataFactory.createAndInsertWorkItems(5, 'Active Item');

    // Act
    Test.startTest();
    List<Work_Item__c> results = WorkItemService.getActiveWorkItems();
    Test.stopTest();

    // Assert
    Assert.areEqual(
      5,
      results.size(),
      'Devrait trouver 5 Work Items actifs'
    );
    for (Work_Item__c item : results) {
      Assert.areNotEqual('Done', item.Status__c, 'Status ne devrait pas être Done');
    }
  }

  /**
   * @description Test 15 : Transaction rollback en cas d'erreur.
   */
  @IsTest
  static void testTransactionRollbackOnError() {
    // Arrange
    Work_Item__c item = WorkItemService.createWorkItem(
      'Test Rollback',
      'Description',
      'Development',
      'Medium',
      System.today().addDays(10)
    );

    // Créer des updates invalides (date passée + Done)
    Map<String, Object> badUpdates = new Map<String, Object>{
      'Status__c' => 'Done',
      'Due_Date__c' => System.today().addDays(-5)
    };

    // Act & Assert
    try {
      Test.startTest();
      WorkItemService.updateWorkItem(item.Id, badUpdates);
      Test.stopTest();
      Assert.fail('Une exception devrait être levée pour validation échouée');
    } catch (Exception e) {
      // Vérifier que l'enregistrement n'a pas été modifié
      Work_Item__c unchanged = WorkItemSelector.getById(item.Id);
      Assert.areEqual('New', unchanged.Status__c, 'Status ne devrait pas changer');
    }
  }
}
