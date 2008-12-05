// TODO: build into genetify

function getScrollXY() {
  var scrOfX = 0, scrOfY = 0;
  if( typeof( window.pageYOffset ) == 'number' ) {
    //Netscape compliant
    scrOfY = window.pageYOffset;
    scrOfX = window.pageXOffset;
  } else if( document.body && ( document.body.scrollLeft || document.body.scrollTop ) ) {
    //DOM compliant
    scrOfY = document.body.scrollTop;
    scrOfX = document.body.scrollLeft;
  } else if( document.documentElement && ( document.documentElement.scrollLeft || document.documentElement.scrollTop ) ) {
    //IE6 standards compliant mode
    scrOfY = document.documentElement.scrollTop;
    scrOfX = document.documentElement.scrollLeft;
  }
  return [ scrOfX, scrOfY ];
}
MAX_SCROLL = 0;
setInterval(function(){
    MAX_SCROLL = Math.max(MAX_SCROLL, getScrollXY()[1]);
    // console.log(MAX_SCROLL);
}, 1000);

window.onbeforeunload = function(){
    genetify.record.goal('max_scroll', MAX_SCROLL);
};
