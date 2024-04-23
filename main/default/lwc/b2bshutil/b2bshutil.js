/**
 * Created by dimitrisavelieff on 2019-07-08.
 */

import {wire, LightningElement, track, api} from 'lwc';
import extractObjectsIds from '@salesforce/apex/B2BSH_Object_Helper.extractObjectsIds';
import runObjQuery from '@salesforce/apex/B2BSH_Object_Helper.runQuery';
import uploadConfigFile from '@salesforce/apex/B2BSH_Object_Helper.uploadConfigFile';
//import getRecordsForFilter from '@salesforce/apex/B2BSH_Object_Helper.getFilteredData';
import getAllConfigs from '@salesforce/apex/B2BSH_Object_Helper.getAllConfigs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import styles from '@salesforce/resourceUrl/SandboxHelperCSS'
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

const columns = [ { label : 'Data Group', fieldName : 'dataGroup', type : 'text'} ];
const gridData = [
    { dataGroup : 'Configuration' },
    { dataGroup : 'Storefront' },
    { dataGroup : 'Account' },
    { dataGroup : 'Product' },
];
const dataGroups = [ 'Configuration', 'Storefront', 'Account', 'Product' ];


const downloadDataAsFile = (name, type, data) => {
    let file = new Blob([data], { type: type });
    if (window.navigator.msSaveOrOpenBlob) { // IE10+
        window.navigator.msSaveOrOpenBlob(file, filename);
    } else { // Others
        let a = document.createElement("a"),
            url = URL.createObjectURL(file);
        a.href = url;
        a.download = name;
        document.body.appendChild(a);
        a.click();
        setTimeout(function () {
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
        }, 0);
    }
};

export default class B2Bshutil extends LightningElement {
    connectedCallback() {
        Promise.all([loadStyle(this, styles)]);
        sessionStorage.clear();
    }
    @track _selected = [];
    @track error;
    @track columns = columns;
    @track gridData = gridData;
    @track currentObject;
    @track filteredObjs = [];
    @track sobjectValues = [];
    @track openmodel = false;
    @track navigation = {
        activePage : "home",
        home : true,
        import : false,
        exportStorefront: false,
        exportConfigs: false,
        exportAccount: false,
        exportProduct: false,
        exportFile: false
    };
    @track settingsToExport = {
        Storefront : {selected:false, selectAll:false},
        Configuration : {selected:false, selectAll:false},
        Account : {selected:false, selectAll:false},
        Product : {selected:false, selectAll:false}
    };
    @track summaryData;
    @track currentExpandedSummary = [];

    dataCategories = ['Storefront','Configuration','Account','Product'];
    summaryColumns = [
        {
            type: 'text',
            fieldName: 'attribute',
            label: 'Attribute'
        }
    ];
    dataCategoriesSelected = [];

    @api progress = 0;
    @api extracting = false;
    @api extractButtonDisabled = false;
    @api hasItemsToExport = false;
    @api doNotChain = false;
    @api filteredColumnNames = [ { label : 'Record Name', fieldName : 'Name', type : 'text'} ];
    //@wire(getAllConfigs) allConfigs;
    @track allConfigs = {};
    @wire(getAllConfigs) getConfigs({ error, data }) {
        if (data) {
            //debugger;
            let modConfig = JSON.parse(JSON.stringify(data));
            this.allConfigs.data = Object.assign({},modConfig);
            this.allConfigs.error = undefined;
        } else if (error) {
            this.allConfigs.error = error;
            this.allConfigs.data = undefined;
        }
    }
    selectedRows = [];
    selectedSObjects = {};


    metadataFieldsView = ['MasterLabel', 'DeveloperName', 'Data_Group__c', 'defaultWhereClause__c', 'resultName__c', 'SObject__c', 'DeleteBeforeLoading__', 'UpsertKey__c'];

    get selected() {
        return this._selected.length ? this._selected : 'none';
    }

