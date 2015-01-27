(function() {

 if (window.__firefox__ === undefined) {
    window.__firefox__ = { }
 }
 
 function Favicons() {
 }

 Favicons.prototype = {
    selectors: ["link[rel~='icon']",
                "link[rel='apple-touch-icon']",
                "link[rel='apple-touch-icon-precomposed']"],
    getAll: function() {
        var res = []
        for (var s = 0; s < this.selectors.length; s++) {
            var icons = document.querySelectorAll(this.selectors[s])
            for (var i = 0; i < icons.length; i++) {
                res.push(icons[i].href);
            }
        }

        if (res.length == 0) {
            res.push(document.location.origin + "/favicon.ico")
        }

        return res;
    }
 }

 window.__firefox__.Favicons = new Favicons()
})()
