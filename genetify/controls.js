//TODO: effect of javascript vary is not apparent unless switched objects are called
//TODO: view results
var genetify_controls_HTML = '\
    <div class="buttons">\
        Vary \
        <a href="#" class="positive" onclick="genetify.controls.reVary(\'all\'); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">all</a>\
        <a href="#" class="positive" onclick="genetify.controls.reVary(\'elements\'); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">HTML elements</a>\
        <a href="#" class="positive" onclick="genetify.controls.reVary(\'CSSRules\'); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">CSS rules</a>\
        <a href="#" class="positive" onclick="genetify.controls.reVary(\'additiveCSSRules\'); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">additive CSS rules</a>\
        <a href="#" class="positive" onclick="genetify.controls.reVary(\'javascript\'); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">javascript</a>\
    </div>\
    <div class="buttons">\
        Goals\
        <a href="#" class="positive" onclick="genetify.controls.goal(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/accept.png" alt="">Record goal</a>\
        <a href="#" class="negative" onclick="genetify.record.reset(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/delete.png" alt="">Reset results</a>\
        <a href="#" class="positive" onclick="genetify.controls.showResults(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">Show results</a>\
    </div>\
    <div class="buttons">\
        Cookie\
        <a href="#" class="positive" onclick="genetify.cookie.enable(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/accept.png" alt="">Enable</a>\
        <a href="#" class="negative" onclick="genetify.cookie.disable(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/delete.png" alt="">Disable</a>\
    </div>\
';
genetify.controls._insertHTML('genetify_controls', genetify_controls_HTML);