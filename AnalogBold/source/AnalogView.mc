
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;
using Toybox.Position as Position;
using Toybox.Activity as ActI;

// This implements an analog watch face
// Original design by Austen Harbour
class AnalogView extends Ui.WatchFace
{
    var isAwake = true;
    var screenShape;
    var sc;
    var sunrise_moment;
    var sunset_moment;
    var app;
    var bitmap;
    
    var width;
    var height;
    var centerX;
    var centerY;
    
    var circles;
    var hand;
    var hand2;
    var hand3;
    var hand4;
    
    var offscreenBuffer;
    var curClip;
    var partialUpdatesAllowed;
    
    var cachedSeconds;// = new [60*7];
    

    function initialize() {
        WatchFace.initialize();
        screenShape = Sys.getDeviceSettings().screenShape;
       partialUpdatesAllowed = ( Toybox.WatchUi.WatchFace has :onPartialUpdate );
        // sun dates      
        sc = new SunCalc();
    }
    
    function setApp(app1) {  
    	app = app1;
    }

    function onLayout(dc) {
         bitmap = Ui.loadResource(Rez.Drawables.id_cy);
         
         width = dc.getWidth();
       	 height = dc.getHeight();
         
         centerX = width / 2;
         centerY = height / 2;
         
         if (Sys.SCREEN_SHAPE_ROUND == screenShape) {
         	circles = compCircles(dc);
         }
         
         var _length;
         var _width;
         
         // hour hand
         // length
         // drawHand(dc, hourHand, w2-34, 12);
         _length = centerX-34;
         _width = 12;
         hand =  [[-(_width / 2),-10], [-(_width / 2), -_length], [_width / 2, -_length], [_width / 2, -10]];
         // minute hand
         // drawHand2(dc, minuteHand, w2 -20, 10);
         _length= centerX -20;
         _width = 10;
         hand2 = [[-(_width / 2),-10], [-(_width / 2), -_length], [0, -_length - 10], [_width / 2, -_length], [_width / 2, -10]];
         // seconds hand
         //  drawHand3(dc, secondHand, w2 -20, 5);
         _length= centerX -20;
         _width= 5;
         hand3 = [[-(_width / 2),-10], [-(_width / 2), -_length], [0, -_length - 10], [_width / 2, -_length], [_width / 2, -10]];
         // others
         // drawHand4(dc, sun, w2 , 20, color);
         _length= centerX;
         _width= 20;
         hand4 = [[-(_width / 2),-_length],[_width / 2, -_length],  [0, -_length+10]];
         
         
         cachedSeconds = cacheSeconds();
         
         // offscreen
         // If this device supports BufferedBitmap, allocate the buffers we use for drawing
        if(Toybox.Graphics has :BufferedBitmap) {
            // Allocate a full screen size buffer to draw
            // the background image of the watchface.  This is used to facilitate blanking
            // the second hand during partial updates of the display
            offscreenBuffer = new Graphics.BufferedBitmap({
                :width=>width,
                :height=>height
                });
           
        } else {
            offscreenBuffer = null;
        }
        
        curClip = null;
         
    }
    
    
    function drawPolygon(dc, poly) {
		var s = poly.size()-1;
		for(var i=0;i<s; i+=1) {
		   dc.drawLine(poly[i][0], poly[i][1], poly[i+1][0], poly[i+1][1]);
		} 
		dc.drawLine(poly[s][0], poly[s][1], poly[0][0], poly[0][1]);		
	}
	
	
    
