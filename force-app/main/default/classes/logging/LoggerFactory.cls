/**
 * @description Factory for creating Logger instances.
 * Returns configured Logger based on FeatureFlags settings.
 * Single entry point for logger creation across application.
 * @author Hamza Amari
 * @version 1.0
 */
public class LoggerFactory {
  /**
   * @description Create a Logger instance for the calling class.
   * Logger will be configured based on FeatureFlags.
   * @param callingClassName Name of the class requesting the logger
   * @return Configured Logger instance
   */
  public static Logger getLogger(String callingClassName) {
    Logger logger = new Logger(callingClassName);

    // Configure from FeatureFlags
    if (FeatureFlags.enableLogging()) {
      logger.setMinLevel(FeatureFlags.minLevel());
      logger.setPersistEnabled(FeatureFlags.persistLogs());
      logger.setPerfLoggingEnabled(FeatureFlags.perfLogs());
    } else {
      // If logging disabled, set to highest level (FATAL only)
      logger.setMinLevel(LogLevel.FATAL);
    }

    return logger;
  }

  /**
   * @description Create a Logger with custom context.
   * Allows specifying additional context for advanced scenarios.
   * @param callingClassName Name of the class requesting the logger
   * @param context Custom LogContext
   * @return Configured Logger instance
   */
  public static Logger getLogger(String callingClassName, LogContext context) {
    Logger logger = new Logger(callingClassName, context);

    if (FeatureFlags.enableLogging()) {
      logger.setMinLevel(FeatureFlags.minLevel());
      logger.setPersistEnabled(FeatureFlags.persistLogs());
      logger.setPerfLoggingEnabled(FeatureFlags.perfLogs());
    } else {
      logger.setMinLevel(LogLevel.FATAL);
    }

    return logger;
  }
}
