/**
 * Created by dimitrisavelieff on 2020-04-28.
 */

import {wire, LightningElement, track, api} from 'lwc';
import extractObjectsIds from '@salesforce/apex/B2BSH_Object_HelperOld.extractObjectsIds';
import runObjQuery from '@salesforce/apex/B2BSH_Object_HelperOld.runQuery';
import uploadConfigFile from '@salesforce/apex/B2BSH_Object_HelperOld.uploadConfigFile';
import getRecordsForFilter from '@salesforce/apex/B2BSH_Object_HelperOld.getFilteredData';
import getAllConfigs from '@salesforce/apex/B2BSH_Object_HelperOld.getAllConfigs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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

export default class B2Bshutilold extends LightningElement {
    @track _selected = [];
    @track error;
    @track columns = columns;
    @track gridData = gridData;
    @track currentObject;
    @track filteredObjs = [];
    @track sobjectValues = [];

    @api progress = 0;
    @api extracting = false;
    @api doNotChain = false;
    @api filteredColumnNames = [ { label : 'Record Name', fieldName : 'Name', type : 'text'} ];
    @wire(getAllConfigs) allConfigs;
    selectedRows = [];
    selectedSObjects = {};

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
        debugger;
        this.extracting = true;
        let configsToQuery = [];
        for (let i = 0; i < this.selectedRows.length; i++){
            configsToQuery.push(this.selectedRows[i].dataGroup);
        }
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
                //button.disabled = false;
            });
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
                    //buttonDom.disabled = false;
                }
            })
            .catch(error => {
                debugger;
                this.extracting = false;
                //buttonDom.disabled = false;
            });

    }

    handleDoNotChainJobsCheckbox(e) {
        this.doNotChain = e.target.checked;
    }

    getSelectedRow(e) {
        //debugger;
        let oldArray = this.selectedRows.slice();
        this.selectedRows = e.detail.selectedRows;
        let difference = this.selectedRows.filter(x => !oldArray.includes(x));

        if(difference.length > 0) {
            let currConfig = difference[0];
            getRecordsForFilter({configSetting : currConfig})
                .then(result => {
                    //this.filteredObjs = result;
                })
                .catch(error =>{
                    console.log(error);
                })
        }
    }
    handleDataGroupTabSelect(e) {
        let currConfig = e.target.label;
        if(typeof this.filteredObjs[currConfig] === 'undefined') {
            getRecordsForFilter({configSetting: currConfig})
                .then(result => {
                    if(typeof result !== 'undefined') {
                        //this.filteredObjs[currConfig] = result;
                        this.setConfigSobjects(result, currConfig);
                    } else {
                        //this.filteredObjs[currConfig] = [];
                        this.setConfigSobjects([], currConfig);
                    }

                    // debugger;
                })
                .catch(error => {
                    console.log(error);
                    debugger;
                })
        }
    }

    setConfigSobjects(results, currConfig) {
        let modConfig = JSON.parse(JSON.stringify(this.allConfigs));
        if(typeof modConfig.data !== 'undefined') {
            for (let config of modConfig.data) {
                if(config.dataGroup == currConfig) {
                    debugger;
                    config.filteredObjs = results;
                }
            }
        }
        this.allConfigs = Object.assign({},modConfig);
    }
    handleSobjectSelect(e) {
        debugger;
        let dataGroup = e.target.parentElement.label;
        let oldArray = [];
        if(typeof this.selectedSObjects[dataGroup] === 'undefined') {
            this.selectedSObjects[dataGroup] = {};
        }
        if(typeof this.selectedSObjects[dataGroup].sobjects  !== 'undefined')
        {
            oldArray = this.selectedSObjects[dataGroup].sobjects.slice();
        }

        this.selectedSObjects[dataGroup].sobjects = e.detail.value;
        let difference = this.selectedSObjects[dataGroup].sobjects.filter(x => !oldArray.includes(x));
        let defVal = this.getDefaultGroupId(dataGroup);
        if(difference.length > 0) {
            //let defVal = this.getDefaultGroupId(dataGroup);
            if(!e.detail.value.includes(defVal)) {
                this.selectedSObjects[dataGroup].sobjects.push(defVal);
            }
        }
    }
    handleRecordFilterSelect(e) {
        debugger;
        let dataGroup = e.target.parentElement.label;
        let oldArray = [];
        if(typeof this.selectedSObjects[dataGroup] === 'undefined') {
            this.selectedSObjects[dataGroup] = {};
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


    showToast(title, message, variant) {
        let event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
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