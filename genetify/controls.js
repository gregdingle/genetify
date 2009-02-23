genetify.test = {

    _currentGeneName: '',
    _currentVariantNames: [],
    delay: 300,

    results: function(geneName, variantNames){

        //TODO: multiple distribution tests of results
        // if (!probs){
        //     // default even prob
        //     for (var i=0; i < variantNames.length; i++){
        //         probs[i] = 1 / variantNames.length;
        //     }
        // }
        //
        // genetify.utils.assert(probs.length == variantNames.length)

        if (variantNames.indexOf('__original__') == -1){
            variantNames.push('__original__');
        }

        //TODO: safety checks so it won't delete data! ... change namespace?
        // in case page has already been varied
        genetify.controls.reset();
        genetify.genome = {};

        // record random subset of variants
        var leaveOut = genetify._getRandomVariant(variantNames);
        // var leaveOut = '';

        for (var i=0; i < variantNames.length; i++){

            // stagger requests for database performance
            var requestAfterDelay = function(variantName, delay){
                setTimeout(function(){
                    genetify.genome[geneName] = variantName;
                    genetify.pageview_xid = genetify._generateID();
                    genetify.record.pageview(genetify.genome, genetify.referrer);
                    genetify.record.goal('__test__', 1);
                }, delay);
            };

            if (variantNames[i] != leaveOut){
                requestAfterDelay(variantNames[i], i * genetify.test.delay);
            }
        }

        // //TODO: better way to pass info to callback?
        genetify.test._currentGeneName = geneName;
        genetify.test._currentVariantNames = variantNames;

        //to give time for database
        setTimeout(function(){
            genetify.requestResults('genetify.test.processResults', true);
        }, (i + 3) * genetify.test.delay);
    },

    processResults: function(JSON){
        genetify.handleResults(JSON);
        genetify.test._checkResults(genetify.test._currentGeneName, genetify.test._currentVariantNames);
        genetify.controls.reset();
    },

    _checkResults: function(geneName, variantNames){

        // to conform to function params
        var variants = [];
        for (var i=0; i < variantNames.length; i++){
            variants[i] = [variantNames[i], null];
        }
        // this will adjust missing results
        var probs = genetify._getProbabilities(genetify.results[geneName], variants);

        for (var k=0; k < variantNames.length; k++){
            if (genetify.results[geneName]){
                var expectedProb = 1 / variantNames.length;
                probs[k] = genetify.utils.round(probs[k]);
                genetify.utils.assert(
                    expectedProb == probs[k],
                    'Expected probability ' + expectedProb + ', got ' + probs[k]
                );
                console.log(variantNames[k] + ', p=' + probs[k]);
            }
        }

        var sum = genetify.utils.round(genetify.utils.sum(probs));
        genetify.utils.assert(sum == 1, 'Weights add up to ' + sum + ' for ' + geneName);
        console.log('PASSED: Probabilities match expected');
    },

    variants: function(geneName, variantNames, geneType /*optional*/){
        //TODO: safety checks so it won't delete data! ... change namespace?

        if (variantNames.indexOf('__original__') == -1){
            variantNames.push('__original__');
        }

        console.log('Checking expression of variants', variantNames, 'in gene', geneName);

        genetify.genomeOverride = {};

        var checked = [];
        var iterations_per_variant = 6; //to make sure all are seen
        for (var i=0; i < variantNames.length * iterations_per_variant; i++){
            // stagger requests for database performance
            setTimeout(function (){
                genetify.controls.reVary(geneType || 'all');
                for (var k=0; k < variantNames.length; k++){
                    if (genetify.genome[geneName] == variantNames[k]){
                        checked[k] = 1;
                    }
                }
            }, i * genetify.test.delay);
        }

        setTimeout(function(){
            genetify.controls.reset();
            genetify.utils.assert(
                genetify.utils.sum(checked) == variantNames.length,
                'Not all variants were present in genome'
            );
            console.log('PASSED: All variants expressed');
        }, i * genetify.test.delay);
    }

};

