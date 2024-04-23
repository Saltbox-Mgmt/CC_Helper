/**
 * Created by dimitrisavelieff on 2020-04-28.
 */

/*****************************************************
 * Author: Zach Engman
 * Created Date: 07/29/2019
 * Last Modified Date: 07/29/2019
 * Last Modified By: Zach Engman
 * Description: Test factory for easy object creation without insertion
 * 	ONLY use from within test classes
 * ****************************************************/
public with sharing class B2BSH_Test_Factory {
    private static final Map<String, Schema.SObjectType> GlobalDescribe = Schema.getGlobalDescribe();
    //General B2B/CloudCraze Constants
    public static final String ACCOUNT_NAME = 'PortalAccount';
    public static final String ACCOUNT_GROUP_NAME = 'PortalAccount';
    public static final String ANON_ACCOUNT_NAME = 'CCAnonymous';
    public static final String ANON_ACCOUNTGROUP_NAME = 'Anonymous';
    public static final String B2B_COMMUNITY_PROFILE_NAME = 'CloudCraze Customer Community User';
    public static final Decimal DEFAULT_PRICE = 100.00;
    public static final String STOREFRONT_NAME = 'DefaultStore';
    public static final String USER_LANGUAGE = 'en_US';

    public static Account createAccount(){
        Account accountRecord = (Account)createSObject('Account');

        accountRecord.Name = ACCOUNT_Name;
        accountRecord.OwnerId = UserInfo.getUserId();

        return accountRecord;
    }

    public static ccrz__E_AccountGroup__c createCCAccountGroup(){
        ccrz__E_AccountGroup__c accountGroupRecord = (ccrz__E_AccountGroup__c)createSObject('ccrz__E_AccountGroup__c');

        accountGroupRecord.Name = ACCOUNT_GROUP_NAME;

        return accountGroupRecord;
    }

    public static ccrz__E_AccountGroupPriceList__c createCCAccountGroupPriceList(string accountGroupId, string priceListId){
        ccrz__E_AccountGroupPriceList__c accountGroupPriceListRecord = (ccrz__E_AccountGroupPriceList__c)createSObject('ccrz__E_AccountGroupPriceList__c');

        accountGroupPriceListRecord.ccrz__AccountGroup__c = accountGroupId;
        accountGroupPriceListRecord.ccrz__PriceList__c = priceListId;
        accountGroupPriceListRecord.ccrz__Enable__c = true;

        return accountGroupPriceListRecord;
    }

    public static ccrz__E_Category__c createCCCategory(){
        ccrz__E_Category__c categoryRecord = (ccrz__E_Category__c)createSObject('ccrz__E_Category__c');

        categoryRecord.Name = 'Products';
        categoryRecord.ccrz__CategoryID__c = '0';
        categoryRecord.ccrz__StartDate__c = Date.today().addDays(-1);
        categoryRecord.ccrz__EndDate__c = Date.today().addDays(1);

        return categoryRecord;
    }

    public static Contact createContact(){
        Contact contactRecord = (Contact)createSObject('Contact');

        contactRecord.FirstName = 'Sample';
        contactRecord.LastName = 'Contact';
        contactRecord.MailingStreet = '111 Rodeo Dr.';
        contactRecord.MailingCity = 'Beverly Hills';
        contactRecord.MailingState = 'CA';
        contactRecord.MailingPostalCode = '90210';

        return contactRecord;
    }

    public static ccrz__E_PriceList__c createCCPriceList(){
        ccrz__E_PriceList__c priceListRecord = (ccrz__E_PriceList__c)createSObject('ccrz__E_PriceList__c');

        priceListRecord.Name = 'PL001';
        priceListRecord.ccrz__CurrencyISOCode__c = 'USD';
        priceListRecord.ccrz__Enabled__c= true;
        priceListRecord.ccrz__Storefront__c = STOREFRONT_NAME;
        priceListRecord.ccrz__StartDate__c = Date.today().addDays(-7);
        priceListRecord.ccrz__EndDate__c = Date.today().addDays(7);

        return priceListRecord;
    }

    public static ccrz__E_PriceListItem__c createCCPriceListItem(string priceListId, string productId){
        ccrz__E_PriceListItem__c priceListItemRecord = (ccrz__E_PriceListItem__c)createSObject('ccrz__E_PriceListItem__c');

        priceListItemRecord.ccrz__Pricelist__c = priceListId;
        priceListItemRecord.ccrz__Product__c = productId;
        priceListItemRecord.ccrz__StartDate__c = Date.today().addDays(-7);
        priceListItemRecord.ccrz__EndDate__c = Date.today().addDays(7);
        priceListItemRecord.ccrz__Price__c = DEFAULT_PRICE;

        return priceListItemRecord;
    }

    public static ccrz__E_Product__c createCCProduct(){
        ccrz__E_Product__c productRecord = (ccrz__E_Product__c)createSObject('ccrz__E_Product__c');

        productRecord.Name = 'product';
        productRecord.ccrz__SKU__c = 'sku';
        productRecord.ccrz__ProductStatus__c = 'Released';
        productRecord.ccrz__UnitOfMeasure__c = 'Each';
        productRecord.ccrz__StartDate__c = Date.today().addDays(-7);
        productRecord.ccrz__EndDate__c  = Date.today().addDays(7);
        productRecord.ccrz__Storefront__c  = STOREFRONT_NAME;

        return productRecord;
    }

    public static ccrz__E_ProductCategory__c createCCProductCategory(string productId, string categoryId){
        ccrz__E_ProductCategory__c productCategoryRecord = (ccrz__E_ProductCategory__c)createSObject('ccrz__E_ProductCategory__c');

        productCategoryRecord.ccrz__Product__c  = productId;
        productCategoryRecord.ccrz__Category__c = categoryId;

        return productCategoryRecord;
    }

    public static User createUser(string profileName){
        String emailAddress = String.valueOf(System.now().getTime() + '@b2b-m360.com');

        Profile profile = [SELECT Id
        FROM Profile
        WHERE Name =: profileName LIMIT 1];

        User userOwner = [SELECT TimeZoneSidKey,
                UserRoleId
        FROM User
        WHERE Id = :UserInfo.getUserId()];

        User userRecord = new User(
                Alias = 'b2btest',
                Email = emailAddress,
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = profile.Id,
                TimeZoneSidKey = userOwner.TimeZoneSidKey,
                Username = emailAddress,
                isActive = true
        );

        return userRecord;
    }

    public static void setupB2BCatalog() {
        //******************************************************************************
        // INSERT ACCOUNT GROUPS
        //******************************************************************************
        List<ccrz__E_AccountGroup__c> accountGroupList = new List<ccrz__E_AccountGroup__c>();
        ccrz__E_AccountGroup__c anonymousAccountGroup = createCCAccountGroup();
        anonymousAccountGroup.Name = ANON_ACCOUNTGROUP_NAME;

        accountGroupList.add(createCCAccountGroup());
        accountGroupList.add(anonymousAccountGroup);

        insert accountGroupList;

        //******************************************************************************
        // INSERT PRICE LISTS
        //******************************************************************************
        List<ccrz__E_PriceList__c> priceLists = new List<ccrz__E_PriceList__c> {createCCPriceList()};
        insert priceLists;

        List<ccrz__E_AccountGroupPriceList__c> accountGroupPriceLists = new List<ccrz__E_AccountGroupPriceList__c>();

        for (ccrz__E_PriceList__c priceList : priceLists) {
            accountGroupPriceLists.add(createCCAccountGroupPriceList(accountGroupList[0].Id, priceList.Id));
            accountGroupPriceLists.add(createCCAccountGroupPriceList(accountGroupList[1].Id, priceList.Id));
        }
        insert accountGroupPriceLists;

        //******************************************************************************
        // INSERT PRODUCTS
        //******************************************************************************
        List<ccrz__E_Product__c> productList = new List<ccrz__E_Product__c>();
        for(integer i = 0; i < 10; i++){
            ccrz__E_Product__c productRecord = createCCProduct();
            productRecord.Name += String.valueOf(i).leftPad(3,'0');
            productRecord.ccrz__SKU__c += String.valueOf(i).leftPad(3, '0');
            productList.add(productRecord);
        }
        insert productList;

        List<ccrz__E_PriceListItem__c> priceListItems = new List<ccrz__E_PriceListItem__c>();

        for (ccrz__E_Product__c product : productList) {
            priceListItems.add(createCCPriceListItem(priceLists.get(0).Id, product.Id));
        }
        insert priceListItems;

        //******************************************************************************
        // INSERT CATEGORIES (ROOT)
        //******************************************************************************
        ccrz__E_Category__c categoryRootRecord = createCCCategory();
        insert categoryRootRecord;

        //******************************************************************************
        // INSERT PRODUCT CATEGORIES
        //******************************************************************************
        List<ccrz__E_ProductCategory__c> productCategoryList = new List<ccrz__E_ProductCategory__c>{
                createCCProductCategory(productList.get(0).Id, categoryRootRecord.Id),
                createCCProductCategory(productList.get(1).Id, categoryRootRecord.Id),
                createCCProductCategory(productList.get(2).Id, categoryRootRecord.Id),
                createCCProductCategory(productList.get(3).Id, categoryRootRecord.Id),
                createCCProductCategory(productList.get(4).Id, categoryRootRecord.Id)
        };

        insert productCategoryList;
    }


    public static SObject createSObject(string objectType){
        Schema.sObjectType objectTypeDescribe = GlobalDescribe.get(objectType);

        if(objectTypeDescribe == null){
            throw new cc_Test_Factory_Exception('Invalid ObjectType: ' + objectType);
        }

        SObject obj = objectTypeDescribe.newSObject();

        return obj;
    }

    //******************************************************************************
    // GENERATE RANDOM STRING
    //******************************************************************************
    public static String generateRandomString(Integer len) {
        final String RANDOM_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String returnValue = '';
        Integer random;
        do {
            random = Math.mod(Math.abs(Crypto.getRandomInteger()),RANDOM_CHARS.length());
            returnValue += RANDOM_CHARS.substring(random,random + 1);
        } while (returnValue.length() < len);

        return returnValue;
    }

    public class cc_Test_Factory_Exception extends Exception{}
}