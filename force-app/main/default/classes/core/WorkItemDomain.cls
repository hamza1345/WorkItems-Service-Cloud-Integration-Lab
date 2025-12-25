/**
 * @author Hamza Amari
 * @date 24/12/2025
 * @description Couche métier pour la logique métier de Work_Item__c.
 * Responsabilités :
 * - Encapsuler les règles métier et validations de Work_Item__c
 * - Calculer les champs dérivés (p. ex. temps écoulé, pourcentage d'achèvement)
 * - Gérer les transitions d'état (p. ex. Nouveau -> En_Cours -> Terminé)
 * - Fournir des méthodes d'assistance pour WorkItemService
 *
 * Cette classe ne contient AUCUNE opération de base de données (pas de SOQL/DML).
 * Elle fonctionne uniquement sur les objets Work_Item__c en mémoire.
 */
public without sharing class WorkItemDomain {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemDomain');
  private static final Integer COMPLETION_THRESHOLD = 80;

  /**
   * @description Valider l'état de l'élément de travail avant la sauvegarde.
   * @param records Éléments de travail à valider
   * @return Liste des erreurs de validation (vide si valide)
   */
  public static List<String> validate(List<Work_Item__c> records) {
    List<String> errors = new List<String>();

    // Vérifier si la liste n'est pas vide
    if (records == null || records.isEmpty()) {
      return errors;
    }

    for (Work_Item__c record : records) {
      // TODO: Implement validation logic
    }

    return errors;
  }

  /**
   * @description Remplir les valeurs par défaut pour les nouveaux éléments de travail.
   * @param records Enregistrements à remplir
   */
  public static void populateDefaults(List<Work_Item__c> records) {
    // Vérifier si la liste n'est pas vide
    if (records == null || records.isEmpty()) {
      return;
    }

    for (Work_Item__c record : records) {
      // TODO : Implémenter la logique de remplissage des valeurs par défaut
    }
  }

  /**
   * @description Vérifier si un élément de travail peut passer à un nouveau statut.
   * @param currentStatus Valeur du statut actuel
   * @param newStatus Nouveau statut proposé
   * @return true si la transition est autorisée
   */
  public static Boolean isStatusTransitionValid(String currentStatus, String newStatus) {
    // Utiliser switch au lieu de if-else pour les conditions multiples
    switch on currentStatus {
      when 'New' {
        return newStatus == 'In_Progress' || newStatus == 'On_Hold';
      }
      when 'In_Progress' {
        return newStatus == 'Done' || newStatus == 'On_Hold' || newStatus == 'New';
      }
      when 'On_Hold' {
        return newStatus == 'In_Progress' || newStatus == 'Cancelled';
      }
      when 'Done' {
        return newStatus == 'Reopened';
      }
      when 'Cancelled' {
        return false;
      }
      when else {
        return false;
      }
    }
  }

  /**
   * @description Calculer le pourcentage d'achèvement en fonction des tâches associées.
   * @param workItemId Id de l'élément de travail
   * @return Pourcentage d'achèvement (0-100)
   */
  public static Integer calculateCompletionPercentage(Id workItemId) {
    // TODO : Implémenter le calcul
    return 0;
  }
}