    function drawPolyAngle(dc, poly, angle, colorA, colorB) {
    	var cos = Math.cos(angle);
        var sin = Math.sin(angle);
    	var result = new [poly.size()];
    	for(var i = 0; i< result.size(); i += 1) {
    		var x = (poly[i][0] * cos) - (poly[i][1] * sin);
            var y = (poly[i][0] * sin) + (poly[i][1] * cos);
            result[i] = [centerX + x, centerY + y];
    	}
    	
    	 // Draw the polygon
        dc.setColor(colorA, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(result);
        dc.setColor(colorB, Gfx.COLOR_TRANSPARENT);
        drawPolygon(dc, result);
    	 
    } 


    // Draw the watch hand
    // @param dc Device Context to Draw
    // @param angle Angle to draw the watch hand
    // @param length Length of the watch hand
    // @param width Width of the watch hand
    function drawHand(dc, angle) {
        drawPolyAngle(dc,hand, angle, Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY);
    }


	

    // Draw the watch hand
    // @param dc Device Context to Draw
    // @param angle Angle to draw the watch hand
    // @param length Length of the watch hand
    // @param width Width of the watch hand
    function drawHand2(dc, angle) {
        drawPolyAngle(dc, hand2, angle, Gfx.COLOR_WHITE, Gfx.COLOR_DK_GRAY);
    }
    
     // Draw the watch hand
    // @param dc Device Context to Draw
    // @param angle Angle to draw the watch hand
    // @param length Length of the watch hand
    // @param width Width of the watch hand
    function drawHand3(dc, poly) {
        // Map out the coordinates of the watch hand
        // var coords = hand3;
        /*
        var result = new[5];
        
        for(var i = 0; i<5; i += 1 ) {
        	result[i] = poly[i];
        }
        */
        var result = [ poly[0], poly[1], poly[2], poly[3], poly[4] ];
        
        //var cos = Math.cos(angle);
        //var sin = Math.sin(angle);

        // Transform the coordinates
        //for (var i = 0; i < 5; i += 1) {
        //    var x = (coords[i][0] * cos) - (coords[i][1] * sin);
        //    var y = (coords[i][0] * sin) + (coords[i][1] * cos);
        //    result[i] = [centerX + x, centerY + y];
        //}

        // Draw the polygon
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
        dc.fillPolygon(result);
        dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        drawPolygon(dc, result);
        
    
        // the nice ring
       
        //var x0 = 0;
        //var y0 = -length+15;
        //var x = centerX + x0*cos - y0*sin;
        //var y = centerY + x0*sin + y0*cos;
        
        var x = poly[5];
        var y = poly[6];
        
        
        
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, 7);
        dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
                
        dc.setPenWidth(2);
        dc.drawCircle(x, y, 7);
        dc.setPenWidth(1);
        
        
    }
    
     // Draw the watch hand
    // @param dc Device Context to Draw
    // @param angle Angle to draw the watch hand
    // @param length Length of the watch hand
    // @param width Width of the watch hand
    function drawHand4(dc, angle,color) {
        drawPolyAngle(dc, hand4, angle, color[0], color[1]);
    }



		// Draw the circle symbols on the watch
    // @param dc Device context
    function compCircles(dc) {
	
			var r = new [8];
            var sX, sY;
            var eX, eY;
            var outerRad = centerX;
            var innerRad = outerRad - 10;
            var p6 = Math.PI / 6;
            var p3 = p6 * 2;
            var j = 0;
            // Loop through each 15 minute block and draw tick marks
            for (var i = p6; i <= 11 * p6; i += p3) {
                // Partially unrolled loop to draw two tickmarks in 15 minute block
                var sin = Math.sin(i);
                var cos = Math.cos(i);
                sY = outerRad + innerRad * sin;
                eY = outerRad + outerRad * sin;
                sX = outerRad + innerRad * cos;
                eX = outerRad + outerRad * cos;
                
                r[j] = [sX,sY];
                
                j += 1;                
                i += p6;
                
                sin = Math.sin(i);
                cos = Math.cos(i);
                sY = outerRad + innerRad * sin;
                eY = outerRad + outerRad * sin;
                sX = outerRad + innerRad * cos;
                eX = outerRad + outerRad * cos;
                
                r[j] = [sX,sY];
                j += 1;
            }
            return r;
    }


