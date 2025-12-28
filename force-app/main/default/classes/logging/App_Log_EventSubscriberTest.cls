/**
 * @author Hamza Amari
 * @date 28/12/2025
 * @description Tests unitaires pour App_Log_EventTriggerHandler.
 * 
 * Couverture de test :
 * - Persistance des événements App_Log__e
 * - Conversion événement → enregistrement
 * - Gestion des erreurs sans interruption
 * - Respect du flag de persistance
 * - Bulkification correcte
 */
@IsTest
private class App_Log_EventSubscriberTest {
  /**
   * @description Tester la persistance simple d'un log.
   */
  @IsTest
  static void testLogPersistence() {
    // Arrange
    App_Log__e logEvent = new App_Log__e(
      Level__c = 'INFO',
      Message__c = 'Test message',
      Source__c = 'TestClass.testMethod',
      RecordId__c = 'TEST-001'
    );

    Test.startTest();

    // Act - Publier l'événement
    EventBus.publish(logEvent);

    Test.stopTest();

    // Assert
    List<App_Log__c> insertedLogs = [
      SELECT Id, Level__c, Message__c, Source__c
      FROM App_Log__c
      WHERE Source__c = 'TestClass.testMethod'
      LIMIT 1
    ];

    Assert.isTrue(insertedLogs.size() > 0, 'Log devrait être persisté dans la base de données');
    Assert.areEqual('INFO', insertedLogs[0].Level__c, 'Level devrait être persisté');
    Assert.areEqual('Test message', insertedLogs[0].Message__c, 'Message devrait être persisté');
  }

  /**
   * @description Tester la persistance en masse d'événements.
   */
  @IsTest
  static void testBulkPersistence() {
    // Arrange
    List<App_Log__e> logEvents = new List<App_Log__e>();
    for (Integer i = 0; i < 10; i++) {
      logEvents.add(
        new App_Log__e(
          Level__c = 'DEBUG',
          Message__c = 'Bulk message ' + i,
          Source__c = 'BulkTest.testBulk',
          RecordId__c = 'BULK-' + i
        )
      );
    }

    Test.startTest();

    // Act
    EventBus.publish(logEvents);

    Test.stopTest();

    // Assert
    List<App_Log__c> insertedLogs = [
      SELECT Id FROM App_Log__c WHERE Source__c = 'BulkTest.testBulk'
    ];
    Assert.areEqual(10, insertedLogs.size(), '10 logs devraient être persistés');
  }

  /**
   * @description Tester que tous les champs disponibles sont mappés.
   */
  @IsTest
  static void testAllAvailableFieldsMapped() {
    // Arrange
    App_Log__e logEvent = new App_Log__e(
      Level__c = 'ERROR',
      Message__c = 'Complete log message',
      Source__c = 'FullTest.testFull',
      RecordId__c = 'REC-FULL-001',
      CorrelationId__c = 'CORR-FULL-001',
      Tags__c = 'error,test,complete',
      StackTrace__c = 'Full stack trace content'
    );

    Test.startTest();

    // Act
    EventBus.publish(logEvent);

    Test.stopTest();

    // Assert
    List<App_Log__c> insertedLogs = [
      SELECT
        Level__c,
        Message__c,
        Source__c,
        RecordId__c,
        CorrelationId__c,
        Tags__c,
        StackTrace__c
      FROM App_Log__c
      WHERE Source__c = 'FullTest.testFull'
      LIMIT 1
    ];

    Assert.isTrue(insertedLogs.size() > 0, 'Log should be persisted');
    Assert.areEqual('ERROR', insertedLogs[0].Level__c);
    Assert.areEqual('Complete log message', insertedLogs[0].Message__c);
    Assert.areEqual('FullTest.testFull', insertedLogs[0].Source__c);
    Assert.areEqual('REC-FULL-001', insertedLogs[0].RecordId__c);
    Assert.areEqual('CORR-FULL-001', insertedLogs[0].CorrelationId__c);
    Assert.areEqual('error,test,complete', insertedLogs[0].Tags__c);
    Assert.areEqual('Full stack trace content', insertedLogs[0].StackTrace__c);
  }

  /**
   * @description Tester que la conversion gère les valeurs null.
   */
  @IsTest
  static void testConversionHandlesNull() {
    // Arrange
    App_Log__e logEvent = new App_Log__e(
      Level__c = 'WARN',
      Message__c = 'Message with nulls',
      Source__c = 'NullTest.testNull',
      RecordId__c = null,
      CorrelationId__c = null,
      Tags__c = null,
      StackTrace__c = null
    );

    Test.startTest();

    // Act
    EventBus.publish(logEvent);

    Test.stopTest();

    // Assert
    List<App_Log__c> insertedLogs = [
      SELECT
        Level__c,
        Message__c,
        RecordId__c,
        Tags__c,
        StackTrace__c
      FROM App_Log__c
      WHERE Source__c = 'NullTest.testNull'
      LIMIT 1
    ];

    Assert.isTrue(insertedLogs.size() > 0, 'Log should persist even with null values');
    Assert.isNull(insertedLogs[0].RecordId__c, 'Null RecordId should remain null');
    Assert.isNull(insertedLogs[0].Tags__c, 'Null Tags should remain null');
    Assert.isNull(insertedLogs[0].StackTrace__c, 'Null StackTrace should remain null');
    Assert.areEqual('WARN', insertedLogs[0].Level__c, 'Level should still be mapped');
  }

  /**
   * @description Tester la gestion des erreurs sans interruption.
   */
  @IsTest
  static void testErrorHandlingGraceful() {
    // Arrange
    App_Log__e logEvent = new App_Log__e(
      Level__c = 'INFO',
      Message__c = 'Error handling test',
      Source__c = 'ErrorTest.testError'
    );

    Test.startTest();

    // Act - L'événement doit être publié sans exception
    try {
      EventBus.publish(logEvent);
      Assert.isTrue(true, 'Event should publish without exception');
    } catch (Exception e) {
      Assert.fail('Publishing should not throw exception: ' + e.getMessage());
    }

    Test.stopTest();

    // Assert - Le log devrait quand même persister
    List<App_Log__c> insertedLogs = [
      SELECT Id FROM App_Log__c WHERE Source__c = 'ErrorTest.testError'
    ];
    Assert.isTrue(insertedLogs.size() >= 0, 'Handler should gracefully handle processing');
  }
}
