/**
 * @author Hamza Amari
 * @date 26/12/2025
 * @description Tests unitaires pour la logique métier WorkItemDomain.
 * Couverture de test :
 * - Validation des enregistrements d'éléments de travail
 * - Remplissage des valeurs par défaut
 * - Application des règles métier
 * - Validation de la transition de statut
 * - Calcul du pourcentage d'achèvement
 */
@IsTest
private class WorkItemDomainTest {
  /**
   * @description Tester la validation avec des enregistrements valides.
   */
  @IsTest
  static void testValidateWithValidRecords() {
    // Arrange
    Work_Item__c validItem = new Work_Item__c(Name = 'Test Item', Status__c = 'New');

    // Act
    List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ validItem });

    // Assert
    Assert.isTrue(errors.isEmpty(), 'Aucune erreur ne devrait être retournée pour un enregistrement valide');
  }

  /**
   * @description Tester la validation rejette les enregistrements sans nom.
   */
  @IsTest
  static void testValidateRejectsNoName() {
    // Arrange
    Work_Item__c invalidItem = new Work_Item__c(Name = '', Status__c = 'New');

    // Act
    List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ invalidItem });

    // Assert
    Assert.isFalse(errors.isEmpty(), 'Une erreur devrait être retournée pour un enregistrement sans nom');
    Assert.isTrue(
      errors[0].contains('requis'),
      'Le message d\'erreur doit indiquer que le nom est requis'
    );
  }

  /**
   * @description Tester la validation rejette Done quand Due_Date < today.
   */
  @IsTest
  static void testValidateRejectsDoneWithPastDueDate() {
    // Arrange
    Work_Item__c item = new Work_Item__c(
      Name = 'Test Item',
      Status__c = 'Done',
      Due_Date__c = System.today().addDays(-1)
    );

    // Act
    List<String> errors = WorkItemDomain.validate(new List<Work_Item__c>{ item });

    // Assert
    Assert.isFalse(errors.isEmpty(), 'Validation devrait rejeter Done avec due date dans le passé');
    Assert.isTrue(
      errors[0].contains('passé'),
      'Le message d\'erreur doit mentionner la date passée'
    );
  }

  /**
   * @description Tester populateDefaults assigne Status = New.
   */
  @IsTest
  static void testPopulateDefaultsAssignsStatus() {
    // Arrange
    Work_Item__c item = new Work_Item__c(Name = 'Test Item');

    // Act
    WorkItemDomain.populateDefaults(new List<Work_Item__c>{ item });

    // Assert
    Assert.areEqual('New', item.Status__c, 'Status devrait être défini à New par défaut');
  }

  /**
   * @description Tester populateDefaults assigne Priority = Medium.
   */
  @IsTest
  static void testPopulateDefaultsAssignsPriority() {
    // Arrange
    Work_Item__c item = new Work_Item__c(Name = 'Test Item');

    // Act
    WorkItemDomain.populateDefaults(new List<Work_Item__c>{ item });

    // Assert
    Assert.areEqual('Medium', item.Priority__c, 'Priority devrait être définie à Medium par défaut');
  }

  /**
   * @description Tester applyBusinessRules remplit Completed_On quand Status = Done.
   */
  @IsTest
  static void testApplyBusinessRulesCompletesOnDone() {
    // Arrange - Créer des Work Items réels pour les IDs
    List<Work_Item__c> itemsToInsert = new List<Work_Item__c>();
    Work_Item__c item1 = new Work_Item__c(Name = 'Test Item 1', Status__c = 'In_Progress');
    itemsToInsert.add(item1);
    insert itemsToInsert;

    // Act - Récupérer l'item inséré et le mettre à jour
    Work_Item__c oldItem = new Work_Item__c(Id = item1.Id, Status__c = 'In_Progress');
    Work_Item__c newItem = new Work_Item__c(Id = item1.Id, Status__c = 'Done');
    Map<Id, Work_Item__c> oldMap = new Map<Id, Work_Item__c>{ oldItem.Id => oldItem };

    WorkItemDomain.applyBusinessRules(new List<Work_Item__c>{ newItem }, oldMap);

    // Assert
    Assert.isNotNull(newItem.Completed_On__c, 'Completed_On devrait être rempli quand Status passe à Done');
  }

  /**
   * @description Tester isStatusTransitionValid accepte transitions valides.
   */
  @IsTest
  static void testStatusTransitionValidForValid() {
    // Arrange & Act
    Boolean newToProgress = WorkItemDomain.isStatusTransitionValid('New', 'In_Progress');
    Boolean progressToDone = WorkItemDomain.isStatusTransitionValid('In_Progress', 'Done');

    // Assert
    Assert.isTrue(newToProgress, 'New -> In_Progress devrait être valide');
    Assert.isTrue(progressToDone, 'In_Progress -> Done devrait être valide');
  }

  /**
   * @description Tester isStatusTransitionValid rejette transitions invalides.
   */
  @IsTest
  static void testStatusTransitionRejectsInvalid() {
    // Arrange & Act
    Boolean invalidTransition = WorkItemDomain.isStatusTransitionValid('Done', 'In_Progress');

    // Assert
    Assert.isFalse(invalidTransition, 'Done -> In_Progress ne devrait pas être valide');
  }

  /**
   * @description Tester calculateCompletionPercentage retourne les bonnes valeurs.
   */
  @IsTest
  static void testCalculateCompletionPercentage() {
    // Arrange & Act
    Integer newCompletion = WorkItemDomain.calculateCompletionPercentage('New');
    Integer progressCompletion = WorkItemDomain.calculateCompletionPercentage('In_Progress');
    Integer doneCompletion = WorkItemDomain.calculateCompletionPercentage('Done');

    // Assert
    Assert.areEqual(0, newCompletion, 'New devrait avoir 0% d\'achèvement');
    Assert.areEqual(50, progressCompletion, 'In_Progress devrait avoir 50% d\'achèvement');
    Assert.areEqual(100, doneCompletion, 'Done devrait avoir 100% d\'achèvement');
  }

  /**
   * @description Tester isDueSoon retourne true pour dates proches.
   */
  @IsTest
  static void testIsDueSoon() {
    // Arrange
    Date tomorrow = System.today().addDays(1);
    Date inThreeDays = System.today().addDays(3);
    Date inFiveDays = System.today().addDays(5);

    // Act & Assert
    Assert.isTrue(WorkItemDomain.isDueSoon(tomorrow), 'Tomorrow devrait être due soon');
    Assert.isTrue(WorkItemDomain.isDueSoon(inThreeDays), '3 jours devrait être due soon');
    Assert.isFalse(WorkItemDomain.isDueSoon(inFiveDays), '5 jours ne devrait pas être due soon');
  }

  /**
   * @description Tester isOverdue retourne true pour dates passées (sauf Done).
   */
  @IsTest
  static void testIsOverdue() {
    // Arrange
    Date yesterday = System.today().addDays(-1);

    // Act & Assert
    Assert.isTrue(WorkItemDomain.isOverdue(yesterday, 'In_Progress'), 'Hier avec In_Progress devrait être overdue');
    Assert.isFalse(WorkItemDomain.isOverdue(yesterday, 'Done'), 'Hier avec Done ne devrait pas être overdue');
  }

  /**
   * @description Tester que null lists sont gérées proprement.
   */
  @IsTest
  static void testNullListHandling() {
    // Act
    List<String> errors = WorkItemDomain.validate(null);
    WorkItemDomain.populateDefaults(null);

    // Assert
    Assert.isTrue(errors.isEmpty(), 'Null list devrait retourner liste vide');
    // No exception should be thrown
  }

  /**
   * @description Tester validation avec messages d'erreur métier clairs.
   */
  @IsTest
  static void testValidationErrorMessages() {
    // Arrange
    Work_Item__c itemWithInvalidStatus = new Work_Item__c(Name = 'Test', Status__c = 'InvalidStatus');
    Work_Item__c itemWithInvalidPriority = new Work_Item__c(
      Name = 'Test',
      Status__c = 'New',
      Priority__c = 'InvalidPriority'
    );

    // Act
    List<String> errors1 = WorkItemDomain.validate(new List<Work_Item__c>{ itemWithInvalidStatus });
    List<String> errors2 = WorkItemDomain.validate(new List<Work_Item__c>{ itemWithInvalidPriority });

    // Assert
    Assert.isFalse(errors1.isEmpty(), 'Statut invalide devrait produire une erreur');
    Assert.isFalse(errors2.isEmpty(), 'Priorité invalide devrait produire une erreur');
  }
}
