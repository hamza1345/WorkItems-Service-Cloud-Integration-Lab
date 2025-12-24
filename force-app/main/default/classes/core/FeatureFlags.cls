/**
 * @description FeatureFlags Utility Class.
 * Manages feature flags and logging configuration via Logging_Settings custom metadata.
 * Provides safe fallbacks and testable design with @TestVisible overrides.
 * SOQL is centralized in this class only.
 * No hard coupling to specific record structures - uses dynamic access patterns.
 * @author Hamza Amari
 * @version 1.0
 */
public without sharing class FeatureFlags {
  private static final String METADATA_TYPE = 'Logging_Settings';
  private static final String DEFAULT_RECORD = 'Default';

  @TestVisible
  private static Logging_Settings__mdt cachedSettings;

  @TestVisible
  private static Boolean hasInitialized = false;

  /**
   * @description Initialize and cache the Logging_Settings metadata.
   * Safe fallback if record not found.
   */
  private static void ensureInitialized() {
    if (hasInitialized) {
      return;
    }

    try {
      cachedSettings = getLoggingSettings();
      if (cachedSettings == null) {
        cachedSettings = getDefaultSettings();
      }
    } catch (Exception e) {
      cachedSettings = getDefaultSettings();
    }

    hasInitialized = true;
  }

  /**
   * @description Retrieve Logging_Settings metadata record from Salesforce.
   * CENTRALIZED SOQL - Only place where database queries happen.
   * Validates CRUD permissions before querying.
   * @return Logging_Settings__mdt record or null if not found or not accessible
   */
  @TestVisible
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Logging_Settings__mdt getLoggingSettings() {
    SObjectType sObjectType = Logging_Settings__mdt.sObjectType;
    DescribeSObjectResult describeResult = sObjectType.getDescribe(
      SObjectDescribeOptions.DEFERRED
    );
    if (!describeResult.isAccessible()) {
      return null;
    }

    List<Logging_Settings__mdt> settings = [
      SELECT
        Id,
        DeveloperName,
        Enable_Logging__c,
        Min_Log_Level__c,
        Persist_Logs__c,
        Performance_Logs__c,
        Disable_Automation__c,
        Disable_External_Sync__c
      FROM Logging_Settings__mdt
      WHERE DeveloperName = :DEFAULT_RECORD
      LIMIT 1
    ];

    return settings.isEmpty() ? null : settings[0];
  }

  /**
   * @description Provides safe default settings when metadata is not found.
   * Allows graceful degradation without breaking the application.
   * @return Default Logging_Settings__mdt with safe values
   */
  @TestVisible
  private static Logging_Settings__mdt getDefaultSettings() {
    Logging_Settings__mdt defaults = new Logging_Settings__mdt();
    defaults.DeveloperName = DEFAULT_RECORD;
    defaults.Enable_Logging__c = true;
    defaults.Min_Log_Level__c = 'DEBUG';
    defaults.Persist_Logs__c = false;
    defaults.Performance_Logs__c = false;
    defaults.Disable_Automation__c = false;
    defaults.Disable_External_Sync__c = false;
    return defaults;
  }

  /**
   * @description Check if logging is enabled in the system.
   * Returns true if logging feature flag is active.
   * @return true if logging is enabled, false otherwise
   */
  public static Boolean enableLogging() {
    ensureInitialized();
    return cachedSettings.Enable_Logging__c != null
      ? cachedSettings.Enable_Logging__c
      : true;
  }

  /**
   * @description Get the minimum logging level configured.
   * Possible values: NONE, DEBUG, INFO, WARN, ERROR, FATAL.
   * Defaults to DEBUG if not configured.
   * @return The minimum log level as a string
   */
  public static String minLevel() {
    ensureInitialized();
    String level = cachedSettings.Min_Log_Level__c;
    return String.isBlank(level) ? 'DEBUG' : level;
  }

  /**
   * @description Check if logs should be persisted to the database.
   * When true, log records will be created in Log__c custom object.
   * @return true if logs should be persisted, false otherwise
   */
  public static Boolean persistLogs() {
    ensureInitialized();
    return cachedSettings.Persist_Logs__c != null
      ? cachedSettings.Persist_Logs__c
      : false;
  }

  /**
   * @description Check if performance logging is enabled.
   * When true, execution time and resource usage will be logged.
   * @return true if performance logs should be captured, false otherwise
   */
  public static Boolean perfLogs() {
    ensureInitialized();
    return cachedSettings.Performance_Logs__c != null
      ? cachedSettings.Performance_Logs__c
      : false;
  }

  /**
   * @description Check if automations should be disabled.
   * When true, triggers and flows will be prevented from executing.
   * @return true if automations should be disabled, false otherwise
   */
  public static Boolean disableAutomation() {
    ensureInitialized();
    return cachedSettings.Disable_Automation__c != null
      ? cachedSettings.Disable_Automation__c
      : false;
  }

  /**
   * @description Check if external synchronization is disabled.
   * When true, integrations with external systems will be halted.
   * @return true if external sync should be disabled, false otherwise
   */
  public static Boolean disableExternalSync() {
    ensureInitialized();
    return cachedSettings.Disable_External_Sync__c != null
      ? cachedSettings.Disable_External_Sync__c
      : false;
  }

  /**
   * @description Reset cache for testing purposes.
   * Clears both the cached settings and initialization flag.
   * @TestVisible allows unit tests to clear state between test cases.
   */
  @TestVisible
  private static void resetCache() {
    cachedSettings = null;
    hasInitialized = false;
  }
}