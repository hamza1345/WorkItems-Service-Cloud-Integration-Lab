/**
 * @description Test class for LoggerFactory.
 * Tests: Logger creation, configuration from FeatureFlags.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class LoggerFactoryTest {

  @IsTest
  static void testGetLoggerBasic() {
    // Act
    Logger logger = LoggerFactory.getLogger('TestClass');

    // Assert
    Assert.isNotNull(logger, 'Logger should be created');
    Assert.areEqual(0, logger.getEntryCount(), 'Should start empty');
  }

  @IsTest
  static void testGetLoggerWithContext() {
    // Arrange
    LogContext customContext = new LogContext().setSource('CustomClass', 'customMethod');

    // Act
    Logger logger = LoggerFactory.getLogger('TestClass', customContext);

    // Assert
    Assert.isNotNull(logger, 'Logger should be created');
    logger.info('method', 'Test');
    LogEntry entry = logger.getEntries()[0];
    Assert.areEqual('CustomClass', entry.getContext().getClassName());
  }

  @IsTest
  static void testGetLoggerMultipleInstances() {
    // Act
    Logger logger1 = LoggerFactory.getLogger('Class1');
    Logger logger2 = LoggerFactory.getLogger('Class2');

    // Assert
    Assert.isNotNull(logger1);
    Assert.isNotNull(logger2);
    Assert.areNotEqual(logger1, logger2, 'Should create different instances');
  }

  @IsTest
  static void testGetLoggerConfiguresMinLevel() {
    // This test verifies that the factory configures based on FeatureFlags
    // Arrange & Act
    Logger logger = LoggerFactory.getLogger('TestClass');

    // Log at different levels
    logger
      .debug('method', 'Debug')
      .info('method', 'Info')
      .warn('method', 'Warn')
      .error('method', 'Error');

    // Assert
    // Should have entries based on FeatureFlags configuration
    // Default min level from FeatureFlags should be INFO or configured value
    Assert.isTrue(logger.getEntryCount() > 0, 'Should have logged messages');
  }

  @IsTest
  static void testGetLoggerReturnsConfiguredLogger() {
    // Act
    Logger logger = LoggerFactory.getLogger('TestClass');

    // Act - Use the logger
    logger.info('method', 'Test message');

    // Assert
    Assert.areEqual(1, logger.getEntryCount(), 'Logger should be functional');
  }

  @IsTest
  static void testGetLoggerWithContextReturnsConfiguredLogger() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    Logger logger = LoggerFactory.getLogger('TestClass', context);
    logger.info('method', 'Test');

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
  }

  @IsTest
  static void testGetLoggerClassNamePropagation() {
    // Act
    Logger logger = LoggerFactory.getLogger('MyService');

    // Assert - Logger should work with the provided class name
    logger.info('method', 'Message');
    LogEntry entry = logger.getEntries()[0];
    Assert.areEqual('MyService', entry.getContext().getClassName());
  }

  @IsTest
  static void testGetLoggerDifferentClassNames() {
    // Act
    Logger logger1 = LoggerFactory.getLogger('Service1');
    Logger logger2 = LoggerFactory.getLogger('Service2');
    Logger logger3 = LoggerFactory.getLogger('Service3');

    logger1.info('m', 'msg1');
    logger2.info('m', 'msg2');
    logger3.info('m', 'msg3');

    // Assert
    Assert.areEqual('Service1', logger1.getEntries()[0].getContext().getClassName());
    Assert.areEqual('Service2', logger2.getEntries()[0].getContext().getClassName());
    Assert.areEqual('Service3', logger3.getEntries()[0].getContext().getClassName());
  }

  @IsTest
  static void testGetLoggerWithContextAndLogging() {
    // Arrange
    LogContext customContext = new LogContext()
      .setSource('CustomClass', 'customMethod')
      .addCustomData('recordId', '001xx000003DHfAAM');

    // Act
    Logger logger = LoggerFactory.getLogger('TestClass', customContext);
    logger.info('method', 'Test');

    // Assert
    LogEntry entry = logger.getEntries()[0];
    Assert.areEqual('CustomClass', entry.getContext().getClassName());
    Assert.areEqual('001xx000003DHfAAM', entry.getContext().getCustomData().get('recordId'));
  }

  @IsTest
  static void testGetLoggerIndependence() {
    // Act
    Logger logger1 = LoggerFactory.getLogger('Service1');
    Logger logger2 = LoggerFactory.getLogger('Service2');

    logger1.info('m', 'message1').info('m', 'message2');
    logger2.info('m', 'message3');

    // Assert
    Assert.areEqual(2, logger1.getEntryCount());
    Assert.areEqual(1, logger2.getEntryCount());
  }

  @IsTest
  static void testGetLoggerAllowsMethodChaining() {
    // Act
    Logger logger = LoggerFactory.getLogger('TestClass')
      .debug('m', 'd')
      .info('m', 'i')
      .warn('m', 'w');

    // Assert
    Assert.areEqual(2, logger.getEntryCount()); // DEBUG filtered by default
  }

  @IsTest
  static void testGetLoggerWithNullClassNameHandling() {
    // Act
    Logger logger = LoggerFactory.getLogger(null);

    // Assert - Should handle null gracefully
    Assert.isNotNull(logger, 'Logger should be created even with null class name');
  }

  @IsTest
  static void testGetLoggerWithEmptyClassNameHandling() {
    // Act
    Logger logger = LoggerFactory.getLogger('');

    // Assert - Should handle empty string gracefully
    Assert.isNotNull(logger, 'Logger should be created with empty class name');
  }
}
