/**
 * @description Test class for Logger.
 * Tests: Logging methods, filtering, method chaining, buffering, performance logging.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class LoggerTest {

  @IsTest
  static void testLoggerCreation() {
    // Act
    Logger logger = new Logger('TestClass');

    // Assert
    Assert.isNotNull(logger, 'Logger should be created');
    Assert.areEqual(0, logger.getEntryCount(), 'Should start with no entries');
  }

  @IsTest
  static void testLoggerDebug() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    Logger result = logger.debug('testMethod', 'Debug message');

    // Assert
    Assert.areEqual(logger, result, 'Should return this for chaining');
    Assert.areEqual(1, logger.getEntryCount(), 'Should have one entry');
    Assert.areEqual('DEBUG', logger.getEntries()[0].getLevel());
  }

  @IsTest
  static void testLoggerInfo() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    logger.info('testMethod', 'Info message');

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    Assert.areEqual('INFO', logger.getEntries()[0].getLevel());
  }

  @IsTest
  static void testLoggerWarn() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    logger.warn('testMethod', 'Warn message');

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    Assert.areEqual('WARN', logger.getEntries()[0].getLevel());
  }

  @IsTest
  static void testLoggerError() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    logger.error('testMethod', 'Error message');

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    Assert.areEqual('ERROR', logger.getEntries()[0].getLevel());
  }

  @IsTest
  static void testLoggerErrorWithException() {
    // Arrange
    Logger logger = new Logger('TestClass');
    Exception testException = new DmlException('Test error');

    // Act
    logger.error('testMethod', 'Error occurred', testException);

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    LogEntry entry = logger.getEntries()[0];
    Assert.isNotNull(entry.getException());
    Assert.areEqual('Test error', entry.getException().getMessage());
  }

  @IsTest
  static void testLoggerFatal() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    logger.fatal('testMethod', 'Fatal message');

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    Assert.areEqual('FATAL', logger.getEntries()[0].getLevel());
  }

  @IsTest
  static void testLoggerFatalWithException() {
    // Arrange
    Logger logger = new Logger('TestClass');
    Exception testException = new DmlException('Fatal error');

    // Act
    logger.fatal('testMethod', 'Fatal occurred', testException);

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    LogEntry entry = logger.getEntries()[0];
    Assert.isNotNull(entry.getException());
  }

  @IsTest
  static void testLoggerMethodChaining() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    logger
      .debug('method', 'Debug')
      .info('method', 'Info')
      .warn('method', 'Warn')
      .error('method', 'Error')
      .fatal('method', 'Fatal');

    // Assert
    Assert.areEqual(5, logger.getEntryCount(), 'Should have 5 entries');
  }

  @IsTest
  static void testLoggerSetMinLevel() {
    // Arrange
    Logger logger = new Logger('TestClass');
    logger.setMinLevel('WARN');

    // Act
    logger.debug('method', 'Debug').info('method', 'Info').warn('method', 'Warn');

    // Assert - Only WARN should be logged (DEBUG and INFO filtered)
    Assert.areEqual(1, logger.getEntryCount());
    Assert.areEqual('WARN', logger.getEntries()[0].getLevel());
  }

  @IsTest
  static void testLoggerFiltering() {
    // Arrange
    Logger logger = new Logger('TestClass');
    logger.setMinLevel('ERROR');

    // Act
    logger
      .debug('method', 'Debug')
      .info('method', 'Info')
      .warn('method', 'Warn')
      .error('method', 'Error')
      .fatal('method', 'Fatal');

    // Assert - Only ERROR and FATAL should be logged
    Assert.areEqual(2, logger.getEntryCount());
    List<LogEntry> entries = logger.getEntries();
    Assert.areEqual('ERROR', entries[0].getLevel());
    Assert.areEqual('FATAL', entries[1].getLevel());
  }

  @IsTest
  static void testLoggerClearEntries() {
    // Arrange
    Logger logger = new Logger('TestClass');
    logger.info('method', 'Message 1').info('method', 'Message 2');
    Assert.areEqual(2, logger.getEntryCount());

    // Act
    logger.clearEntries();

    // Assert
    Assert.areEqual(0, logger.getEntryCount());
  }

  @IsTest
  static void testLoggerGetEntries() {
    // Arrange
    Logger logger = new Logger('TestClass');
    logger.info('method', 'Message 1').warn('method', 'Message 2');

    // Act
    List<LogEntry> entries = logger.getEntries();

    // Assert
    Assert.areEqual(2, entries.size());
    Assert.areEqual('INFO', entries[0].getLevel());
    Assert.areEqual('WARN', entries[1].getLevel());
  }

  @IsTest
  static void testLoggerPerformanceLogging() {
    // Arrange
    Logger logger = new Logger('TestClass');
    logger.setPerfLoggingEnabled(true);

    // Act
    logger.logPerformance('method', 'Database query', 1500);

    // Assert
    Assert.areEqual(1, logger.getEntryCount());
    LogEntry entry = logger.getEntries()[0];
    Assert.isTrue(entry.getMessage().contains('1500'));
    Assert.isTrue(entry.getMessage().contains('Database query'));
  }

  @IsTest
  static void testLoggerPerformanceLoggingDisabled() {
    // Arrange
    Logger logger = new Logger('TestClass');
    logger.setPerfLoggingEnabled(false);

    // Act
    logger.logPerformance('method', 'Operation', 1000);

    // Assert - Should not log if disabled
    Assert.areEqual(0, logger.getEntryCount());
  }

  @IsTest
  static void testLoggerSetPersistEnabled() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    Logger result = logger.setPersistEnabled(true);

    // Assert
    Assert.areEqual(logger, result, 'Should return this for chaining');
  }

  @IsTest
  static void testLoggerCustomContext() {
    // Arrange
    LogContext customContext = new LogContext().setSource('CustomClass', 'customMethod');
    Logger logger = new Logger('TestClass', customContext);

    // Act
    logger.info('method', 'Message');

    // Assert
    LogEntry entry = logger.getEntries()[0];
    Assert.areEqual('CustomClass', entry.getContext().getClassName());
    Assert.areEqual('customMethod', entry.getContext().getMethodName());
  }

  @IsTest
  static void testLoggerBuffering() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    for (Integer i = 0; i < 100; i++) {
      logger.info('method', 'Message ' + i);
    }

    // Assert
    Assert.areEqual(100, logger.getEntryCount());
    List<LogEntry> entries = logger.getEntries();
    Assert.areEqual('Message 0', entries[0].getMessage());
    Assert.areEqual('Message 99', entries[99].getMessage());
  }

  @IsTest
  static void testLoggerFilteringAtDifferentLevels() {
    // Test filtering with different min levels
    Logger debugLogger = new Logger('TestClass').setMinLevel('DEBUG');
    Logger infoLogger = new Logger('TestClass').setMinLevel('INFO');
    Logger fatalLogger = new Logger('TestClass').setMinLevel('FATAL');

    // Add all levels to each
    debugLogger.debug('m', 'd').info('m', 'i').warn('m', 'w').error('m', 'e').fatal('m', 'f');
    infoLogger.debug('m', 'd').info('m', 'i').warn('m', 'w').error('m', 'e').fatal('m', 'f');
    fatalLogger.debug('m', 'd').info('m', 'i').warn('m', 'w').error('m', 'e').fatal('m', 'f');

    // Assert
    Assert.areEqual(5, debugLogger.getEntryCount(), 'DEBUG should allow all');
    Assert.areEqual(4, infoLogger.getEntryCount(), 'INFO should allow INFO+');
    Assert.areEqual(1, fatalLogger.getEntryCount(), 'FATAL should allow FATAL only');
  }

  @IsTest
  static void testLoggerSourceTracking() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act
    logger.info('method1', 'Message1');
    logger.info('method2', 'Message2');
    logger.warn('method3', 'Message3');

    // Assert
    List<LogEntry> entries = logger.getEntries();
    Assert.areEqual('method1', entries[0].getContext().getMethodName());
    Assert.areEqual('method2', entries[1].getContext().getMethodName());
    Assert.areEqual('method3', entries[2].getContext().getMethodName());
  }

  @IsTest
  static void testLoggerDefaultMinLevel() {
    // Arrange
    Logger logger = new Logger('TestClass');

    // Act - Default should be DEBUG (from Logger constructor)
    logger.debug('m', 'debug').info('m', 'info').warn('m', 'warn');

    // Assert - All messages should be logged (DEBUG is the default minimum level)
    Assert.areEqual(3, logger.getEntryCount());
  }
}
