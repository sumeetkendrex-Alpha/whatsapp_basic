({
    doInit: function (component, event, helper) {
        $A.util.addClass(component, 'custom-spinner');

        window.setTimeout(
            $A.getCallback(function () {
                helper.syncTemplate(component);
            }), 1000
        );
    }
});