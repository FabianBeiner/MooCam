(function() {
  var MooCam = this.MooCam = new Class({
      Implements: [Events, Options],

    options: {
        swfPath: 'MooCam.swf',
        swfWidth: 480,
        swfHeight: 480
    },

    initialize: function(camContainer, options) {
        this.camContainer = $(camContainer);
        this.setOptions(options);
        this.camId = $(this.setupCamera());
    },

    setupCamera: function() {
        if (this.camContainer != null) {
            this.flashCam = new Swiff(this.options.swfPath, {
                container: this.camContainer,
                width: this.options.swfWidth,
                height: this.options.swfHeight,
                params: {
                    bgcolor: '#000000',
                    menu: 'false'
                }
            });
            return this.flashCam.toElement().get('id');
        }
        return null;
    },

    takePicture: function(strFilter) {
        Swiff.remote(this.camId, 'takePicture', (strFilter ? strFilter : ''));
        return true;
    },

    deletePicture: function() {
        Swiff.remote(this.camId, 'deletePicture');
        return true;
    },

    savePicture: function() {
        Swiff.remote(this.camId, 'savePicture');
        return true;
    }
  });
})();
