/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Context de logging thread-safe avec correlationId.
 * 
 * Pattern:
 * - Génère un UUID unique par transaction (Request.getCurrent().getRequestId())
 * - Utilisé pour tracer les logs d'une même transaction
 * - Exposé dans UiError pour debugging côté UI
 * 
 * Usage moderne (static):
 * String corrId = LogContext.getCorrelationId();
 * 
 * Usage legacy (instance - pour old Logger.cls):
 * LogContext ctx = new LogContext();
 * ctx.setSource('MyClass', 'myMethod');
 */
public class LogContext {
  
  private static String correlationId;
  
  // Instance fields for legacy Logger compatibility
  private String instanceClassName;
  private String instanceMethodName;
  private Map<String, String> instanceCustomData;
  private Long instanceStartTime;
  
  /**
   * @description Constructor for legacy Logger compatibility.
   */
  public LogContext() {
    this.instanceClassName = '';
    this.instanceMethodName = '';
    this.instanceCustomData = new Map<String, String>();
    this.instanceStartTime = System.currentTimeMillis();
  }
  
  // ======== INSTANCE METHODS FOR LEGACY LOGGER.CLS COMPATIBILITY ========
  
  public String getClassName() {
    return this.instanceClassName != null ? this.instanceClassName : '';
  }
  
  public String getMethodName() {
    return this.instanceMethodName != null ? this.instanceMethodName : '';
  }
  
  public void setSource(String className, String methodName) {
    this.instanceClassName = className;
    this.instanceMethodName = methodName;
  }
  
  public Map<String, String> getCustomData() {
    return this.instanceCustomData != null ? this.instanceCustomData : new Map<String, String>();
  }
  
  public void addCustomData(String key, String value) {
    if (this.instanceCustomData == null) {
      this.instanceCustomData = new Map<String, String>();
    }
    this.instanceCustomData.put(key, value);
  }
  
  public String getRequestId() {
    return Request.getCurrent().getRequestId();
  }
  
  public String getUserId() {
    return UserInfo.getUserId();
  }
  
  public String getOrgId() {
    return UserInfo.getOrganizationId();
  }
  
  public Long getStartTime() {
    return this.instanceStartTime;
  }
  
  public Long getElapsedTime() {
    return System.currentTimeMillis() - this.instanceStartTime;
  }
  
  // ======== END INSTANCE METHODS ========
  
  // ======== STATIC METHODS FOR NEW CODE (ControllerLogger, UiError) ========
  
  /**
   * @description Récupère ou génère le correlationId pour la transaction courante.
   * Thread-safe: utilise Request.getCurrent().getRequestId() si disponible.
   * 
   * @return String UUID au format 8 caractères (ex: "8f2c-9a1e")
   */
  public static String getCorrelationId() {
    if (correlationId == null) {
      correlationId = generateShortId();
    }
    return correlationId;
  }
  
  /**
   * @description Réinitialise le correlationId (utile en tests).
   */
  @TestVisible
  private static void reset() {
    correlationId = null;
  }
  
  // ======== END STATIC METHODS ========
  
  /**
   * @description Génère un ID court (8 caractères) basé sur Request ID ou UUID.
   * Format: "xxxx-xxxx"
   * 
   * @return String Short correlation ID
   */
  private static String generateShortId() {
    String requestId = Request.getCurrent().getRequestId();
    if (String.isNotBlank(requestId)) {
      // Utilise les 8 derniers caractères du Request ID
      return requestId.right(9); // Format: "xxxx-xxxx"
    }
    
    // Fallback: génère un UUID court
    String uuid = String.valueOf(Crypto.getRandomLong());
    String hex = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(uuid)));
    return hex.substring(0, 4) + '-' + hex.substring(4, 8);
  }
}
