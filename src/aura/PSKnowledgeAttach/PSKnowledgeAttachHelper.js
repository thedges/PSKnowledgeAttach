({
    loadRecord : function(component) {
        var self = this;
        var recid = component.get("v.recordId");
        var autoSearch = component.get("v.autoSearch");
        var searchField = component.get("v.searchField");
        var extraFields = component.get("v.extraFields");
        console.log("loadRecord id: " + recid);
        
        component.set('v.searchResults', null);
        
        var action = component.get("c.queryRecord");
        
        var paramMap = {};
        paramMap['recId'] = recid;

        if (autoSearch && searchField)
        {
            paramMap['searchField'] = searchField;
        }

        if (extraFields)
        {
            paramMap['extraFields'] = extraFields;
        }
        
        action.setParams({
            "params": JSON.stringify(paramMap)
        });
        
        
        action.setCallback(component,  $A.getCallback(function(response) {
            console.log('resp=' + response.getReturnValue());
            if (response.getState() === 'SUCCESS') 
            {
                var resp = JSON.parse(response.getReturnValue());
                component.set('v.objectName', resp['objectName']);

                if (autoSearch)
                {
                   var queryStr = component.get('v.queryStr');
                   component.set('v.queryStr', resp['searchField']);
                   self.executeQuery(component);
                }

                if (extraFields)
                {
                    var fields = JSON.parse(resp['extraFields']);
                    component.set('v.extraFieldsDefs', fields);

                    var fieldNames = [];
                    fields.forEach(function(fld){
                      fieldNames.push(fld.name);
                    });
                    component.set('v.extraFieldsNames', fieldNames);
                }
            }
            else
            {
                self.handleErrors(component, response.getError()); 
            }
        }));
        $A.enqueueAction(action);
    },
    executeQuery : function(component) {
        var self = this;
        
        self.showSpinner(component);
        
        component.set('v.searchResults', null);
        
        var queryStr = component.get("v.queryStr");
        var extraFields = component.get("v.extraFields");
        var action = component.get("c.queryData");
        
        var paramMap = {};
        paramMap['query'] = queryStr;
        paramMap['recordId'] = component.get('v.recordId');
        paramMap['maxResults'] = component.get('v.maxResults');
        if (extraFields) paramMap['extraFields'] = extraFields;
        
        action.setParams({
            "params": JSON.stringify(paramMap)
        });
        
        action.setCallback(component, function(response) {
            console.log('resp=' + response.getReturnValue());
            if (response.getState() === 'SUCCESS') 
            {
                var resp = JSON.parse(response.getReturnValue());
                self.hideSpinner(component);
                component.set('v.searchResults', resp);
            }
            else
            {
                self.handleErrors(component, response.getError()); 
            }
        });
        $A.enqueueAction(action);
    },
    attachDocument : function(component, docId) {
        var self = this;
        var kaId = null;
        var verId = null;
        var title = null;

        var results = component.get("v.searchResults");
        for (var i=0; i<results.length; i++)
        {
            if (results[i].Id === docId)
            {
               kaId = results[i].KnowledgeArticleId;
               verId = results[i].MasterVersionId;
               title = results[i].Title;
            }
        }
        
        var action = component.get("c.attachDocToRecord");
        
        var paramMap = {};
        paramMap['recId'] = component.get("v.recordId");
        paramMap['docId'] = kaId;
        paramMap['verId'] = verId;
        paramMap['title'] = title;
        
        action.setParams({
            "params": JSON.stringify(paramMap)
        });
        
        
        action.setCallback(component, $A.getCallback(function(response) {
            console.log('resp=' + response.getReturnValue());
            if (response.getState() === 'SUCCESS') 
            {
                for (var i=0; i<results.length; i++)
                {
                    if (results[i].Id === docId)
                    {
                        results[i].Attached = true;
                    }
                }
                component.set("v.searchResults", results);


                $A.get('e.force:refreshView').fire();
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Document Attached!",
                    "message": "Document has been attached to " + component.get("v.objectName"),
                    "mode": "dismissible",
                    "duration" : 1000,
                    "type": "success"
                });
                toastEvent.fire();
            }
            else
            {
                self.handleErrors(component, response.getError()); 
            }
        }));
        $A.enqueueAction(action);
    },
    showSpinner:function(component){
        component.set("v.IsSpinner",true);
    },
    hideSpinner:function(component){
        component.set("v.IsSpinner",false);
    },
    handleErrors: function (component, errors) {
        var self = this;
        self.hideSpinner(component);

        let toastParams = {
			title: "Error!",
			message: "Unknown error", // Default error message
			type: "error",
			mode: "sticky"
		};
		// Pass the error message if any
		if (errors && Array.isArray(errors) && errors.length > 0) {
			toastParams.message = errors[0].message;
		}
		else
		{
			toastParams.message = errors;
		}
		// Fire error toast
		let toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams(toastParams);
		toastEvent.fire();
    }
})