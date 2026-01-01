/**
 * @author Hamza Amari
 * @date 26/12/2025
 * @description Couche métier pour la logique métier de Work_Item__c.
 * Responsabilités :
 * - Encapsuler les règles métier et validations de Work_Item__c
 * - Calculer les champs dérivés (p. ex. temps écoulé, pourcentage d'achèvement)
 * - Gérer les transitions d'état (p. ex. Nouveau -> En_Cours -> Terminé)
 * - Fournir des méthodes d'assistance pour WorkItemService
 *
 * Cette classe ne contient AUCUNE opération de base de données (pas de SOQL/DML).
 * Elle fonctionne uniquement sur les objets Work_Item__c en mémoire.
 *
 * Règles Métier Implémentées :
 * 1. Valeurs par défaut : Status = New, Priority = Medium
 * 2. Completion : Quand Status = Done, Completed_On = NOW
 * 3. Guard métier : Impossible Done si Due_Date < today
 */
public without sharing class WorkItemDomain {
  private static final Logger LOGGER = LoggerFactory.getLogger('WorkItemDomain');
  private static final Integer COMPLETION_THRESHOLD = 80;

  // ========================================
  // CONSTANTES MÉTIER
  // ========================================
  private static final String STATUS_NEW = 'New';
  private static final String STATUS_IN_PROGRESS = 'In_Progress';
  private static final String STATUS_BLOCKED = 'Blocked';
  private static final String STATUS_DONE = 'Done';
  private static final String STATUS_REOPENED = 'Reopened';

  private static final String PRIORITY_LOW = 'Low';
  private static final String PRIORITY_MEDIUM = 'Medium';
  private static final String PRIORITY_HIGH = 'High';

  /**
   * @description Valider l'état de l'élément de travail avant la sauvegarde.
   * Applique les règles métier et retourne les erreurs de validation.
   * @param records Éléments de travail à valider
   * @return Liste des erreurs de validation (vide si valide)
   */
  public static List<String> validate(List<Work_Item__c> records) {
    List<String> errors = new List<String>();

    // Vérifier si la liste n'est pas vide
    if (records == null || records.isEmpty()) {
      return errors;
    }

    // Valider chaque enregistrement
    for (Work_Item__c record : records) {
      try {
        validateSingleRecord(record);
      } catch (WorkItemBusinessException e) {
        errors.add(e.getMessage());
        LOGGER.warn('validate', 'Erreur de validation : ' + e.getMessage());
      }
    }

    return errors;
  }

  /**
   * @description Valider un seul enregistrement.
   * Lève une exception si une règle métier est violée.
   * @param record Enregistrement à valider
   * @throws WorkItemBusinessException si validation échoue
   */
  private static void validateSingleRecord(Work_Item__c record) {
    // Règle 3 : Guard métier - Impossible Done si Due_Date < today
    if (record.Status__c == STATUS_DONE && record.Due_Date__c != null) {
      if (record.Due_Date__c < System.today()) {
        String errorMsg = 'Impossible de marquer comme Terminé : la date d\'échéance est dans le passé';
        LOGGER.warn('validateSingleRecord', errorMsg);
        throw new WorkItemBusinessException(errorMsg);
      }
    }

    // Valider que le nom n'est pas vide
    if (String.isBlank(record.Name)) {
      String errorMsg = 'Le nom de l\'élément de travail est requis';
      LOGGER.warn('validateSingleRecord', errorMsg);
      throw new WorkItemBusinessException(errorMsg);
    }

    // Valider la priorité si fournie
    if (String.isNotBlank(record.Priority__c)) {
      if (!isValidPriority(record.Priority__c)) {
        String errorMsg = 'Priorité invalide : ' + record.Priority__c;
        LOGGER.warn('validateSingleRecord', errorMsg);
        throw new WorkItemBusinessException(errorMsg);
      }
    }

    // Valider le statut si fourni
    if (String.isNotBlank(record.Status__c)) {
      if (!isValidStatus(record.Status__c)) {
        String errorMsg = 'Statut invalide : ' + record.Status__c;
        LOGGER.warn('validateSingleRecord', errorMsg);
        throw new WorkItemBusinessException(errorMsg);
      }
    }
  }

  /**
   * @description Remplir les valeurs par défaut pour les nouveaux éléments de travail.
   * Règle 1 : Status = New, Priority = Medium si null
   * @param records Enregistrements à remplir
   */
  public static void populateDefaults(List<Work_Item__c> records) {
    // Vérifier si la liste n'est pas vide
    if (records == null || records.isEmpty()) {
      return;
    }

    for (Work_Item__c record : records) {
      populateSingleDefaults(record);
    }
  }

  /**
   * @description Remplir les valeurs par défaut pour un seul enregistrement.
   * @param record Enregistrement à remplir
   */
  private static void populateSingleDefaults(Work_Item__c record) {
    // Règle 1a : Status par défaut = New
    if (String.isBlank(record.Status__c)) {
      record.Status__c = STATUS_NEW;
      LOGGER.info('populateSingleDefaults', 'Status défini à ' + STATUS_NEW);
    }

    // Règle 1b : Priority par défaut = Medium
    if (String.isBlank(record.Priority__c)) {
      record.Priority__c = PRIORITY_MEDIUM;
      LOGGER.info('populateSingleDefaults', 'Priority définie à ' + PRIORITY_MEDIUM);
    }
  }

  /**
   * @description Appliquer les transitions et modifications à la sauvegarde.
   * Règle 2 : Si Status = Done, Completed_On = NOW
   * @param newRecords Enregistrements mis à jour
   * @param oldMap Carte des anciennes valeurs (avant mise à jour)
   */
  public static void applyBusinessRules(List<Work_Item__c> newRecords, Map<Id, Work_Item__c> oldMap) {
    if (newRecords == null || newRecords.isEmpty()) {
      return;
    }

    for (Work_Item__c record : newRecords) {
      Work_Item__c oldRecord = oldMap != null ? oldMap.get(record.Id) : null;
      applySingleBusinessRule(record, oldRecord);
    }
  }

  /**
   * @description Appliquer les règles métier à un seul enregistrement.
   * @param newRecord Nouvel enregistrement
   * @param oldRecord Ancien enregistrement (null pour insert)
   */
  private static void applySingleBusinessRule(Work_Item__c newRecord, Work_Item__c oldRecord) {
    // Règle 2 : Si transition vers Done, remplir Completed_On
    Boolean isTransitionToDone = newRecord.Status__c == STATUS_DONE &&
      (oldRecord == null || oldRecord.Status__c != STATUS_DONE);

    if (isTransitionToDone) {
      newRecord.Completed_On__c = System.now();
      LOGGER.info('applySingleBusinessRule', 'Completed_On défini à ' + System.now());
    }
  }

  /**
   * @description Vérifier si un élément de travail peut passer à un nouveau statut.
   * @param currentStatus Statut actuel
   * @param newStatus Statut proposé
   * @return true si la transition est autorisée
   */
  public static Boolean isStatusTransitionValid(String currentStatus, String newStatus) {
    // Utiliser switch au lieu de if-else pour les conditions multiples
    switch on currentStatus {
      when 'New' {
        return newStatus == STATUS_IN_PROGRESS || newStatus == STATUS_BLOCKED;
      }
      when 'In_Progress' {
        return newStatus == STATUS_DONE || newStatus == STATUS_BLOCKED || newStatus == 'New';
      }
      when 'Blocked' {
        return newStatus == STATUS_IN_PROGRESS || newStatus == 'Cancelled';
      }
      when 'Done' {
        return newStatus == STATUS_REOPENED;
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
   * @description Vérifier si le statut fourni est valide.
   * @param status Statut à vérifier
   * @return true si le statut est autorisé
   */
  private static Boolean isValidStatus(String status) {
    Set<String> validStatuses = new Set<String>{
      STATUS_NEW,
      STATUS_IN_PROGRESS,
      STATUS_BLOCKED,
      STATUS_DONE,
      STATUS_REOPENED,
      'Cancelled'
    };
    return validStatuses.contains(status);
  }

  /**
   * @description Vérifier si la priorité fournie est valide.
   * @param priority Priorité à vérifier
   * @return true si la priorité est autorisée
   */
  private static Boolean isValidPriority(String priority) {
    Set<String> validPriorities = new Set<String>{ PRIORITY_LOW, PRIORITY_MEDIUM, PRIORITY_HIGH };
    return validPriorities.contains(priority);
  }

  /**
   * @description Calculer le pourcentage d'achèvement en fonction du statut.
   * New = 0%, In_Progress = 50%, Done = 100%
   * @param status Statut actuel
   * @return Pourcentage d'achèvement (0-100)
   */
  public static Integer calculateCompletionPercentage(String status) {
    switch on status {
      when 'New' {
        return 0;
      }
      when 'In_Progress' {
        return 50;
      }
      when 'Done' {
        return 100;
      }
      when else {
        return 25;
      }
    }
  }

  /**
   * @description Vérifier si un élément de travail est dû bientôt (dans 3 jours).
   * @param dueDate Date d'échéance
   * @return true si dû dans les 3 prochains jours
   */
  public static Boolean isDueSoon(Date dueDate) {
    if (dueDate == null) {
      return false;
    }

    Date today = System.today();
    Date dueSoonThreshold = today.addDays(3);

    return dueDate <= dueSoonThreshold && dueDate >= today;
  }

  /**
   * @description Vérifier si un élément de travail est en retard.
   * @param dueDate Date d'échéance
   * @param status Statut actuel
   * @return true si la date d'échéance est passée et le statut n'est pas Done
   */
  public static Boolean isOverdue(Date dueDate, String status) {
    if (dueDate == null || status == STATUS_DONE) {
      return false;
    }

    return dueDate < System.today();
  }
}