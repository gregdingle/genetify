// Encapsulates the data for a Google Analytics transaction 
// and provides methods for serializing and committing 

var UrchinTransaction = function(kwargs){
    //constructor that takes either dict or list that maps to this.params 
    this.requestID = this._getUrchinRand();    
    if (!kwargs['items'] && !kwargs[this.params.length-1]) return;
    for (var i=0; i < this.params.length; i++){
        this[this.params[i]] = kwargs[this.params[i]] || kwargs[i];
    }
    var citems = kwargs['items'] || kwargs[kwargs.length-1];
    this.items = [];
    for (var j=0; j < citems.length; j++){
        this.items[j] = new _UrchinItem(citems[j], this);
    }
};
UrchinTransaction.prototype = {
    testData: {
        'order-id': 34535,
        'affiliation': 'Main Store',
        'total': 111108.06,
        'tax': 8467.06,
        'shipping': 10.00,
        'city': 'San Diego',
        'state/region': 'CA',
        'country': 'USA',
        'items': [{
            'sku/code': 'XF-1024',
            'product name': 'Urchin T-Shirt',
            'category': 'Shirts',
            'price': 11399.00,
            'quantity': 9
        },
        {
            'sku/code': 'CU-3424',
            'product name': 'Urchin Drink Holder',
            'category': 'Accessories',
            'price': 20.00,
            'quantity': 2
        }]
    },
    test: function(){
        t = new UrchinTransaction(this.testData);
        return t.toString() == 'UTM:T|34535|Main Store|111108.06|8467.06|10|San Diego|CA|USA|UTM:I|34535|XF-1024|Urchin T-Shirt|Shirts|11399|9|UTM:I|34535|CU-3424|Urchin Drink Holder|Accessories|20|2';
    },
    //TODO: test for what is required by google
    params: [
        'order-id',
        'affiliation',
        'total',
        'tax',
        'shipping',
        'city',
        'state/region',
        'country',
        'items' //items must be last
    ],
    paramQueryNames: [
        'utmtid',
        'utmtst',
        'utmtto',
        'utmttx',
        'utmtsp',
        'utmtci',
        'utmtrg',
        'utmtco'
    ],
    requestID: 0,
    committed: false,
    
    commit: function(){
        this.commitUsingHack();
    },
    toString: function(){
        var l = ['UTM:T'];
        for (var i=0; i < this.params.length-1; i++){
            l[l.length] = this[this.params[i]];
        }
        for (var j=0; j < this.items.length; j++){
            l[l.length] = this.items[j].toString();
        }
        return l.join('|');
    },
    _addToDOM: function(){
        if (document.getElementById('utmtrans')) return;
        var urchinTextarea = document.createElement('textarea');
        urchinTextarea.style.display = 'none';
        urchinTextarea.id = 'utmtrans';
        document.body.appendChild(urchinTextarea);
    },
    commitUsingAPI: function(){
        if (this.committed) return;        
        this._addToDOM();
        document.getElementById('utmtrans').value = this.toString();
        __utmSetTrans();
        this.committed = true;
    },
    _getUrchinRand: function(){
        return Math.round(Math.random()*2147483647);        
    },
    toURL: function(){
        s = "&utmt=tran"+"&utmn=" + this.requestID;
        for (var i=0; i < this.params.length-1; i++){
            if (this[this.params[i]]){
                s += '&' + this.paramQueryNames[i] + '=' + _uES(this[this.params[i]]);
            }
        }
        return _ugifpath2+"?"+"utmwv="+_uwv+s+"&utmac="+_uacct+"&utmcc="+_uGCS();
    },
    commitUsingHack: function(){
        if (this.committed) return;
        var l = [this.toURL()];
        for (var j=0; j < this.items.length; j++){
            l[l.length] = this.items[j].toURL();
        }
        var im = [];
        for (var i=0; i < l.length; i++){
            im[i] = new Image(1,1);
            im[i].src = l[i];
            //TODO: return request status?
            im[i].onload = function() { _uVoid(); };
        }
        this.committed = true;
    },
    recordToDatabase: function(){
        var r = '/recorder.php';
        r += '?domain_id=' + _uDomain();
        r += '&visitor_id=' + __utmVisitorCode(1);
        r += '&click_id=' + this.requestID;
        r += '&raw_request=' + _uES(this.toURL());
        
        //TODO: debug mode only
        var browserInfo = [navigator.appName, navigator.appVersion, navigator.cookieEnabled, navigator.userAgent];
        r += '&browser_info=' + _uES(browserInfo.join('|'));
        
        //TODO: remove mochikit dependency
        doSimpleXMLHttpRequest(r);

        //TODO: im request doesn't work async onunload
        // var im = new Image(1,1);
        // im.src = r;
        // //TODO: return request status?
        // im.onload = function() { console.log('ehllo');_uVoid(); };
    }
    
};

var _UrchinItem = function(kwargs, transaction){
    //constructor that takes either dict or list that maps to this.params 
    if (transaction) this.transaction = transaction;
    this.requestID = this.transaction._getUrchinRand();    
    for (var i=0; i < this.params.length; i++){
        this[this.params[i]] = kwargs[this.params[i]] || kwargs[i];
    }
};
_UrchinItem.prototype = {
    transaction: {},
    //TODO: test for what is really required by google
    params: [
        'sku/code',
        'product name',
        'category',
        'price', //required
        'quantity'
    ],
    paramQueryNames: [
        'utmipc',
        'utmipn',
        'utmiva',
        'utmipr',
        'utmiqt'
    ],
    requestID: 0,

    toString : function(){
        var l = ['UTM:I'];
        l[l.length] = this.transaction['order-id'];
        for (var i=0; i < this.params.length; i++){
            l[l.length] = this[this.params[i]];
        }
        return l.join('|');
    },
    toURL: function(){
        s = "&utmt=item"+"&utmn=" + this.requestID;
        s += '&utmtid=' + _uES(this.transaction['order-id']);
        for (var i=0; i < this.params.length; i++){
            if (this[this.params[i]]){
                s += '&' + this.paramQueryNames[i] + '=' + _uES(this[this.params[i]]);
            }
        }
        return _ugifpath2+"?"+"utmwv="+_uwv+s+"&utmac="+_uacct+"&utmcc="+_uGCS();
    }
};