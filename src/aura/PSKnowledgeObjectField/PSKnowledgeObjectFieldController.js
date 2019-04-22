({
	doInit : function(component, event, helper) {
		var obj = component.get('v.object');
		var fieldName = component.get('v.fieldName');

		component.set('v.fieldVal', obj[fieldName]);
	}
})