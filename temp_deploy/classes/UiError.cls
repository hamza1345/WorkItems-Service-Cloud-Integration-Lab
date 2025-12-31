/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Modèle d'erreur standardisé pour l'UI (LWC/Aura).
 * 
 * Objectif:
 * - Structure cohérente pour toutes les erreurs remontées au front
 * - correlationId pour traçabilité (lien avec logs backend)
 * - Facilite parsing côté JS (reduceErrors)
 * 
 * Usage:
 * UiError err = new UiError('SAVE_FAILED', 'Impossible de sauvegarder', generateCorrelationId());
 * throw new AuraHandledException(err.toMessage());
 */
public class UiError {
  
  /** Code erreur technique/métier (ex: SAVE_FAILED, VALIDATION_ERROR) */
  @AuraEnabled
  public String code { get; set; }
  
  /** Message fonctionnel pour l'utilisateur */
  @AuraEnabled
  public String message { get; set; }
  
  /** Correlation ID pour traçabilité logs (ex: "8f2c-9a1e") */
  @AuraEnabled
  public String correlationId { get; set; }
  
  /**
   * @description Constructeur complet.
   * @param code Code erreur (non null)
   * @param message Message fonctionnel (non null)
   * @param correlationId Correlation ID de la transaction (non null)
   */
  public UiError(String code, String message, String correlationId) {
    this.code = code;
    this.message = message;
    this.correlationId = correlationId;
  }
  
  /**
   * @description Convertit l'erreur en message formaté pour AuraHandledException.
   * Format: "{message} [Réf: {correlationId}]"
   * 
   * Exemple: "Impossible de clôturer le work item. [Réf: 8f2c-9a1e]"
   * 
   * @return String Message formaté avec correlationId
   */
  public String toMessage() {
    return message + ' [Réf: ' + correlationId + ']';
  }
  
  /**
   * @description Factory pour créer UiError avec correlationId auto.
   * @param code Code erreur
   * @param message Message fonctionnel
   * @return UiError avec correlationId généré
   */
  public static UiError create(String code, String message) {
    return new UiError(code, message, generateCorrelationId());
  }
  
  /**
   * @description Génère un ID court (8 caractères) basé sur Request ID ou UUID.
   * Format: "xxxx-xxxx"
   * 
   * @return String Short correlation ID
   */
  private static String generateCorrelationId() {
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
