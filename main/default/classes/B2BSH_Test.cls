/**
 * Created by dimitrisavelieff on 2019-07-30.
 */
@isTest
public with sharing class B2BSH_Test {
    @testSetup static void setup() {
        ccrz__E_AccountGroup__c accountGroupRecord = B2BSH_Test_Factory.createCCAccountGroup();
        insert accountGroupRecord;

        Account accountRecord = B2BSH_Test_Factory.createAccount();
        accountRecord.ccrz__E_AccountGroup__c = accountGroupRecord.Id;
        system.debug(accountRecord);
        insert accountRecord;

        Contact contactRecord = B2BSH_Test_Factory.createContact();
        contactRecord.AccountId = accountRecord.Id;
        insert contactRecord;

        User b2bUser = B2BSH_Test_Factory.createUser(B2BSH_Test_Factory.B2B_COMMUNITY_PROFILE_NAME);
        b2bUser.ContactId = contactRecord.Id;
        b2bUser.Contact = contactRecord;
        insert b2bUser;

        B2BSH_Test_Factory.setupB2BCatalog();
    }

    static testMethod void testExtractObjectsIds() {
        Map<String, Map<String,List<String>>> objs = new Map<String, Map<String,List<String>>>();
        List<String> configIds = new List<String>();
        for(B2BHelperConfig__mdt config :[Select Id from B2BHelperConfig__mdt where Data_Group__c = 'Account']){
            configIds.add(config.Id);
        }
        objs.put('Account',new Map<String,List<String>>{'sobjects'=>configIds});
        String filteredObjects = JSON.serialize(objs);
        List<String> resStrings = B2BSH_Object_Helper.extractObjectsIds(new List<String>{'Account'},filteredObjects);
        String returnedObjects = '{}';
        for(String configId :resStrings) {
            returnedObjects = B2BSH_Object_Helper.runQuery(configId,returnedObjects,filteredObjects);
        }
        Map<String, List<SObject>> returnedSbjectMap = (Map<String, List<SObject>>) Json.deserialize(returnedObjects, Map<String, List<SObject>>.class);
        System.assert(returnedSbjectMap.containsKey('acctGrps') && returnedSbjectMap.get('acctGrps').size() > 0);
        System.assert(returnedSbjectMap.containsKey('accts') && returnedSbjectMap.get('accts').size() > 0);
        System.assert(returnedSbjectMap.containsKey('cons') && returnedSbjectMap.get('cons').size() > 0);
    }

    static testMethod void testExtractObjectsIdsFiltered() {
        Map<String, Map<String,Object>> objs = new Map<String, Map<String,Object>>();
        List<String> configIds = new List<String>();
        Account acc = [Select Id, ccrz__E_AccountGroup__c from Account limit 1];
        for(B2BHelperConfig__mdt config :[Select Id from B2BHelperConfig__mdt where Data_Group__c = 'Account']){
            configIds.add(config.Id);
        }
        objs.put('Account',new Map<String,Object>{'sobjects'=>configIds,
        'filteredRecords'=>new List<Map<String,String>>{new Map<String, String>{'Id'=>acc.Id, 'ccrz__E_AccountGroup__c'=>acc.ccrz__E_AccountGroup__c}}});
        String filteredObjects = JSON.serialize(objs);
        List<String> resStrings = B2BSH_Object_Helper.extractObjectsIds(new List<String>{'Account'},filteredObjects);
        String returnedObjects = '{}';
        for(String configId :resStrings) {
            returnedObjects = B2BSH_Object_Helper.runQuery(configId,returnedObjects,filteredObjects);
        }
        Map<String, List<SObject>> returnedSbjectMap = (Map<String, List<SObject>>) Json.deserialize(returnedObjects, Map<String, List<SObject>>.class);
        System.assert(returnedSbjectMap.containsKey('acctGrps') && returnedSbjectMap.get('acctGrps').size() > 0);
        System.assert(returnedSbjectMap.containsKey('accts') && returnedSbjectMap.get('accts').size() > 0);
        System.assert(returnedSbjectMap.containsKey('cons') && returnedSbjectMap.get('cons').size() > 0);
    }

    static testMethod void testLoadObjects() {
        String json = '{"opps":[],"acctGrpPrclst":[],"accts":[{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/0016C00000ETp1pQAD"},"ccrz__PreventAddrBookSave__c":false,"Name":"CCAnonymous","AccountNumber":"CCAnonymous","ccrz__TaxExemptAccount__c":false,"ccrz__PreventNewBillAddrCO__c":false,"ccrz__SourceSystem__c":"CloudCraze","OwnerId":"0051U000003pZIGQA2","ccrz__E_AccountGroup__c":"a046C0000012SYbQAM","ccrz__DataId__c":"CCANONYMOUS","ccrz__PreventNewAddrCheckout__c":false,"ccrz__UsedByCloudcraze__c":true,"Id":"0016C00000ETp1pQAD"},{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/0016C00000ETp1qQAD"},"ccrz__PreventAddrBookSave__c":false,"Name":"PortalAccount","AccountNumber":"PortalAccount","ccrz__TaxExemptAccount__c":false,"ccrz__PreventNewBillAddrCO__c":false,"ccrz__SourceSystem__c":"CloudCraze","OwnerId":"0051U000003pZIGQA2","ccrz__E_AccountGroup__c":"a046C0000012SYcQAM","ccrz__DataId__c":"PORTALACCOUNT","ccrz__PreventNewAddrCheckout__c":false,"ccrz__UsedByCloudcraze__c":true,"Id":"0016C00000ETp1qQAD"},{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/0016C00000ETp1rQAD"},"ParentId":"0016C00000ETp1sQAD","BillingCity":"Boston","ccrz__PreventAddrBookSave__c":false,"Name":"Atlantic Coffee","ShippingStreet":"180 Clarendon Street","AccountNumber":"AC01","ccrz__TaxExemptAccount__c":false,"ccrz__PreventNewBillAddrCO__c":false,"BillingCountry":"United States","BillingStreet":"180 Clarendon Street","OwnerId":"0051U000003pZIGQA2","Phone":"2345678901","ShippingPostalCode":"02116","ShippingCountry":"United States","ccrz__E_AccountGroup__c":"a046C0000012SYdQAM","BillingPostalCode":"02116","ShippingCity":"Boston","ShippingState":"MA","ccrz__DataId__c":"ATL-COFFEE","ccrz__PreventNewAddrCheckout__c":false,"ccrz__UsedByCloudcraze__c":false,"Id":"0016C00000ETp1rQAD","BillingState":"MA"},{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/0016C00000ETp1sQAD"},"BillingCity":"West Warwick","ccrz__PreventAddrBookSave__c":false,"Website":"https://www.capricorn.company/","NumberOfEmployees":150,"Name":"Central Perc Coffee","Industry":"Food & Beverage","ccrz__PreventNewBillAddrCO__c":false,"OwnerId":"0051U000003pZIGQA2","Phone":"(401) 555-5200","ShippingCountry":"United States","BillingPostalCode":"02116","ShippingCity":"San Jose","ccrz__DataId__c":"CENTRAL-PERC-COFFEE","ccrz__PreventNewAddrCheckout__c":false,"ShippingStreet":"178 San Jose Ave","AccountNumber":"CPC","ccrz__TaxExemptAccount__c":false,"Type":"Customer","BillingCountry":"United States","BillingStreet":"PO Box 1019","ShippingPostalCode":"95125","ccrz__E_AccountGroup__c":"a046C0000012SYcQAM","ShippingState":"CA","ccrz__UsedByCloudcraze__c":false,"Id":"0016C00000ETp1sQAD","BillingState":"RI","AnnualRevenue":1400045},{"attributes":{"type":"Account","url":"/services/data/v46.0/sobjects/Account/0016C00000ETp1tQAD"},"ParentId":"0016C00000ETp1sQAD","BillingCity":"Santa Monica","ccrz__PreventAddrBookSave__c":false,"Name":"Pacific Coffee","ShippingStreet":"100 3rd Street","AccountNumber":"PC01","ccrz__TaxExemptAccount__c":false,"ccrz__PreventNewBillAddrCO__c":false,"BillingCountry":"United States","BillingStreet":"100 3rd Street","OwnerId":"0051U000003pZIGQA2","Phone":"1234567890","ShippingPostalCode":"90401","ShippingCountry":"United States","ccrz__E_AccountGroup__c":"a046C0000012SYeQAM","BillingPostalCode":"90401","ShippingCity":"Santa Monica","ShippingState":"CA","ccrz__DataId__c":"PAC-COFFEE","ccrz__PreventNewAddrCheckout__c":false,"ccrz__UsedByCloudcraze__c":false,"Id":"0016C00000ETp1tQAD","BillingState":"CA"}],"acctGrps":[{"attributes":{"type":"ccrz__E_AccountGroup__c","url":"/services/data/v46.0/sobjects/ccrz__E_AccountGroup__c/a046C0000012SYbQAM"},"ccrz__AccountGroupID__c":"ANONYMOUS","ccrz__PriceListSelectionMethod__c":"Best Price","OwnerId":"0051U000003pZIGQA2","Id":"a046C0000012SYbQAM","Name":"Anonymous"},{"attributes":{"type":"ccrz__E_AccountGroup__c","url":"/services/data/v46.0/sobjects/ccrz__E_AccountGroup__c/a046C0000012SYcQAM"},"ccrz__AccountGroupID__c":"PORTALACCOUNT","ccrz__PriceListSelectionMethod__c":"Best Price","OwnerId":"0051U000003pZIGQA2","Id":"a046C0000012SYcQAM","Name":"PortalAccount"},{"attributes":{"type":"ccrz__E_AccountGroup__c","url":"/services/data/v46.0/sobjects/ccrz__E_AccountGroup__c/a046C0000012SYdQAM"},"ccrz__AccountGroupID__c":"ATL-COFFEE","ccrz__PriceListSelectionMethod__c":"Best Price","OwnerId":"0051U000003pZIGQA2","Id":"a046C0000012SYdQAM","Name":"Atlantic Coffee"},{"attributes":{"type":"ccrz__E_AccountGroup__c","url":"/services/data/v46.0/sobjects/ccrz__E_AccountGroup__c/a046C0000012SYeQAM"},"ccrz__AccountGroupID__c":"PAC-COFFEE","ccrz__PriceListSelectionMethod__c":"Best Price","OwnerId":"0051U000003pZIGQA2","Id":"a046C0000012SYeQAM","Name":"Pacific Coffee"}],"cons":[{"attributes":{"type":"Contact","url":"/services/data/v46.0/sobjects/Contact/0036C00000AnZdoQAF"},"AccountId":"0016C00000ETp1rQAD","DoNotCall":false,"FirstName":"Cathy","OtherPostalCode":"60616","MailingCountry":"US","HasOptedOutOfEmail":false,"Title":"Procurement Specialist","HasOptedOutOfFax":false,"MailingCity":"Chicago","Salutation":"Ms.","OtherStreet":"2100 N 95th Street","OtherState":"IL","ccrz__IsPortalUser__c":false,"MailingState":"IL","ccrz__SelfRegistered__c":false,"OwnerId":"0051U000003pZIGQA2","OtherCity":"Chicago","Phone":"3121231234","MailingPostalCode":"60616","OtherCountry":"US","LastName":"Customer","Id":"0036C00000AnZdoQAF","MailingStreet":"2100 N 95th Street"}],"cases":[]}';
        String jsonEncoded = EncodingUtil.base64Encode(Blob.valueof(json));
        test.startTest();
        B2BSH_Object_Helper.uploadConfigFile(jsonEncoded,false);
        test.stopTest();
        system.assertEquals(7,[Select COUNT() from ccrz__E_AccountGroup__c]);
        system.assertEquals(6,[Select COUNT() from Account]);
        system.assertEquals(2,[Select COUNT() from Contact]);

    }




}