    handleFilesChange(e) {
        let parentDom = this;
        let doNotChain = this.doNotChain;
        if(e.target.files.length > 0) {
            //uploader.target.disabled = true;
            console.log('HAS FILE');
            let reader = new FileReader();
            reader.readAsDataURL(e.target.files[0]);
            reader.onloadend = function() {
                let base64data = reader.result;

                uploadConfigFile({ file : base64data.split(',')[1], doNotChain : doNotChain })
                    .then(result => {
                        console.log('file loaded');
                        //uploader.target.disabled = false;
                        parentDom.showToast('File Uploaded','Config file has been uploaded to be processed. You will receive an email once it is complete.', 'success');
                    })
                    .catch(error => {
                        console.log(error);
                        //uploader.target.disabled = false   ;
                        parentDom.showToast('Error','An error has occurred', 'error');
                        console.log('ERROR');
                    });
            };
        } else {
            parentDom.showToast('Warning','No File was added', 'warning');
        }

    }

    initExtract(e) {
        //let button = e.target;
        //button.disabled = true;
        console.log(this.sobjectValues);
        this.progress = 0;
        //debugger;
        this.extracting = true;
        this.extractButtonDisabled = true;
        let configsToQuery = this.getConfigsSelected()  ;
        console.log(configsToQuery);
        console.log(this.selectedSObjects);
        extractObjectsIds( { selectedConfigs : configsToQuery, filteredObjects : JSON.stringify(this.selectedSObjects) })
            .then(result => {
                console.log(result);
                if(result.length > 0) {
                    let configIds = { data :JSON.parse(JSON.stringify(result)) };
                    configIds.originalLength = configIds.data.length;
                    this.runQueries(configIds, '{}');
                }
                //downloadDataAsFile('ExtractedData', 'text/plain', result);
                //button.disabled = false;
            })
            .catch(error => {
                console.log(error);
                debugger;
                this.extracting = false;
                this.extractButtonDisabled = false;
                //button.disabled = false;
            });
    }

    getConfigsSelected() {
        let configsToQuery = [];
        if(this.settingsToExport.Account.selected) configsToQuery.push('Account');
        if(this.settingsToExport.Storefront.selected) configsToQuery.push('Storefront');
        if(this.settingsToExport.Product.selected) configsToQuery.push('Product');
        if(this.settingsToExport.Configuration.selected) configsToQuery.push('Configuration');
        return configsToQuery;
    }
    runQueries(configIds, extractedItems) {
        let configId = configIds.data.shift();
        runObjQuery( { configId : configId, returnedObjects : extractedItems, filteredObjects: JSON.stringify(this.selectedSObjects)})
            .then(result => {
                if(configIds.data.length > 0) {
                    this.progress = Math.round(((configIds.originalLength-configIds.data.length)/configIds.originalLength)*100);
                    this.runQueries(configIds, result);
                } else {
                    this.progress = 100;
                    console.log('FINISHED');
                    console.log(configIds);
                    let today = new Date();
                    downloadDataAsFile('ExtractedData '
                                +today.getFullYear() + "-"
                                + (today.getMonth() + 1)+ "-"
                                + today.getDate() + "_"
                                + today.getHours() + "-"
                                + today.getMinutes() + "-"
                                + today.getSeconds(),
                        'text/plain', result);
                    this.extracting = false;
                    this.extractButtonDisabled = false;
                    //buttonDom.disabled = false;
                }
            })
            .catch(error => {
                debugger;
                this.extracting = false;
                this.extractButtonDisabled = false;
                //buttonDom.disabled = false;
            });

    }

    handleDoNotChainJobsCheckbox(e) {
        this.doNotChain = e.target.checked;
    }

