/**
 * @author Hamza Amari
 * @date 31/12/2025
 * @description Tests unitaires pour BusinessException.
 */
@IsTest
private class BusinessExceptionTest {
  
  /**
   * @description Teste factory method withCode.
   */
  @IsTest
  static void testWithCode() {
    Test.startTest();
    BusinessException ex = BusinessException.withCode('TEST_CODE');
    Test.stopTest();
    
    Assert.areEqual('TEST_CODE', ex.getErrorCode(), 'Le code devrait être TEST_CODE');
  }
  
  /**
   * @description Teste chainable withMessage.
   */
  @IsTest
  static void testWithMessage() {
    Test.startTest();
    BusinessException ex = BusinessException.withCode('ERR_001').withMessage('Test error');
    Test.stopTest();
    
    Assert.areEqual('ERR_001', ex.getErrorCode(), 'Code devrait être ERR_001');
    Assert.areEqual('Test error', ex.getMessage(), 'Message devrait être Test error');
  }
  
  /**
   * @description Teste setter/getter errorCode.
   */
  @IsTest
  static void testSetAndGetErrorCode() {
    Test.startTest();
    BusinessException ex = BusinessException.withCode('INITIAL');
    ex.setErrorCode('UPDATED');
    Test.stopTest();
    
    Assert.areEqual('UPDATED', ex.getErrorCode(), 'Code devrait être UPDATED');
  }
  
  /**
   * @description Teste toString avec code et message.
   */
  @IsTest
  static void testToStringWithCodeAndMessage() {
    Test.startTest();
    BusinessException ex = BusinessException.withCode('ERR_001').withMessage('Something failed');
    String result = ex.toString();
    Test.stopTest();
    
    Assert.isTrue(result.contains('ERR_001'), 'toString devrait contenir code');
    Assert.isTrue(result.contains('Something failed'), 'toString devrait contenir message');
  }
  
  /**
   * @description Teste toString sans code.
   */
  @IsTest
  static void testToStringWithoutCode() {
    Test.startTest();
    BusinessException ex = new BusinessException();
    ex.setMessage('Generic error');
    String result = ex.toString();
    Test.stopTest();
    
    Assert.isTrue(result.contains('Generic error'), 'toString devrait contenir message');
  }
  
  /**
   * @description Teste throw et catch.
   */
  @IsTest
  static void testThrowAndCatch() {
    Boolean caught = false;
    
    Test.startTest();
    try {
      throw BusinessException.withCode('VALIDATION_ERROR').withMessage('Invalid status');
    } catch (BusinessException ex) {
      caught = true;
      Assert.areEqual('VALIDATION_ERROR', ex.getErrorCode(), 'Code devrait correspondre');
    }
    Test.stopTest();
    
    Assert.isTrue(caught, 'Exception devrait être catchée');
  }
  
  /**
   * @description Teste catch comme Exception générique.
   */
  @IsTest
  static void testCatchAsGenericException() {
    Boolean caught = false;
    
    Test.startTest();
    try {
      throw BusinessException.withCode('GENERIC_ERROR');
    } catch (Exception ex) {
      caught = true;
    }
    Test.stopTest();
    
    Assert.isTrue(caught, 'Exception devrait être catchée comme Exception');
  }
}
