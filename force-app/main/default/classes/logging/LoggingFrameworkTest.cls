/**
 * @description Simple test to verify logging framework compiles and works.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class LoggingFrameworkTest {

  @IsTest
  static void testLoggerCreation() {
    // Arrange
    Logger logger = LoggerFactory.getLogger('LoggingFrameworkTest');

    // Act
    logger.info('testLoggerCreation', 'Logger created successfully');

    // Assert
    Assert.isNotNull(logger, 'Logger should not be null');
    Assert.areEqual(1, logger.getEntryCount(), 'Should have one log entry');
  }

  @IsTest
  static void testLogLevels() {
    // Test log level priorities
    Assert.areEqual(0, LogLevel.getPriority('DEBUG'));
    Assert.areEqual(1, LogLevel.getPriority('INFO'));
    Assert.areEqual(2, LogLevel.getPriority('WARN'));
    Assert.areEqual(3, LogLevel.getPriority('ERROR'));
    Assert.areEqual(4, LogLevel.getPriority('FATAL'));
  }

  @IsTest
  static void testLogContext() {
    // Arrange
    LogContext context = new LogContext();

    // Act
    context.setSource('TestClass', 'testMethod');
    context.addCustomData('key', 'value');

    // Assert
    Assert.isNotNull(context.getRequestId(), 'Request ID should be generated');
    Assert.areEqual('TestClass', context.getClassName());
    Assert.areEqual('testMethod', context.getMethodName());
    Assert.isTrue(context.getCustomData().containsKey('key'));
  }

  @IsTest
  static void testMultipleLogs() {
    // Arrange
    Logger logger = LoggerFactory.getLogger('LoggingFrameworkTest');

    // Act
    logger
      .debug('testMultipleLogs', 'Debug message')
      .info('testMultipleLogs', 'Info message')
      .warn('testMultipleLogs', 'Warn message')
      .error('testMultipleLogs', 'Error message');

    // Assert
    // LoggerFactory applies FeatureFlags which defaults to INFO level, so DEBUG is filtered
    Assert.areEqual(3, logger.getEntryCount(), 'Should have three log entries (DEBUG filtered)');
  }

  @IsTest
  static void testDebugSink() {
    // Arrange
    DebugSink sink = new DebugSink();
    LogContext context = new LogContext();
    LogEntry entry = new LogEntry('INFO', 'Test message', context);

    // Act - should not throw
    sink.write(entry);

    // Assert
    Assert.isNotNull(entry, 'Entry should still exist');
  }

  @IsTest
  static void testExceptionLogging() {
    // Arrange
    Logger logger = LoggerFactory.getLogger('LoggingFrameworkTest');

    try {
      throw new DmlException('Test exception');
    } catch (Exception e) {
      // Act
      logger.error('testExceptionLogging', 'An error occurred', e);
    }

    // Assert
    Assert.areEqual(1, logger.getEntryCount(), 'Should have log entry with exception');
    List<LogEntry> entries = logger.getEntries();
    Assert.isNotNull(entries[0].getException(), 'Exception should be captured');
  }
}