    // getSelectedRow(e) {
    //     //debugger;
    //     let oldArray = this.selectedRows.slice();
    //     this.selectedRows = e.detail.selectedRows;
    //     let difference = this.selectedRows.filter(x => !oldArray.includes(x));
    //
    //     if(difference.length > 0) {
    //         let currConfig = difference[0];
    //         getRecordsForFilter({configSetting : currConfig})
    //             .then(result => {
    //                 //this.filteredObjs = result;
    //             })
    //             .catch(error =>{
    //                 console.log(error);
    //             })
    //     }
    // }
    // handleDataGroupTabSelect(e) {
    //     let currConfig = e.target.label;
    //     if(typeof this.filteredObjs[currConfig] === 'undefined') {
    //         getRecordsForFilter({configSetting: currConfig})
    //             .then(result => {
    //                 if(typeof result !== 'undefined') {
    //                     //this.filteredObjs[currConfig] = result;
    //                     this.setConfigSobjects(result, currConfig);
    //                 } else {
    //                     //this.filteredObjs[currConfig] = [];
    //                     this.setConfigSobjects([], currConfig);
    //                 }
    //
    //                // debugger;
    //             })
    //             .catch(error => {
    //                 console.log(error);
    //                 debugger;
    //             })
    //     }
    // }

    setConfigSobjects(results, currConfig) {
        let modConfig = JSON.parse(JSON.stringify(this.allConfigs));
        if(typeof modConfig.data !== 'undefined') {
            for (let config of modConfig.data) {
                if(config.dataGroup == currConfig) {
                    //debugger;
                    config.filteredObjs = results;
                }
            }
        }
        this.allConfigs = Object.assign({},modConfig);
    }
    handleSobjectSelect(e) {
        let dataGroup = e.target.parentElement.parentElement.title;
        let configSetting = this.allConfigs.data[dataGroup][e.target.title];
        this.sobjectSelect(dataGroup,configSetting,!configSetting.isSelected);

    }

    sobjectSelect(dataGroup, configSetting, selectionStatus) {
        if(typeof this.selectedSObjects[dataGroup] === 'undefined') {
            this.selectedSObjects[dataGroup] ={};
        }

        if(typeof this.selectedSObjects[dataGroup].sobjects  === 'undefined'){
            this.selectedSObjects[dataGroup].sobjects = [];
        }

        configSetting.isSelected = selectionStatus;
        if(configSetting.isSelected&& this.selectedSObjects[dataGroup].sobjects.indexOf(configSetting.value) < 0){
            this.selectedSObjects[dataGroup].sobjects.push(configSetting.value);
            if(this.selectedSObjects[dataGroup].sobjects.length == this.allConfigs.data[dataGroup].length) {
                this.settingsToExport[dataGroup].allSelected = true;
            }
        } else if(!configSetting.isSelected && this.selectedSObjects[dataGroup].sobjects.indexOf(configSetting.value) >= 0) {
            this.selectedSObjects[dataGroup].sobjects.splice(this.selectedSObjects[dataGroup].sobjects.indexOf(configSetting.value), 1);
            if(this.selectedSObjects[dataGroup].sobjects.length != this.allConfigs.data[dataGroup].length) {
                this.settingsToExport[dataGroup].allSelected = false;
            }
        }
    }

    selectAllSobjects(e){

        let dataGroup = e.target.parentElement.parentElement.title;
        this.runSelectAllSobjects(e,dataGroup);
    }

    runSelectAllSobjects(e, dataGroup) {
        this.settingsToExport[dataGroup].allSelected = !this.settingsToExport[dataGroup].allSelected;
        this.allConfigs.data[dataGroup].forEach((config) => {
            this.sobjectSelect(dataGroup,config,this.settingsToExport[dataGroup].allSelected);
        });
    }
    runDeselectAll(e, dataGroup) {
        this.settingsToExport[dataGroup].allSelected = false;
        this.allConfigs.data[dataGroup].forEach((config) => {
            if(this.selectedSObjects[dataGroup]){
                if(this.selectedSObjects[dataGroup].sobjects){
                    if(this.selectedSObjects[dataGroup].sobjects.indexOf(config.value) >= 0){
                        this.selectedSObjects[dataGroup].sobjects.splice(this.selectedSObjects[dataGroup].sobjects.indexOf(config.value), 1);
                        config.isSelected = false;
                    }
                }
            }
        });
    }
    handleRecordFilterSelect(e) {
        //debugger;
        let dataGroup = e.target.parentElement.label;
        let oldArray = [];
        if(typeof this.selectedSObjects[dataGroup] === 'undefined') {
            this.selectedSObjects[dataGroup] = [];
        }
        if(typeof this.selectedSObjects[dataGroup].filteredRecords  !== 'undefined')
        {
            oldArray = this.selectedSObjects[dataGroup].filteredRecords.slice();
        }


        this.selectedSObjects[dataGroup].filteredRecords = e.detail.selectedRows;
        let difference = this.selectedSObjects[dataGroup].filteredRecords.filter(x => !oldArray.includes(x));

        if(difference.length > 0) {

        }
    }

