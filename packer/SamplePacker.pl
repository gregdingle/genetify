#!perl
#
use strict;
use Pack;

use vars qw/$VERSION/;
$VERSION = '1.01b';
my $Version  = "v$VERSION\[p$Pack::VERSION-pm$Pack::PM_VERSION\]";


if ((!$ARGV[0]) || ($ARGV[0] ne '-o')) {
   print "$0 $Version\n";
   print "  This program generates an html page containing examples of packed Javascript\n";
   print "\tSyntax: $0 -o > testpage.htm\n";
   exit(1);
}

# Get the javascript to be packed
  my $libraryscript = getJSLibrary(); # eg a library - could be from an external file
  my @blockscripts  = getJSBlocks();  # eg local blocks specific to this page

# Set pack options (extend with cgi interface etc)
  my $encoding          = 62;
  my $fastdecoding      = 1;
  my $specialcharacters = 1;

# Pack the source scripts
  my $packedlibrary = &Pack::pack($libraryscript, $encoding, $fastdecoding, $specialcharacters);
  my @packedblocks  = ();
  for (my $i=0; $i< scalar(@blockscripts); $i++) { # Pack each indexed block of js code
    $packedblocks[$i] = &Pack::pack($blockscripts[$i], $encoding, $fastdecoding, $specialcharacters);
  }

# Output the html page containing the packed scripts (passed by reference in this case)
  #print "Content-type: text/html\n\n";
  printHTMLPage(\$packedlibrary,\@packedblocks);

##########
# End    #
exit(0); #
##########

################
# Sub-routines #
################

#############
# HTML PAGE #
#############
sub printHTMLPage {
my ($libraryref,$blocksref) = @_; # References to packed scripts - need to be de-referenced in interpolations
my ($HTML) = <<"END_HTML";
<html><head><title>Packed script example page</title>

<!-- Here is where the library script is inserted -->
<script language="JavaScript">$$libraryref</script>
<!-->

</head><body>
<center>
<h1>Packed Javascript</h1>

<p>
Javascript contained within this page has been packed using using <br>
Packer [$0] $Version<br>
a JavaScript Compressor/Obfuscator developed by Dean Edwards <<a href="http://dean.edwards.name/">http://dean.edwards.name/</a>><br>
and ported to Perl by Rob Seiler, ELR Software Pty Ltd <<a href="http://www.elr.com.au/">http://www.elr.com.au</a>><br>
Copyright 2005. License <a href="http://creativecommons.org/licenses/LGPL/2.1/">http://creativecommons.org/licenses/LGPL/2.1/</a>>
</p>
</center>

<h2>Profile of your Browser</h2>
<p>Here are the results of running the packed JavaScript code in the browser you are using.
If you are seeing bowser vendor, version, and operating system data, the packed scripts are functioning properly.</p>

<!-- Here is where the local block scripts are inserted -->
<h3>Bascic Data</h3>       <script language="JavaScript">$$blocksref[0]</script>
<h3>Version Number</h3>    <script language="JavaScript">$$blocksref[1]</script>
<h3>Browser Version</h3>   <script language="JavaScript">$$blocksref[2]</script>
<h3>JavaScript Version</h3><script language="JavaScript">$$blocksref[3]</script>
<h3>OS</h3>                <script language="JavaScript">$$blocksref[4]</script>
<!-->

</body></html>
END_HTML
print $HTML;
}

#############################
# Javascript Source Scripts #
#############################
# Below are our example Javascript code blocks

