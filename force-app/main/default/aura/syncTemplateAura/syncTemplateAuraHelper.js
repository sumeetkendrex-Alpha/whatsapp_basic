({
    syncTemplate: function (component) {
        var action = component.get("c.syncTemplate");
        console.log('action==>',action);
        action.setParams({recordId: component.get("v.recordId")});
        action.setCallback(this, function (response) {
            component.set("v.isLoading", false);
            var state = response.getState();

            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var isError = result.toLowerCase().includes('error') || result.toLowerCase().includes('exception');
                
                this.showToast(isError ? 'Error' : 'Success',result,isError ? 'error' : 'success');

                // Close the action screen
                $A.get("e.force:closeQuickAction").fire();
  setTimeout(function () {
                    window.location.reload();
                }, 500);
            } else if (state === "ERROR") {
                var errors = response.getError();
                var message = (errors && errors[0] && errors[0].message) || "Unknown error occurred.";

                this.showToast("Error", message, "error");
                  setTimeout(function () {
                    window.location.reload();
                }, 500);
            }
        });

        $A.enqueueAction(action);
    },

    showToast: function (title, message, variant) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: title,
            message: message,
            type: variant
        });
        toastEvent.fire();
    }
});