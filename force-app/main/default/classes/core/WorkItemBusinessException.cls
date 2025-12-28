/**
 * @author Hamza Amari
 * @date 26/12/2025
 * @description Exception métier pour les violations de règles métier Work_Item__c.
 * Levée quand une opération viole une règle métier (pas une erreur système).
 *
 * Exemples :
 * - Tentative de marquer comme Done alors que la date d'échéance est passée
 * - Transition de statut invalide
 * - Valeurs requises manquantes
 */
public class WorkItemBusinessException extends Exception {
}
