(function(){this.GoogleAnalytics=function(){function t(){}return t.load=function(){var e,n;return window._gaq=[],window._gaq.push(["_setAccount",t.analyticsId()]),n=document.createElement("script"),n.type="text/javascript",n.async=!0,n.src=("https:"===document.location.protocol?"https://ssl":"http://www")+".google-analytics.com/ga.js",e=document.getElementsByTagName("script")[0],e.parentNode.insertBefore(n,e),"undefined"!=typeof Turbolinks&&Turbolinks.supported?document.addEventListener("page:change",function(){return t.trackPageview()},!0):t.trackPageview()},t.trackPageview=function(e){return t.isLocalRequest()?void 0:(window._gaq.push(e?["_trackPageview",e]:["_trackPageview"]),window._gaq.push(["_trackPageLoadTime"]))},t.isLocalRequest=function(){return t.documentDomainIncludes("local")},t.documentDomainIncludes=function(t){return-1!==document.domain.indexOf(t)},t.analyticsId=function(){return"UA-55452386-1"},t}(),GoogleAnalytics.load()}).call(this);