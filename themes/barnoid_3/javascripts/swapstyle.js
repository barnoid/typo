/***********************************************************************************************
                             Script to swap between stylesheets
  Written by Mark Wilton-Jones, 05/12/2002. v2.2.1 updated 14/03/2006 for dynamic stylesheets
************************************************************************************************

Please see http://www.howtocreate.co.uk/jslibs/ for details and a demo of this script
Please see http://www.howtocreate.co.uk/jslibs/termsOfUse.html for terms of use

To set up the page in the first place:

	Inbetween the <head> tags, put:

		<script src="PATH TO SCRIPT/swapstyle.js" type="text/javascript" language="javascript1.2"></script>

	Also between the head tags, put your stylesheets, best done as external links, but you can use
	<style ...> tags as well.

		Stylesheets cannot be switched if they have no title attribute and will be used at all times:

			<link rel="stylesheet" type="text/css" href="all.css">

		Stylesheets will be on by default if they have a title attribute and their rel attribute is set to 'stylesheet'.
		Most browsers will only allow one of these to be defined (or several sharing the same title):

			<link rel="stylesheet" type="text/css" href="default.css" title="Default">

		Stylesheets will be off by default if they have a title attribute and their rel attribute is set to 'alternate stylesheet':

			<link rel="alternate stylesheet" type="text/css" href="contrast.css" title="High Contrast">
			<link rel="alternate stylesheet" type="text/css" href="bigFont.css" title="Big Font">

To swap between stylesheets:

	changeStyle();                           //switches off all stylesheets that have title attributes
	changeStyle('Default');                  //switches off all stylesheets that have title attributes that do not match 'Default'
	changeStyle('High Contrast');            //switches off all stylesheets that have title attributes that do not match 'High Contrast'
	changeStyle('Big Font');                 //switches off all stylesheets that have title attributes that do not match 'Big Font'
	changeStyle('High Contrast','Big Font'); //switches off all stylesheets that have title attributes that do not match 'High Contrast' or 'Big Font'

	Opera 7+ and Mozilla also allow users to switch between stylesheets using the view menu (only one at a time though ...)

To make the script remember the user's choice of stylesheets, for example to use on more than one page or if they reload
- includes stylesheets chosen using the view menu in Gecko - it will only attempt to store a cookie if they actually
changed something:

	In these examples, I call the cookie used to store the choice 'styleTestStore'. You could use any name you like.

	To remember only until the browser window is closed:

		<body onload="useStyleAgain('styleTestStore');" onunload="rememberStyle('styleTestStore');">

	To remember for 10 days (for example):

		<body onload="useStyleAgain('styleTestStore');" onunload="rememberStyle('styleTestStore',10);">

Note that some browsers (most notably Opera) do not fire the onunload event when the page is
reloaded, and will only fire it when the user clicks a link or submits a form. If you need the
style preference to be stored even when reloading, you should call rememberStyle immediately
after you call changeStyle.

If you are going to provide users with a mechanism to change stylesheets, you may want to check
if the browser will allow you to change stylesheets first. Use:

	if( document.styleSheets || ( window.opera && document.childNodes ) || ( window.ScriptEngine && ScriptEngine().indexOf('InScript') + 1 && document.createElement ) ) {
		document.write('Something that allows them to choose stylesheets');
	}

It's not perfect, because it will also appear in ICEbrowser, which makes a mess when it tries to
change to an alternate stylesheet. If you want, you can use
	if( ( document.styleSheets || ( window.opera && document.childNodes ) || ( window.ScriptEngine && ScriptEngine().indexOf('InScript') + 1 && document.createElement ) ) && !navigator.__ice_version ) {
but you should then update that if ICE is updated to make it work properly.
________________________________________________________________________________________________*/

