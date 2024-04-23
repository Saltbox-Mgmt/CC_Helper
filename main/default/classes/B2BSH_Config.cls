/**
 * Created by dimitrisavelieff on 2019-06-20.
 */

global with sharing class B2BSH_Config{
    public Id configId;
    public B2BHelperConfig__mdt setting;
    public String query;
    public String resultName;
    public String SObjectName;
    public Set<Id> childrenIds;
    @AuraEnabled
    public configSelectOption optionValue;

    public B2BSH_Config(B2BHelperConfig__mdt p_setting) {
        this.configId = p_setting.Id;
        this.setting = p_setting;
        this.resultName = p_setting.resultName__c;
        this.SObjectName = p_setting.SObject__c;
        childrenIds = new Set<Id>();
        for(B2BHelperDependency__mdt child:p_setting.DependentConfigs__r) {
            childrenIds.add(child.ChildConfig__c);
        }
        this.optionValue = new configSelectOption(this.SObjectName, this.configId, p_setting);


    }

    public Integer compareTo(Object compareTo) {
        B2BSH_Config compareToB2BSHConfig = (B2BSH_Config)compareTo;
        //system.debug('comparing '+compareToB2BSHConfig.resultName+' to '+this.resultName);
        if(this.childrenIds.contains(compareToB2BSHConfig.configId)) {
            //this.childrenIds.addAll(compareToB2BSHConfig.childrenIds);
            return -1;
        } else {
            return 1;
        }
    }

    public class configSelectOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public B2BHelperConfig__mdt setting;

        public configSelectOption(String label, String value, B2BHelperConfig__mdt setting) {
            this.label = label;
            this.value = value;
            this.setting = setting;
        }
    }
}