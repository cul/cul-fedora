// Note: The Open and close links are pretty much identical.
var map, mapDiv, layerId = false;
function init_ext(){
  init_map("file%3A%2Fhmt/sirius2/cul3/ldpd/apis/jp2/3/columbia.apis.p223.f.0.600.jp2");
}
function init_map(_rft) {
  if (_rft == null) {
    return;
  }
  metadataUrl = "http://seasnail.cc.columbia.edu:8080/adore-djatoka/resolver?url_ver=Z39.88-2004&rft_id=" + _rft + "&svc_id=info:lanl-repo/svc/getMetadata&svc_val_fmt=info:lanl-repo/svc/getMetadata/callback&svc.callback=?";
  var metadata = new OpenLayers.Layer.OpenURL.Metadata(metadataUrl, setMetadata); // callbacks will actually use metadata

}
function debugHash(object,label){
  debug = label + "[\n";
  for (name in object){
    debug += (name + " : \"" + object[name] + "\",\n");
  }
  debug += "\n]";
  window.alert(debug);
}
function setMetadata(metadata){
        var OUlayer = new OpenLayers.Layer.OpenURL( "OpenURL",
          "http://seasnail.cc.columbia.edu:8080/", {layername: 'basic', format:'image/jpeg', rft_id:metadata['identifier'], imgMetadata: metadata} );
        
        var lyrMetadata = OUlayer.getImageMetadata();
        var resolutions = OUlayer.getResolutions();        
        var maxExtent = new OpenLayers.Bounds(0, 0, lyrMetadata.width, lyrMetadata.height);
        var tileSize = OUlayer.getTileSize();
        var options = {resolutions: resolutions, maxExtent: maxExtent, tileSize: tileSize};
        if (!map) map = new OpenLayers.Map( 'map');
        if (layerId){
          var prev = map.getLayer(layerId);
          prev.destroy();
        }
        layerId = OUlayer.id;
        map.setOptions(options);
        map.addLayer(OUlayer);
        var lon = lyrMetadata.width / 2;
        var lat = lyrMetadata.height / 2;
        map.setCenter(new OpenLayers.LonLat(lon, lat), 0);
}

