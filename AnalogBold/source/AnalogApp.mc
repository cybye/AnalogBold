
using Toybox.Application as App;

class AnalogWatch extends App.AppBase
{
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
    }

    function onStop(state) {
    }

    function getInitialView() {
        var view = new AnalogView();
        
       	view.setApp(self); 
        
         if( Toybox.WatchUi has :WatchFaceDelegate ) {
            return [view, new AnalogDelegate()];
        } else {
            return [view];
        }
    }

   /*
    function getGoalView(goal){
        return [new AnalogGoalView(goal)];
    }
    */
}
 