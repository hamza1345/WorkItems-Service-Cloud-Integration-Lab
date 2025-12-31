// Test Request.getCurrent().getRequestId() format and uniqueness
String reqId1 = Request.getCurrent().getRequestId();
String reqId2 = Request.getCurrent().getRequestId();

System.debug('Request ID 1: ' + reqId1);
System.debug('Request ID 2: ' + reqId2);
System.debug('Contains hyphens: ' + reqId1.contains('-'));
System.debug('Length: ' + reqId1.length());
System.debug('Are equal: ' + reqId1.equals(reqId2));