genetify.controls = {

    _timer: false,

    reVary: function(geneType){
        genetify.genome = {};
        genetify.vary(geneType);
        // console.log(genetify.genome, genetifyTime.time.vary + 'ms');
        //TODO: this does nothing until server updates vary counts
        // genetify.controls._refreshResults();
    },


    remove: function(){
        var elem = document.getElementById('genetify_controls');
        if (elem){
            elem.parentNode.removeChild(elem);
        }
    },

    _insertHTML: function(id, HTML){
        var elem = document.getElementById(id);
        if (!elem){
            elem = document.createElement('div');
            elem.id = id;
            document.getElementsByTagName('body')[0].appendChild(elem);
        }
        elem.innerHTML = HTML;
    },

    _refreshResults: function(){
        if (genetify.controls._timer){
            clearTimeout(genetify.controls._timer);
            genetify.controls._timer = false;
        }

        genetify.controls._timer = setTimeout(function(){
                genetify.requestResults('genetify.handleResults', true);
            },
            genetify.test.delay
        );
    },

    goal: function(value){
        //TODO: user input of goal value

        if (!value){
            // value = Math.round(Math.random()*99) + 1;
            value = 1;
        }

        genetify.record.goal('genetify.controls.goal', value);
        genetify.controls._refreshResults();
    },

    reset: function(){
        var queryDict = {
            //TODO: change name to reset?
            'delete': true
        };
        genetify.utils.request(genetify.utils.buildURL('/delete.php', queryDict));
        genetify.controls._refreshResults();
    },

    //TODO: do something so genome passed in cookie is also shown
    //TODO: better handling of unused and missing results
    resultsToTable: function(){
        //TODO: make column headers dynamic
        //TODO: fix with new results
        var headers = ['count', 'sum', 'avg', 'weight', 'recorded'];
        var rows = [['name'].concat(headers)];

        if (!genetify.config.REQUEST_RESULTS){
            //TODO: get results anyway
            console.log('Results not requested');
        }
        else if (genetify.utils.empty(genetify.results)){
            console.warn('No results found');
        }
        else {
            //TODO: use current genes on page??
            for (var p in genetify.results){

                rows.push([p]);
                var gene = genetify.results[p];

                for (var variantName in gene){
                    var row = [variantName];
                    for (var col in headers){
                        var value = gene[variantName][headers[col]];
                        if (typeof(value) == 'number'){
                            value = genetify.utils.round(value);
                        }
                        row.push(value);

                    }
                    rows.push(row);
                }

            }
        }
        return rows;
    },

    showResults: function(){
        var rows = genetify.controls.resultsToTable();

        var HTML = '<table id="genetify_results_table">';
        for (var i=0; i < rows.length; i++){

            var rowTag = 'tr';
            HTML += '<' + rowTag + '>';

            cols = rows[i];

            for (var j=0; j < cols.length; j++){

                var extra = ' class="genetify_col_' + rows[0][j] + '"';

                if (genetify.results[cols[j]] && rows[i+1]){
                    var geneName = cols[j];

                    extra = ' colspan="' + rows[i+1].length + '"';
                    extra += ' class="genetify_gene_row"';

                    // stats confidence
                    var confidence = genetify.weight.sums[geneName] ? genetify.weight.sums[geneName].confidence: '';
                    if (confidence){
                        var stars = '';
                        if (confidence > 0.9){
                            stars += '*';
                        }
                        if (confidence > 0.95){
                            stars += '*';
                        }
                        if (confidence > 0.99){
                            stars += '*';
                        }
                        extra += ' title="The ' + geneName + ' variants are different at a confidence of ' + genetify.utils.round(confidence) + '"';
                        cols[j] = cols[j] + ' ' + stars;
                    }

                }
                else if (j === 0){
                    extra += ' onclick="location=\'#' + encodeURIComponent(geneName) + '=' + cols[j] + '\'; genetify.controls.reVary(\'all\')"';
                }
                else {
                    extra += ' title="The ' + rows[0][j] + ' of variant ' + cols[0] + ' is ' + cols[j] + '"';
                }

                var colTag = '';
                if (i === 0){
                    colTag = 'th';
                }
                else {
                    colTag = 'td';
                }

                HTML += '<' + colTag + extra + '>' + cols[j] + '</' + colTag + '>';
            }

            HTML += '</' + rowTag + '>';
        }
        HTML += '</table>';

        genetify.controls._insertHTML('genetify_results', HTML);
    }

};


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
        <a href="#" class="negative" onclick="genetify.controls.reset(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/delete.png" alt="">Reset results</a>\
        <a href="#" class="positive" onclick="genetify.controls.showResults(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/lightning.png" alt="">Show results</a>\
    </div>\
    <div class="buttons">\
        Cookie\
        <a href="#" class="positive" onclick="genetify.cookie.enable(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/accept.png" alt="">Enable</a>\
        <a href="#" class="negative" onclick="genetify.cookie.disable(); return false;"><img src="' + genetify.config.REMOTE_BASE_URL + '/images/delete.png" alt="">Disable</a>\
    </div>\
';
