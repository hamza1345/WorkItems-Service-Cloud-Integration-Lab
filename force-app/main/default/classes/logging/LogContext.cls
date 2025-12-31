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
 * Usage:
 * String corrId = LogContext.getCorrelationId();
 * Logger.info('MyClass', 'Operation completed').tag('correlationId', corrId);
 */
public class LogContext {
  
  private static String correlationId;
  
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
  
  // ======== STUBS FOR BACKWARDS COMPATIBILITY WITH OLD LOGGER FRAMEWORK ========
  // Ces méthodes sont appelées par Logger.cls existant mais ne sont pas utilisées
  // par ControllerLogger. Retournent valeurs par défaut pour éviter erreurs compilation.
  
  public static String getRequestId() {
    return Request.getCurrent().getRequestId();
  }
  
  public static String getUserId() {
    return UserInfo.getUserId();
  }
  
  public static String getOrgId() {
    return UserInfo.getOrganizationId();
  }
  
  public static String getClassName() {
    return '';
  }
  
  public static String getMethodName() {
    return '';
  }
  
  public static Map<String, String> getCustomData() {
    return new Map<String, String>();
  }
  
  public static void setSource(String className, String methodName) {
    // No-op stub
  }
  
  public static void addCustomData(String key, String value) {
    // No-op stub
  }
  
  public static Long getStartTime() {
    return System.currentTimeMillis();
  }
  
  public static Long getElapsedTime() {
    return 0;
  }
  // ======== END STUBS ========
  
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
