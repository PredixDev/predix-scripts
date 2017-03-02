(function() {
  'use strict';

  var URLs = {};
  var repo;
  var org;

  getURLs();
  getResource( URLs.readme, onReadme );

  // FUNCTIONS //

  function getURLs() {
    var repo = window.location.href ;
    var parser = document.createElement('a');
    parser.href = window.location.href;
    if (parser.href.endsWith("/"))
      parser.href = parser.href.substring(0,parser.href.length-1);
    //parser.protocol; // => "http:"
    //parser.hostname; // => "example.com"
    //parser.port;     // => "3000"
    //parser.pathname; // => "/pathname/"
    //parser.search;   // => "?search=test"
    //parser.hash;     // => "#hash"
    //parser.host;     // => "example.com:3000"

    var pathSplit = parser.pathname.split("/");
    repo = pathSplit.reverse()[0];
    if (parser.href.indexOf("github.io") < 0 ) {
      //internal github url
      org = pathSplit.reverse()[2];
      URLs.readme = parser.protocol + '//' + parser.hostname + '/raw/' + org + '/' + repo + '/develop/README.md';
      URLs.github = parser.protocol + '//' + parser.hostname + '/' + org + '/' + repo;
    }
    else {
      //github.com url - external
      var hostSplit = parser.hostname.split(".");
      org = hostSplit[0]
      URLs.readme = parser.protocol + '//rawgit.com/' + org + '/' + repo + '/master/README.md';
      URLs.info = parser.protocol + '//api.github.com/repos/' + org + '/' + repo;
      URLs.github = parser.protocol + '//github.com/' + org + '/' + repo;
      getResource( URLs.info, onInfo );
    }
    document.getElementById( 'view-on-github' ).href = URLs.github;
    document.getElementById( 'repo-header' ).innerHTML = repo;
    var innerHtml = document.getElementById( 'repo-footer' ).innerHTML;
    innerHtml = innerHtml.replace('{repo}', repo);
    document.getElementById( 'repo-footer' ).innerHTML = innerHtml;
    
    //innerHtml = document.getElementById( 'repo-title' ).innerHTML;
    //innerHtml = innerHtml.replace('{repo}', repo);
    //document.getElementById( 'repo-title' ).innerHTML = innerHtml;
    //document.title = innerHtml;
    
    URLs.markdown = 'https://api.github.com/markdown';

    return parser.pathname;
  }

  function onReadme( blob ) {
    render( blob );
  }

  function onInfo( blob ) {
    document.getElementById('repo-desc').innerHTML = JSON.parse(blob).description;
  }
  
  function onResource( html ) {
    document.getElementById( 'readme' ).innerHTML = html;
    document.title = $('h1').text();
  }

  function getResource( url, clbk ) {
    var xhr;
    if ( url && clbk ) {
      xhr = new XMLHttpRequest();
      xhr.open( 'GET', url );

      xhr.onreadystatechange = function () {
        if ( xhr.readyState != 4 || xhr.status != 200 ){
          return;
        }
        clbk( xhr.responseText );
      };
      xhr.send();
    }
  }

  function postResource( url, data, clbk ) {
    var xhr;
    if ( url && clbk ) {
      xhr = new XMLHttpRequest();
      xhr.open( 'POST', url, true );

      xhr.setRequestHeader( 'Content-Type', 'application/json' );

      xhr.onreadystatechange = function () {
        if ( xhr.readyState != 4 || xhr.status != 200 ){
          return;
        }
        clbk( xhr.responseText );
      };
      xhr.send( data );
    }
  }

  function render( content ) {
    content = {
      'text': content,
      'mode': 'markdown',
      'context': repo
    };
    content = JSON.stringify( content );
    postResource( URLs.markdown, content, onResource );
  }
})();
