        var mutateCSS = function(){
    		genetify._forAllCSSRules(function(cssRule){
                var pairs = cssRule.style.cssText.split(';');     
                for (var i=0; i < pairs.length; i++){   
                    if (pairs[i]){
                        var parts = pairs[i].split(':');
                        var property = parts[0];
                        var value = parts.slice(1).join(':');  

                        if (property.indexOf('display') != -1){
                            // ignore display CSS
                            continue;
                        }

                        var cssPossibleValues = genetify.css.getCSSKeywordsByProperty(property);
                        //TODO: get ranges as well

                        //TODO: really need key-value structure?
                        // var variants = [];
                        // for (var i=0; i < cssPossibleValues.length; i++){
                        //     variants.push([cssPossibleValues[i], cssPossibleValues[i]]);
                        // }
                        //     
                        // var geneName = cssRule.selectorText + '->' + property;
                        // //TODO: set selected in genetify.genome
                        // var selectedVariant = genetify._selectVariant(geneName, value, variants);
                        // console.log(selectedVariant);

                        if (!genetify.utils.empty(cssPossibleValues)){
                            var selectedVariant = genetify._getRandomVariant(cssPossibleValues);
                            pairs[i] = property + ': ' + selectedVariant;
                        }
                    }
                }
                cssRule.style.cssText = pairs.join(';');
            });
        };
