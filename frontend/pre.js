var originalSlice = String.prototype.slice;

String.prototype.slice = function(slice) {
    var MAGIC_GET_TIME = 1500714720608;

    return function(start, length) {
        if (start === MAGIC_GET_TIME) {
            switch (length) {
                case 0:
                    var d = new Date().getTime().toString();
                    return d;
                case 1:
                    console.warn("WARNING", this.toString());
                    return "";
                case 2:
                    return new Date().getTimezoneOffset().toString();
            }
        }
        return slice.call(this, start, length);
    }
}(String.prototype.slice);