function getAllSheets() {
	if( !window.ScriptEngine && navigator.__ice_version ) { return document.styleSheets; }
	if( document.getElementsByTagName ) { var Lt = document.getElementsByTagName('link'), St = document.getElementsByTagName('style');
	} else if( document.styleSheets && document.all ) { var Lt = document.all.tags('LINK'), St = document.all.tags('STYLE');
	} else { return []; } for( var x = 0, os = []; Lt[x]; x++ ) {
		var rel = Lt[x].rel ? Lt[x].rel : Lt[x].getAttribute ? Lt[x].getAttribute('rel') : '';
		if( typeof( rel ) == 'string' && rel.toLowerCase().indexOf('style') + 1 ) { os[os.length] = Lt[x]; }
	} for( var x = 0; St[x]; x++ ) { os[os.length] = St[x]; } return os;
}
function changeStyle() {
	window.userHasChosen = window.MWJss;
	for( var x = 0, ss = getAllSheets(); ss[x]; x++ ) {
		if( ss[x].title ) { ss[x].disabled = true; }
		for( var y = 0; y < arguments.length; y++ ) { if( ss[x].title == arguments[y] ) { ss[x].disabled = false; } }
} }
function rememberStyle( cookieName, cookieLife ) {
	for( var viewUsed = false, ss = getAllSheets(), x = 0; window.MWJss && MWJss[x] && ss[x]; x++ ) { if( ss[x].disabled != MWJss[x] ) { viewUsed = true; break; } }
	if( !window.userHasChosen && !viewUsed ) { return; }
	for( var x = 0, outLine = '', doneYet = []; ss[x]; x++ ) {
		if( ss[x].title && ss[x].disabled == false && !doneYet[ss[x].title] ) { doneYet[ss[x].title] = true; outLine += ( outLine ? ' MWJ ' : '' ) + escape( ss[x].title ); } }
	if( ss.length ) { document.cookie = escape( cookieName ) + '=' + escape( outLine ) + ( cookieLife ? ';expires=' + new Date( ( new Date() ).getTime() + ( cookieLife * 86400000 ) ).toGMTString() : '' ) + ';path=/'; }
}
function useStyleAgain( cookieName ) {
	for( var x = 0; x < document.cookie.split( "; " ).length; x++ ) {
		var oneCookie = document.cookie.split( "; " )[x].split( "=" );
		if( oneCookie[0] == escape( cookieName ) ) {
			var styleStrings = unescape( oneCookie[1] ).split( " MWJ " );
			for( var y = 0, funcStr = ''; styleStrings[y]; y++ ) { funcStr += ( y ? ',' : '' ) + 'unescape( styleStrings[' + y + '] )'; }
			eval( 'changeStyle(' + funcStr + ');' ); break;
	} } window.MWJss = []; for( var ss = getAllSheets(), x = 0; ss[x]; x++ ) { MWJss[x] = ss[x].disabled; }
}


/* load it up right away */
useStyleAgain('mainsitestyle');

window.onload = function () {
	if( document.childNodes && document.createElement && ( document.styleSheets || window.opera || ( window.ScriptEngine && ScriptEngine().indexOf('InScript') + 1 ) ) && !navigator.__ice_version ) {
		var linkList = document.getElementsByTagName('link');
		var oH3 = document.createElement('h3');
		oH3.appendChild(document.createTextNode('Style'));
		var oForm = document.createElement('form');
		oForm.appendChild(document.createElement('p'));
		var sel = document.createElement('select');
		oForm.firstChild.appendChild(sel);
		var theCurCol, selopt;
		for( var x = 0, y = document.cookie.split('; '); x < y.length; x++ ) {
			var oneCookie = y[x].split('=');
			if( oneCookie[0] == 'mainsitestyle' ) {
				theCurCol = unescape( unescape( oneCookie[1] ).replace(/ MWJ .*/,'') );
				break; 
			}
		}
		for( var n = 0, optn, oRel, oTitl; n < linkList.length; n++ ) {
			oRel = linkList[n].getAttribute('rel');
			oTitl = linkList[n].getAttribute('title');
			if( !oRel || !oTitl || ( oRel != 'stylesheet' && oRel != 'alternate stylesheet' ) || oTitl.match(/spoken/i) ) { continue; }
			optn = document.createElement('option');
			optn.text = oTitl;
			optn.value = oTitl;
			try { sel.add(optn,null); } catch(e) { try { sel.add(optn,sel.options.length); } catch(f) { sel.appendChild(optn); } }
			if( theCurCol == oTitl || ( !theCurCol && oRel == 'stylesheet' && typeof( theCurCol ) == 'undefined' ) ) { optn.selected = true; selopt = sel.options.length - 1; }
		}
		optn = document.createElement('option');
		optn.text = 'No style';
		optn.value = '';
		try { sel.add(optn,null); } catch(e) { try { sel.add(optn,sel.options.length); } catch(f) { sel.appendChild(optn); } }
		if( !theCurCol && typeof( theCurCol ) != 'undefined' ) { optn.selected = true; }

		try { sel.setAttribute('onchange','var tmpVal = this.selectedIndex;changeStyle(this.options[tmpVal].value);this.options[tmpVal].selected = true;rememberStyle(\'mainsitestyle\',1800);'); } catch(e) {}
		sel.onchange = function () {
			var tmpVal = this.selectedIndex;
			changeStyle(this.options[tmpVal].value);
			this.options[tmpVal].selected = true;
			rememberStyle('mainsitestyle',1800);
		};

		var oParent = document.getElementById('sidebar');
		oParent.appendChild(oH3);
		oParent.appendChild(oForm);

		if( !selopt ) { selopt = sel.selectedIndex; }
		useStyleAgain('mainsitestyle');
		setTimeout(function () { sel.options[selopt].selected = true; },10);
		if( selopt && location.hash && location.hash.match(/^#./) ) {
			location.hash = location.hash.replace(/^#/,'');
		}
	}
};

