/**
 * @description Test class for LogLevel utility.
 * Tests: Priority calculation, log level comparison, filtering logic.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class LogLevelTest {

  @IsTest
  static void testGetPriority() {
    // Test each level priority
    Assert.areEqual(0, LogLevel.getPriority('DEBUG'), 'DEBUG should have priority 0');
    Assert.areEqual(1, LogLevel.getPriority('INFO'), 'INFO should have priority 1');
    Assert.areEqual(2, LogLevel.getPriority('WARN'), 'WARN should have priority 2');
    Assert.areEqual(3, LogLevel.getPriority('ERROR'), 'ERROR should have priority 3');
    Assert.areEqual(4, LogLevel.getPriority('FATAL'), 'FATAL should have priority 4');
  }

  @IsTest
  static void testGetPriorityUnknownLevel() {
    // Unknown level should default to INFO (priority 1)
    Integer priority = LogLevel.getPriority('UNKNOWN');
    Assert.areEqual(1, priority, 'Unknown level should default to INFO priority');
  }

  @IsTest
  static void testGetPriorityNull() {
    // Null level should default to INFO
    Integer priority = LogLevel.getPriority(null);
    Assert.areEqual(1, priority, 'Null level should default to INFO priority');
  }

  @IsTest
  static void testShouldLogDebugVsInfo() {
    // With minLevel INFO, DEBUG should NOT be logged
    Boolean shouldLog = LogLevel.shouldLog('DEBUG', 'INFO');
    Assert.isFalse(shouldLog, 'DEBUG should not be logged when min level is INFO');
  }

  @IsTest
  static void testShouldLogInfoVsInfo() {
    // With minLevel INFO, INFO should be logged
    Boolean shouldLog = LogLevel.shouldLog('INFO', 'INFO');
    Assert.isTrue(shouldLog, 'INFO should be logged when min level is INFO');
  }

  @IsTest
  static void testShouldLogErrorVsInfo() {
    // With minLevel INFO, ERROR should be logged
    Boolean shouldLog = LogLevel.shouldLog('ERROR', 'INFO');
    Assert.isTrue(shouldLog, 'ERROR should be logged when min level is INFO');
  }

  @IsTest
  static void testShouldLogDebugVsDebug() {
    // With minLevel DEBUG, DEBUG should be logged
    Boolean shouldLog = LogLevel.shouldLog('DEBUG', 'DEBUG');
    Assert.isTrue(shouldLog, 'DEBUG should be logged when min level is DEBUG');
  }

  @IsTest
  static void testShouldLogFatalVsFatal() {
    // With minLevel FATAL, FATAL should be logged
    Boolean shouldLog = LogLevel.shouldLog('FATAL', 'FATAL');
    Assert.isTrue(shouldLog, 'FATAL should be logged when min level is FATAL');
  }

  @IsTest
  static void testShouldLogWarnVsFatal() {
    // With minLevel FATAL, WARN should NOT be logged
    Boolean shouldLog = LogLevel.shouldLog('WARN', 'FATAL');
    Assert.isFalse(shouldLog, 'WARN should not be logged when min level is FATAL');
  }

  @IsTest
  static void testLogLevelHierarchy() {
    // Test complete hierarchy: DEBUG < INFO < WARN < ERROR < FATAL
    Assert.isTrue(LogLevel.shouldLog('INFO', 'DEBUG'), 'INFO >= DEBUG');
    Assert.isTrue(LogLevel.shouldLog('WARN', 'INFO'), 'WARN >= INFO');
    Assert.isTrue(LogLevel.shouldLog('ERROR', 'WARN'), 'ERROR >= WARN');
    Assert.isTrue(LogLevel.shouldLog('FATAL', 'ERROR'), 'FATAL >= ERROR');
  }

  @IsTest
  static void testLogLevelConstants() {
    // Verify static constants are defined
    Assert.isNotNull(LogLevel.DEBUG, 'DEBUG constant should exist');
    Assert.isNotNull(LogLevel.INFO, 'INFO constant should exist');
    Assert.isNotNull(LogLevel.WARN, 'WARN constant should exist');
    Assert.isNotNull(LogLevel.ERROR, 'ERROR constant should exist');
    Assert.isNotNull(LogLevel.FATAL, 'FATAL constant should exist');
  }

  @IsTest
  static void testLogLevelValuesCorrect() {
    // Verify constant values
    Assert.areEqual('DEBUG', LogLevel.DEBUG);
    Assert.areEqual('INFO', LogLevel.INFO);
    Assert.areEqual('WARN', LogLevel.WARN);
    Assert.areEqual('ERROR', LogLevel.ERROR);
    Assert.areEqual('FATAL', LogLevel.FATAL);
  }
}