    handleFilteredData(event){
        debugger;
        if(event.detail.callback){
            if(typeof this[event.detail.callback] === 'function') {
                this[event.detail.callback](event.detail.records);
            }
        }

    }

    setAccountRecordObjects(event){
        this.selectedSObjects["Account"].filteredRecords = [];
        if(event.detail.records){
            for(let index in event.detail.records){
                let record = event.detail.records[index];
                if(record["Id"]){
                    this.selectedSObjects["Account"].filteredRecords.push(record);
                }
            }
        }
    }

    setProductRecordObjects(event){
        this.selectedSObjects["Product"].filteredRecords = [];
        if(event.detail.records){
            for(let index in event.detail.records){
                let record = event.detail.records[index];
                if(record["Id"]){
                    this.selectedSObjects["Product"].filteredRecords.push(record);
                }
            }
        }
    }


    showToast(title, message, variant) {
        let event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    openNewModelWindow(e){
        openmodel = true;
    }

    closeNewModelWindow(e){
        openmodel = false;
    }

    handleNav(e) {
        let navSelect = '';
        if(e.target.tagName == 'LIGHTNING-PROGRESS-STEP') {
            navSelect = e.target.value;
        } else {
            navSelect = e.target.name;
        }

        if(this.navigation[navSelect] === undefined) navSelect = home;
        this.navigation[this.navigation.activePage] = false;
        this.navigation[navSelect] = true;
        this.navigation.activePage = navSelect;
        if(navSelect == 'exportFile') {
            this.createSummarydata();
        }
    }

    handleNavExportCats(e){

    }

    queueCategory(e){
        this.settingsToExport[e.target.title].selected = true;
        this.runSelectAllSobjects(e,e.target.title);
    }
    removeCategory(e) {
        this.settingsToExport[e.target.title].selected = false;
        this.runDeselectAll(e,e.target.title);
        this.handleNav(e);
    }

    createSummarydata() {
        this.summaryData = [];
        for(let dataGroup in this.dataCategories) {
            let childrenArray = [];
            for(let childIndex in this.allConfigs.data[this.dataCategories[dataGroup]]) {
                let child = this.allConfigs.data[this.dataCategories[dataGroup]][childIndex];
                if(child.isSelected) {
                    childrenArray.push({attribute:child.label});
                }
            }
            if(childrenArray.length > 0) {
                this.summaryData.push({attribute:this.dataCategories[dataGroup], _children:childrenArray});
                this.currentExpandedSummary.push(this.dataCategories[dataGroup]);
            }

        }
        if(this.summaryData.length > 0) {
            this.extractButtonDisabled = false;
            this.hasItemsToExport = true;
        } else {
            this.extractButtonDisabled = true;
            this.hasItemsToExport = false;
        }

    }

    testHover(){
        console.log('hovered');
    }


    getDefaultGroupId(dataGroup) {
        if(typeof this.allConfigs.data !== 'undefined') {
            for (let config of this.allConfigs.data) {
                if(config.dataGroup == dataGroup) {
                    let key = '';
                    switch(dataGroup) {
                        case 'Account':
                            key = 'ccrz__E_AccountGroup__c';
                            break;
                        case 'Product':
                            key = 'ccrz__E_Product__c';
                            // code block
                            break;
                        default:
                            return '';
                    }
                    let ret = ''
                    for (let cRow of config.data) {
                        if(cRow.label == key) {
                            ret = cRow.value;
                        }
                    }
                    return ret;
                }

            }
        }
    }

}