 	// Draw the circle symbols on the watch
    // @param dc Device context
    function drawCircles(dc) {

        // Draw hashmarks differently depending on screen geometry
        if (Sys.SCREEN_SHAPE_ROUND == screenShape) {
        
        	for(var i = 0; i< circles.size(); i += 1) {
        		dc.fillCircle(circles[i][0], circles[i][1], 8);
        	}
        
            
        } else {
 	        var width = dc.getWidth();
	        var height = dc.getHeight();
            var coords = [0, width / 4, (3 * width) / 4, width];
            for (var i = 0; i < coords.size(); i += 1) {
                var dx = ((width / 2.0) - coords[i]) / (height / 2.0);
                var upperX = coords[i] + (dx * 10);
                // Draw the upper hash marks
                dc.fillPolygon([[coords[i] - 1, 2], [upperX - 1, 12], [upperX + 1, 12], [coords[i] + 1, 2]]);
                // Draw the lower hash marks
                dc.fillPolygon([[coords[i] - 1, height-2], [upperX - 1, height - 12], [upperX + 1, height - 12], [coords[i] + 1, height - 2]]);
            }
        }
    }

   

    // Handle the update event
    function onUpdate(dc) {
        var screenWidth = dc.getWidth();
        var clockTime = Sys.getClockTime();
        var hourHand;
        var minuteHand;
        var secondHand;
        var w2 = centerX;
        var h2 = centerY;
        var tdc = null;

        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
 
        var dateStr = Lang.format("$1$", [info.day]);
        
        var settings = Sys.getDeviceSettings();
        var batt = Sys.getSystemStats().battery;
        var battStr = batt.format("%i");
        
        
        
        if(null != offscreenBuffer) {
            dc.clearClip();
            curClip = null;
            // If we have an offscreen buffer that we are using to draw the background,
            // set the draw context of that buffer as our target.
            tdc = offscreenBuffer.getDc();
        } else {
            tdc = dc;
        }
        
        
        

        // Clear the screen
        tdc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        tdc.fillRectangle(0, 0, width, height);

		// the logo 		
        tdc.drawBitmap(width/2 - bitmap.getWidth()/2, 35 , bitmap);
        

        // Draw the numbers
        
        tdc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        
        //12
        // phone connected
        tdc.fillRectangle(w2 - 12, 2, 10, 30);
        
        if(settings has :phoneConnected && !settings.phoneConnected) {
        	tdc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
        }
        
        tdc.fillRectangle(w2 + 2, 2, 10, 30);
              
        //3
        // DND & notifications
        if(settings has :doNotDisturb && settings.doNotDisturb) {
        	tdc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
        	 tdc.fillRectangle(width-30, h2 - 5, 30, 10);
        } else {
        	tdc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	        tdc.fillRectangle(width-30, h2 - 5, 30, 10);
	        
	        if(settings has :notificationCount) {
		        var notificationCount = settings.notificationCount;
		        if(notificationCount > 0) {
		        	if(isAwake || notificationCount < 2) {
		        		tdc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
		        	} else {
		        		tdc.setColor(0x80ff80, Gfx.COLOR_TRANSPARENT);
		        	}
		        	var n = notificationCount * 5;
		        	if(n>30) {
		        	  n= 30;
		        	}
		        
		        	tdc.fillRectangle(width-n, h2 - 5, n, 10);
		        }
	        }
        }
        
        //6 
        // Any ALARMS?
    	tdc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        tdc.fillRectangle(w2 - 5, height - 30, 10, 30);
        
        if(settings has :alarmCount) {
	        var alarmCount = settings.alarmCount;
	        if(alarmCount>0) {
	        	if(isAwake) {
	        		tdc.setColor(0x7070ff, Gfx.COLOR_TRANSPARENT);
	        	} else {
	        		tdc.setColor(0x8080ff, Gfx.COLOR_TRANSPARENT);
	        	}
	        	var n = alarmCount * 10;
	        	if(n>30) {
	        	  n= 30;
	        	}
	        	tdc.fillRectangle(w2 - 5, height-n, 10, n);       	
        }
        }
        
        
        
        //9 
        // battery
        if(batt < 11) {
       	 tdc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
       	} else if(batt < 31) {
       	  tdc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_TRANSPARENT);
       	} else if(batt < 51) {
       	  tdc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
       	} else {
       	  tdc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
       	}
        tdc.fillRectangle(2, h2 - 5, 30, 10);
        
        tdc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        if( batt < 31 ) {
        	tdc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        }
        var l = 30*batt/100;
        tdc.fillRectangle(2+l, h2 - 5, 30-l+1, 10);
        
   	
        // Draw the date
        tdc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        
        tdc.drawText(width-34, h2-18, Gfx.FONT_SYSTEM_MEDIUM,  dateStr , Gfx.TEXT_JUSTIFY_RIGHT);

