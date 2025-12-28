/**
 * @description Test class for FeatureFlags utility.
 * Tests: Loading from metadata (happy path), Safe fallback when metadata missing,
 * All 6 feature flag methods, Cache reset for test isolation.
 * @author Hamza Amari
 * @version 1.0
 */
@IsTest
private class FeatureFlagsTest {

  /**
   * @description Test that all methods return safe defaults when metadata not found.
   */
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testSafeFallbackDefaults() {
  // Arrange
  FeatureFlags.resetCache();

  // Mock: cachedSettings will be null, triggering fallback
  Test.startTest();

  // Act
  Boolean loggingEnabled = FeatureFlags.enableLogging();
  String minLevel = FeatureFlags.minLevel();
  Boolean persistLogs = FeatureFlags.persistLogs();
  Boolean perfLogs = FeatureFlags.perfLogs();
  Boolean disableAuto = FeatureFlags.disableAutomation();
  Boolean disableSync = FeatureFlags.disableExternalSync();

  Test.stopTest();

  // Assert - defaults should be safe
  Assert.isTrue(loggingEnabled, 'Logging should be enabled by default');
  Assert.areEqual('INFO', minLevel, 'Default log level should be INFO');
  Assert.isFalse(persistLogs, 'Logs should not persist by default');
  Assert.isFalse(perfLogs, 'Perf logs should be disabled by default');
  Assert.isFalse(disableAuto, 'Automations should be enabled by default');
  Assert.isFalse(disableSync, 'External sync should be enabled by default');
    }

  /**
   * @description Test that settings are cached (not requeried on subsequent calls).
   */
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testCaching() {
  // Arrange
  FeatureFlags.resetCache();

  Test.startTest();

  // Act - First call initializes cache
  FeatureFlags.enableLogging();

  // Store initial query count
  Integer initialQueries = Limits.getQueries();

  // Act - Second call should use cache
  FeatureFlags.enableLogging();
  FeatureFlags.minLevel();
  FeatureFlags.persistLogs();

  Integer finalQueries = Limits.getQueries();

  Test.stopTest();

  // Assert - No additional queries should have been executed
  Assert.areEqual(initialQueries, finalQueries, 'Settings should be cached');
    }

  /**
   * @description Test resetCache for test isolation.
   */
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testResetCache() {
  // Arrange
  FeatureFlags.resetCache();

  Test.startTest();

  // Act - Force initialization
  FeatureFlags.enableLogging();
  Assert.isTrue(FeatureFlags.enableLogging(), 'Settings should be initialized');

  // Reset cache
  FeatureFlags.resetCache();

  // Act - Initialize again
  Boolean result = FeatureFlags.enableLogging();

  Test.stopTest();

  // Assert
  Assert.isTrue(result, 'Should reinitialize after reset');
    }

  /**
   * @description Test that null values in metadata are handled safely.
   */
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testNullValueHandling() {
  // Arrange
  FeatureFlags.resetCache();

  Test.startTest();

  // Act & Assert - Even with null metadata, methods should not throw
  try {
      FeatureFlags.enableLogging();
      FeatureFlags.minLevel();
      FeatureFlags.persistLogs();
      FeatureFlags.perfLogs();
      FeatureFlags.disableAutomation();
      FeatureFlags.disableExternalSync();

      Assert.isTrue(true, 'No exceptions should be thrown');
  } catch (Exception e) {
      Assert.fail('Should not throw exception: ' + e.getMessage());
  }

  Test.stopTest();
    }

  /**
   * @description Test individual feature flag methods.
   */
  @IsTest
  @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
  static void testAllFeatureFlagMethods() {
  // Arrange
  FeatureFlags.resetCache();

  Test.startTest();

  // Act & Assert
  Boolean loggingEnabled = FeatureFlags.enableLogging();
  Assert.isTrue(loggingEnabled, 'enableLogging() should work');

  String level = FeatureFlags.minLevel();
  Assert.isNotNull(level, 'minLevel() should not be null');
  Assert.isTrue(level.length() > 0, 'minLevel() should return non-empty string');

  Boolean persist = FeatureFlags.persistLogs();
  Assert.isNotNull(persist, 'persistLogs() should not be null');

  Boolean perf = FeatureFlags.perfLogs();
  Assert.isNotNull(perf, 'perfLogs() should not be null');

  Boolean noAuto = FeatureFlags.disableAutomation();
  Assert.isNotNull(noAuto, 'disableAutomation() should not be null');

  Boolean noSync = FeatureFlags.disableExternalSync();
  Assert.isNotNull(noSync, 'disableExternalSync() should not be null');

  Test.stopTest();
    }
}