sub getJSLibrary {
my ($jscript) = <<'END_JSLIBRARY';
// Ultimate client-side JavaScript client sniff.
// (C) Netscape Communications 1999.  Permission granted to reuse and distribute.
// Revised 7 May 99 to add is.nav5up and is.ie5up (see below). (see below).

// Everything you always wanted to know about your JavaScript client
// but were afraid to ask ... "Is" is the constructor function for "is" object,
// which has properties indicating:
// (1) browser vendor:
//     is.nav, is.ie, is.opera
// (2) browser version number:
//     is.major (integer indicating major version number: 2, 3, 4 ...)
//     is.minor (float   indicating full  version number: 2.02, 3.01, 4.04 ...)
// (3) browser vendor AND major version number
//     is.nav2, is.nav3, is.nav4, is.nav4up, is.ie3, is.ie4, is.ie4up, is.ie5, is.ie5up
// (4) JavaScript version number:
//     is.js (float indicating full JavaScript version number: 1, 1.1, 1.2 ...)
// (5) OS platform and version:
//     is.win, is.win16, is.win32, is.win31, is.win95, is.winnt, is.win98
//     is.os2
//     is.mac, is.mac68k, is.macppc
//     is.unix
//        is.sun, is.sun4, is.sun5, is.suni86
//        is.irix, is.irix5, is.irix6
//        is.hpux, is.hpux9, is.hpux10
//        is.aix, is.aix1, is.aix2, is.aix3, is.aix4
//        is.linux, is.sco, is.unixware, is.mpras, is.reliant
//        is.dec, is.sinix, is.freebsd, is.bsd
//     is.vms
//
// See http://www.it97.de/JavaScript/JS_tutorial/bstat/navobj.html and
// http://www.it97.de/JavaScript/JS_tutorial/bstat/Browseraol.html
// for detailed lists of userAgent strings.

//
// Note: you don't want your Nav4 or IE4 code to "turn off" or
// stop working when Nav5 and IE5 (or later) are released, so
// in conditional code forks, use is.nav4up ("Nav4 or greater")
// and is.ie4up ("IE4 or greater") instead of is.nav4 or is.ie4
// to check version in code which you want to work on future
// versions.


function Is ()
{   // convert all characters to lowercase to simplify testing
    var agt=navigator.userAgent.toLowerCase();

    // *** BROWSER VERSION ***
    // Note: On IE5, these return 4, so use is.ie5up to detect IE5.
    this.major = parseInt(navigator.appVersion);
    this.minor = parseFloat(navigator.appVersion);

    this.nav  = ((agt.indexOf('mozilla')!=-1) && (agt.indexOf('spoofer')==-1)
                && (agt.indexOf('compatible') == -1) && (agt.indexOf('opera')==-1)
                && (agt.indexOf('webtv')==-1));
    this.nav2 = (this.nav && (this.major == 2));
    this.nav3 = (this.nav && (this.major == 3));
    this.nav4 = (this.nav && (this.major == 4));
    this.nav4up = (this.nav && (this.major >= 4));
    this.navonly  = (this.nav && ((agt.indexOf(";nav") != -1) ||
                     (agt.indexOf("; nav") != -1)) );
    this.nav5 = (this.nav && (this.major == 5));
    this.nav5up = (this.nav && (this.major >= 5));

    this.ie   = (agt.indexOf("msie") != -1);
    this.ie3  = (this.ie && (this.major < 4));
    this.ie4  = (this.ie && (this.major == 4) && (agt.indexOf("msie 5.0")==-1) );
    this.ie4up  = (this.ie  && (this.major >= 4));
    this.ie5  = (this.ie && (this.major == 4) && (agt.indexOf("msie 5.0")!=-1) );
    this.ie5up  = (this.ie  && !this.ie3 && !this.ie4);

    this.aol   = (agt.indexOf("aol") != -1);
    this.aol3  = (this.aol && this.ie3);
    this.aol4  = (this.aol && this.ie4);

    this.opera = (agt.indexOf("opera") != -1);
    this.webtv = (agt.indexOf("webtv") != -1);

    // *** JAVASCRIPT VERSION CHECK ***
    // Useful to workaround Nav3 bug in which Nav3
    // loads <SCRIPT LANGUAGE="JavaScript1.2">
    if (this.nav2 || this.ie3) this.js = 1.0;
    else if (this.nav3 || this.opera) this.js = 1.1;
    else if ((this.nav4 && (this.minor <= 4.05)) || this.ie4) this.js = 1.2;
    else if ((this.nav4 && (this.minor > 4.05)) || this.ie5) this.js = 1.3;
    else if (this.nav5) this.js = 1.4;
    // NOTE: In the future, update this code when newer versions of JS
    // are released. For now, we try to provide some upward compatibility
    // so that future versions of Nav and IE will show they are at
    // *least* JS 1.x capable. Always check for JS version compatibility
    // with > or >=.
    else if (this.nav && (this.major > 5)) this.js = 1.4;
    else if (this.ie && (this.major > 5)) this.js = 1.3;
    // HACK: no idea for other browsers; always check for JS version with > or >=
    else this.js = 0.0;

    // *** PLATFORM ***
    this.win   = ( (agt.indexOf("win")!=-1) || (agt.indexOf("16bit")!=-1) );
    // NOTE: On Opera 3.0, the userAgent string includes "Windows 95/NT4" on all
    //        Win32, so you can't distinguish between Win95 and WinNT.
    this.win95 = ((agt.indexOf("win95")!=-1) || (agt.indexOf("windows 95")!=-1));

    // is this a 16 bit compiled version?
    this.win16 = ((agt.indexOf("win16")!=-1) ||
                  (agt.indexOf("16bit")!=-1) || (agt.indexOf("windows 3.1")!=-1) ||
                  (agt.indexOf("windows 16-bit")!=-1) );

    this.win31 = ((agt.indexOf("windows 3.1")!=-1) || (agt.indexOf("win16")!=-1) ||
                  (agt.indexOf("windows 16-bit")!=-1));

    // NOTE: Reliable detection of Win98 may not be possible. It appears that:
    //       - On Nav 4.x and before you'll get plain "Windows" in userAgent.
    //       - On Mercury client, the 32-bit version will return "Win98", but
    //         the 16-bit version running on Win98 will still return "Win95".
    this.win98 = ((agt.indexOf("win98")!=-1) || (agt.indexOf("windows 98")!=-1));
    this.winnt = ((agt.indexOf("winnt")!=-1) || (agt.indexOf("windows nt")!=-1));
    this.win32 = ( this.win95 || this.winnt || this.win98 ||
                   ((this.major >= 4) && (navigator.platform == "Win32")) ||
                   (agt.indexOf("win32")!=-1) || (agt.indexOf("32bit")!=-1) );

    this.os2   = ((agt.indexOf("os/2")!=-1) ||
                  (navigator.appVersion.indexOf("OS/2")!=-1) ||
                  (agt.indexOf("ibm-webexplorer")!=-1));

    this.mac    = (agt.indexOf("mac")!=-1);
    this.mac68k = (this.mac && ((agt.indexOf("68k")!=-1) ||
                               (agt.indexOf("68000")!=-1)));
    this.macppc = (this.mac && ((agt.indexOf("ppc")!=-1) ||
                               (agt.indexOf("powerpc")!=-1)));

    this.sun   = (agt.indexOf("sunos")!=-1);
    this.sun4  = (agt.indexOf("sunos 4")!=-1);
    this.sun5  = (agt.indexOf("sunos 5")!=-1);
    this.suni86= (this.sun && (agt.indexOf("i86")!=-1));
    this.irix  = (agt.indexOf("irix") !=-1);    // SGI
    this.irix5 = (agt.indexOf("irix 5") !=-1);
    this.irix6 = ((agt.indexOf("irix 6") !=-1) || (agt.indexOf("irix6") !=-1));
    this.hpux  = (agt.indexOf("hp-ux")!=-1);
    this.hpux9 = (this.hpux && (agt.indexOf("09.")!=-1));
    this.hpux10= (this.hpux && (agt.indexOf("10.")!=-1));
    this.aix   = (agt.indexOf("aix") !=-1);      // IBM
    this.aix1  = (agt.indexOf("aix 1") !=-1);
    this.aix2  = (agt.indexOf("aix 2") !=-1);
    this.aix3  = (agt.indexOf("aix 3") !=-1);
    this.aix4  = (agt.indexOf("aix 4") !=-1);
    this.linux = (agt.indexOf("inux")!=-1);
    this.sco   = (agt.indexOf("sco")!=-1) || (agt.indexOf("unix_sv")!=-1);
    this.unixware = (agt.indexOf("unix_system_v")!=-1);
    this.mpras    = (agt.indexOf("ncr")!=-1);
    this.reliant  = (agt.indexOf("reliantunix")!=-1);
    this.dec   = ((agt.indexOf("dec")!=-1) || (agt.indexOf("osf1")!=-1) ||
         (agt.indexOf("dec_alpha")!=-1) || (agt.indexOf("alphaserver")!=-1) ||
         (agt.indexOf("ultrix")!=-1) || (agt.indexOf("alphastation")!=-1));
    this.sinix = (agt.indexOf("sinix")!=-1);
    this.freebsd = (agt.indexOf("freebsd")!=-1);
    this.bsd = (agt.indexOf("bsd")!=-1);
    this.unix  = ((agt.indexOf("x11")!=-1) || this.sun || this.irix || this.hpux ||
                 this.sco ||this.unixware || this.mpras || this.reliant ||
                 this.dec || this.sinix || this.aix || this.linux || this.bsd || this.freebsd);

    this.vms   = ((agt.indexOf("vax")!=-1) || (agt.indexOf("openvms")!=-1));
}

var is;
var isIE3Mac = false;
// this section is designed specifically for IE3 for the Mac

if ((navigator.appVersion.indexOf("Mac")!=-1) && (navigator.userAgent.indexOf("MSIE")!=-1) &&
(parseInt(navigator.appVersion)==3))
       isIE3Mac = true;
else   is = new Is();

END_JSLIBRARY
return $jscript; # Return the JS library code block
}