		if(isAwake) {
			tdc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
	        tdc.drawText(34, h2-14, Gfx.FONT_SYSTEM_XTINY,  battStr + "%" , Gfx.TEXT_JUSTIFY_LEFT);
        
        	// UTC TIME display
        	var utc = Calendar.utcInfo(now, Time.FORMAT_SHORT);
        	var utcStr = utc.hour.format("%02i") + ":" + utc.min.format("%02i");
        	tdc.drawText(w2, 3*height/4, Gfx.FONT_SYSTEM_XTINY,  utcStr, Gfx.TEXT_JUSTIFY_CENTER);
        }
        
        
        // sun and so
        
        /*
         * activity info will be available during and after an activity.
         * sync it with the AppBase.setProperty if so
         */
                
        
        var loc = ActI.getActivityInfo().currentLocation;
        
        if(app != null) { // hope it's not ;)
	        if(loc != null) {
	           var l = loc.toRadians();
	           app.setProperty("location",[l[0],l[1]]);
	        }
	        loc = app.getProperty("location");
        }
        
        
        var latlon;
        var color = [Gfx.COLOR_YELLOW, Gfx.COLOR_DK_BLUE];
        
        if(loc == null) {
        	latlon = [Math.toRadians(49.3d),Math.toRadians(6.7d)]; 
        	color[1] = Gfx.COLOR_ORANGE;
        } else {
        	latlon = loc;
		}
		
        sunrise_moment = sc.calculate(now, latlon, SUNRISE);
    	sunset_moment  = sc.calculate(now, latlon, SUNSET);
 		
 		var sunt;
 		if(sunrise_moment.lessThan(now) && sunset_moment.greaterThan(now)) {
 			sunt = Time.Gregorian.info(sunset_moment, Time.FORMAT_SHORT);
 			color[0] = Gfx.COLOR_BLUE;
 		} else {
 			sunt = Time.Gregorian.info(sunrise_moment, Time.FORMAT_SHORT);
 		}
 		
 		var sun = (((sunt.hour % 12) * 60) + sunt.min);
        sun = sun / (12 * 60.0);
        sun = sun * Math.PI * 2;
        drawHand4(tdc, sun, color);
 		
 		if(isAwake) {
	 		tdc.setColor(color[0], Gfx.COLOR_TRANSPARENT);
	 		var sunStr = sunt.hour.format("%02i") + ":" + sunt.min.format("%02i");
	        tdc.drawText(w2, 3*height/4-20, Gfx.FONT_SYSTEM_XTINY,  sunStr, Gfx.TEXT_JUSTIFY_CENTER);
 		}
        
        
        
        // Draw the hash marks
        tdc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
	    drawCircles(tdc);

        // Draw the hour. Convert it to minutes and compute the angle.
        hourHand = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHand = hourHand / (12 * 60.0);
        hourHand = hourHand * Math.PI * 2;
        drawHand(tdc, hourHand);

        // Draw the minute
        minuteHand = (clockTime.min / 60.0) * Math.PI * 2;
        drawHand2(tdc, minuteHand);

		/*
 		// Draw the arbor       
        tdc.setColor(0x303030, Gfx.COLOR_BLACK);
        // tdc.drawCircle(w2, h2, 10);
        tdc.fillCircle(w2, h2,  9);

        tdc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        // tdc.drawCircle(w2, h2, 10);
        tdc.fillCircle(w2, h2,  2);
 		*/
 		
