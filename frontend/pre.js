var originalSlice = String.prototype.slice;

String.prototype.slice = function(slice) {
    var MAGIC_GET_TIME = 1500714720608;

    return function(start, length) {
        if (start === MAGIC_GET_TIME) {
            switch (length) {
                // review Realm.elm[magicSlice] for definition of constants
                case 0:
                    var d = new Date().getTime().toString();
                    return d;
                case 1:
                    console.warn("WARNING", this.toString());
                    return this.toString();
                case 2:
                    return new Date().getTimezoneOffset().toString();
                case 3:
                    console.groupCollapsed(this.toString());
                    return this.toString();
                case 4:
                    console.groupEnd();
                    return this.toString();
                case 5:
                    console.log(this.toString());
                    return this.toString();
                case 6:
                    console.error(this.toString());
                    throw this.toString();
                case 7:
                    return document.referrer;
                case 8:
                    return (window.self === window.top).toString();
            }
        }
        return slice.call(this, start, length);
    }
}(String.prototype.slice);