sub getJSBlocks {
my @jscript = ();
($jscript[0]) = <<'END_JSBLOCK0';
  document.write("navigator.appName " + navigator.appName + "<br>");
  document.write("navigator.userAgent" + navigator.userAgent + "<br>");
  document.write("navigator.appVersion" + navigator.appVersion + "<br>");
END_JSBLOCK0
($jscript[1]) = <<'END_JSBLOCK1';
  document.write("<TT>major:" + is.major + "</TT><br>");
  document.write("<TT>minor:" + is.minor + "</TT><br>");
END_JSBLOCK1
($jscript[2]) = <<'END_JSBLOCK2';
  document.write("nav:" + is.nav + "<br>");
  document.write("nav2:" + is.nav2 + "<br>");
  document.write("nav3:" + is.nav3 + "<br>");
  document.write("nav4:" + is.nav4 + "<br>");
  document.write("nav4up:" + is.nav4up + "<br>");
  document.write("nav5:" + is.nav5 + "<br>");
  document.write("nav5up:" + is.nav5up + "<br>");
  document.write("navonly:" + is.navonly + "<br>");
  document.write("<P>" + "ie:" + is.ie + "<br>");
  document.write("ie3:" + is.ie3 + "<br>");
  document.write("ie4:" + is.ie4 + "<br>");
  document.write("ie4up:" + is.ie4up + "<br>");
  document.write("ie5:" + is.ie5 + "<br>");
  document.write("ie5up:" + is.ie5up + "<br>");
  document.write("<P>" + "aol:" + is.aol + "<br>");
  document.write("aol3:" + is.aol3 + "<br>");
  document.write("aol4:" + is.aol4 + "<br>");
  document.write("<P>" + "opera:" + is.opera + "<br>");
  document.write("<P>" + "webtv:" + is.webtv + "<br>");
END_JSBLOCK2
($jscript[3]) = <<'END_JSBLOCK3';
  document.write("js:" + is.js + "<br>");
END_JSBLOCK3
($jscript[4]) = <<'END_JSBLOCK4';
  document.write("win:" + is.win + "<br>");
  document.write("win16:" + is.win16 + "<br>");
  document.write("win31:" + is.win31 + "<br>");
  document.write("win32:" + is.win32 + "<br>");
  document.write("win95:" + is.win95 + "<br>");
  document.write("win98:" + is.win98 + "<br>");
  document.write("winnt:" + is.winnt + "<br>");
  document.write("<P>" + "os2:" + is.os2 + "<br>");
  document.write("<P>" + "mac:" + is.mac + "<br>");
  document.write("mac68k:" + is.mac68k + "<br>");
  document.write("macppc:" + is.macppc + "<br>");
  document.write("<P>" + "unix:" + is.unix + "<br>");
  document.write("sun:" + is.sun + "<br>");
  document.write("sun4:" + is.sun4 + "<br>");
  document.write("sun5:" + is.sun5 + "<br>");
  document.write("suni86:" + is.suni86 + "<br>");
  document.write("irix:" + is.irix + "<br>");
  document.write("irix5:" + is.irix5 + "<br>");
  document.write("irix6:" + is.irix6 + "<br>");
  document.write("hpux:" + is.hpux + "<br>");
  document.write("hpux9:" + is.hpux9 + "<br>");
  document.write("hpux10:" + is.hpux10 + "<br>");
  document.write("aix:" + is.aix + "<br>");
  document.write("aix1:" + is.aix1 + "<br>");
  document.write("aix2:" + is.aix2 + "<br>");
  document.write("aix3:" + is.aix3 + "<br>");
  document.write("aix4:" + is.aix4 + "<br>");
  document.write("linux:" + is.linux + "<br>");
  document.write("sco:" + is.sco + "<br>");
  document.write("unixware:" + is.unixware + "<br>");
  document.write("mpras:" + is.mpras + "<br>");
  document.write("reliant:" + is.reliant + "<br>");
  document.write("dec:" + is.dec + "<br>");
  document.write("sinix:" + is.sinix + "<br>");
  document.write("bsd:" + is.bsd + "<br>");
  document.write("freebsd:" + is.freebsd + "<br>");
  document.write("<P>" + "vms:" + is.vms + "<br>");
END_JSBLOCK4
return @jscript;
}