 		drawBackground(dc);
 		
 		
 		 // Draw the second
        if (isAwake || partialUpdatesAllowed) {
            drawSeconds(dc, clockTime);
        }

        
 		
        
    }
    
    // Draw the watch face background
    // onUpdate uses this method to transfer newly rendered Buffered Bitmaps
    // to the main display.
    // onPartialUpdate uses this to blank the second hand from the previous
    // second before outputing the new one.
    function drawBackground(dc) {
        //If we have an offscreen buffer that has been written to
        //draw it to the screen.
        if( null != offscreenBuffer ) {
            dc.drawBitmap(0, 0, offscreenBuffer);
        }
    }
    
    
    
    function drawSeconds(dc, clockTime) {
     var w2 = centerX;
     dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    
     // var secondHand = (clockTime.sec / 60.0) * Math.PI * 2;
          
     var rotated = rotateSecondsCached(clockTime.sec);
          
     curClip = adjustArea(getBoundingBox(rotated,5));
     var bboxWidth = curClip[1][0] - curClip[0][0] + 1;
     var bboxHeight = curClip[1][1] - curClip[0][1] + 1;
     
     
     if(dc has :setClip) {
     	dc.setClip(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);
     }
     
    // dc.drawRectangle(curClip[0][0], curClip[0][1], bboxWidth, bboxHeight);
  //   System.println(curClip[0][0] + " " + curClip[0][1] + " " + bboxWidth + " " + bboxHeight);
	      
	      
     drawHand3(dc, rotated);     
    }
    
    
    function onPartialUpdate(dc) {
     // isAwake = true;
        drawBackground(dc);
     	drawSeconds(dc,Sys.getClockTime());
    }
    
    
      function _cacheSeconds() {
  
    	var r = new [60];
    	
    	for(var i = 0; i< r.size(); i += 1) {
    	   r[i] = rotateSeconds( (i / 60.0) * Math.PI * 2 );
    	}
    	
    	return r;
    	
    }
    
     function cacheSeconds()  {
     	var coords = hand3;
      	var result = new [60*12];
	    var x0 = 0;
        var y0 = -(centerX-20)+15;
        

        // Transform the coordinates
        for(var j = 0; j<60; j += 1) {
        
         var angle =  (j / 60.0) * Math.PI * 2 ;
         var cos = Math.cos(angle);
         var sin = Math.sin(angle);
        
         for (var i = 0; i < 5; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[j*12 + i*2] = centerX + x; 
            result[j*12 + i*2 + 1] =centerY + y;
         }
        
         result[j*12 + 10] = centerX + x0*cos - y0*sin;
         result[j*12 + 11] = centerY + x0*sin + y0*cos;
        
        }
    	return result;
    }
    
    
    function rotateSecondsCached(secs)  {
        var s = secs*12;
        
        /*
      	var result = new [7];

        // Transform the coordinates
        for (var i = 0; i < 5; i += 1) {
        	result[i] = [ cachedSeconds[s  + i*2],  cachedSeconds[s  + i*2 +1] ];
        }
        result[5] = cachedSeconds[s  + 10];
        result[6] = cachedSeconds[s  + 11];
        return result;
        
        */
        return [[ cachedSeconds[s  + 0*2],  cachedSeconds[s  + 0*2 +1] ],
        [ cachedSeconds[s  + 1*2],  cachedSeconds[s  + 1*2 +1] ],
        [ cachedSeconds[s  + 2*2],  cachedSeconds[s  + 2*2 +1] ],
        [ cachedSeconds[s  + 3*2],  cachedSeconds[s  + 3*2 +1] ],
        [ cachedSeconds[s  + 4*2],  cachedSeconds[s  + 4*2 +1] ],
        cachedSeconds[s  + 10],
        cachedSeconds[s  + 11] ];
        
       
    }
    
    function rotateSeconds(angle)  {
     	var coords = hand3;
      	var result = new [7];
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 5; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [centerX + x, centerY + y];
        }
        
        var x0 = 0;
        var y0 = -(centerX-20)+15;
        result[5] = centerX + x0*cos - y0*sin;
        result[6] = centerY + x0*sin + y0*cos;
        
    	return result;
    }
    
   
    
    
    function adjustArea(box) {
    	if(box[1][0] - box[0][0] < 24) {
    		box[0][0] = box[0][0] - 12;
    		box[1][0] = box[1][0] + 12;
    	} 
    	if(box[1][1] - box[0][1] < 24) {
    		box[0][1] = box[0][1] - 12;
    		box[1][1] = box[1][1] + 12;
    	} 
    	return box;
    }
    
    // Compute a bounding box from the passed in points
    function getBoundingBox( points, size ) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < size; ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }
    
    

    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    function onExitSleep() {
        isAwake = true;
    }
}

class AnalogDelegate extends Ui.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
    }
}

