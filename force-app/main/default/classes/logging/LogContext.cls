/**
 * @description Encapsulates the execution context for logging.
 * Captures: request ID, user, org, timestamps, and custom metadata.
 * Provides structured data for all log entries within a transaction.
 * @author Hamza Amari
 * @version 1.0
 */
public class LogContext {
  private String requestId;
  private String userId;
  private String orgId;
  private String className;
  private String methodName;
  private Long startTime;
  private Map<String, Object> customData;

  /**
   * @description Initialize LogContext with current execution environment.
   */
  public LogContext() {
    this.requestId = generateRequestId();
    this.userId = UserInfo.getUserId();
    this.orgId = UserInfo.getOrganizationId();
    this.customData = new Map<String, Object>();
    this.startTime = System.currentTimeMillis();
  }

  /**
   * @description Set the calling class and method for context.
   * @param className Name of the class executing
   * @param methodName Name of the method executing
   * @return this for method chaining
   */
  public LogContext setSource(String className, String methodName) {
    this.className = className;
    this.methodName = methodName;
    return this;
  }

  /**
   * @description Add custom key-value pair to context.
   * @param key The data key
   * @param value The data value
   * @return this for method chaining
   */
  public LogContext addCustomData(String key, Object value) {
    this.customData.put(key, value);
    return this;
  }

  /**
   * @description Generate unique request ID for tracing across logs.
   * Format: [orgId]-[userId]-[timestamp]-[random]
   * @return Unique request identifier
   */
  private String generateRequestId() {
    String timestamp = String.valueOf(System.currentTimeMillis());
    String random = String.valueOf(Math.random()).substring(2, 7);
    return UserInfo.getOrganizationId().substring(0, 5) + '-' + timestamp.substring(timestamp.length() - 8) + '-' + random;
  }

  // Getters
  public String getRequestId() {
    return this.requestId;
  }

  public String getUserId() {
    return this.userId;
  }

  public String getOrgId() {
    return this.orgId;
  }

  public String getClassName() {
    return this.className;
  }

  public String getMethodName() {
    return this.methodName;
  }

  public Long getStartTime() {
    return this.startTime;
  }

  public Map<String, Object> getCustomData() {
    return this.customData;
  }

  /**
   * @description Get elapsed time since context creation (milliseconds).
   * @return Time in milliseconds
   */
  public Long getElapsedTime() {
    return System.currentTimeMillis() - this.startTime;
  }
}
