/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Exception métier personnalisée pour WorkItems application.
 * Utilisée pour les erreurs métier non-DML (validations, business rules, etc.).
 * Permet de différencier les erreurs métier des erreurs techniques.
 * 
 * Usage:
 *   throw BusinessException.withCode('VALIDATION_ERROR').withMessage('Invalid status');
 */
public class BusinessException extends Exception {
  private String errorCode;
  
  /**
   * @description Factory method avec code d'erreur.
   * @param code Code d'erreur
   * @return BusinessException
   */
  public static BusinessException withCode(String code) {
    BusinessException ex = new BusinessException();
    ex.errorCode = code;
    return ex;
  }
  
  /**
   * @description Définit le message (chainable).
   * @param msg Message d'erreur
   * @return BusinessException
   */
  public BusinessException withMessage(String msg) {
    this.setMessage(msg);
    return this;
  }
  
  /**
   * @description Récupère le code d'erreur.
   * @return String code d'erreur ou null
   */
  public String getErrorCode() {
    return this.errorCode;
  }
  
  /**
   * @description Définit le code d'erreur.
   * @param code Code d'erreur
   */
  public void setErrorCode(String code) {
    this.errorCode = code;
  }
  
  /**
   * @description Retourne une représentation complète de l'exception.
   * @return String avec code + message
   */
  public override String toString() {
    String result = 'BusinessException';
    if (String.isNotBlank(errorCode)) {
      result += ' [' + errorCode + ']';
    }
    if (String.isNotBlank(getMessage())) {
      result += ': ' + getMessage();
    }
    return result;
  }
}
