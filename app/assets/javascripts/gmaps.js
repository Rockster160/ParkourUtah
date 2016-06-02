var ready = function() {
  if ($('.gmap').length > 0) {

    var gmap = $('.gmap');
    handler = Gmaps.build('Google');
    handler.buildMap({
        provider: {
          // pass in other Google Maps API options here
          mapTypeId: google.maps.MapTypeId.HYBRID // ROADMAP TERRAIN SATELLITE HYBRID
        },
        internal: {
          id: 'map'
        }
      },
      function() {
        var marker_coords = $('.gmap_coord').map(function() {
          return {
            lat: $(this).data('lat'),
            lng: $(this).data('lon'),
            infowindow: '<a href="' + $(this).data('spot-url') + '">' + $(this).data('spot-name') + '<a>'
          }
        });
        markers = handler.addMarkers(marker_coords, {
          animation: google.maps.Animation.DROP,
          draggable: true
        });
        if (gmap.data('contain')) {
          handler.bounds.extendWith(markers);
          handler.fitMapToBounds();
        } else {
          var pt = new google.maps.LatLng(gmap.data('lat'), gmap.data('lng'));
          handler.map.centerOn(pt);
          handler.map.serviceObject.setZoom(gmap.data('zoom'));
        }
      }
    );

    $('#gmaps_search').click(function() {
      geoLocate($('#gmaps_address').val());
    });

    $('#gmaps_form').on('submit', function() {
      var lat = markers[0].getServiceObject().getPosition().lat(),
        lon = markers[0].getServiceObject().getPosition().lng();

      $('#lat').val(lat);
      $('#lon').val(lon);
    });

    geoLocate = function(address) {
      var geocoder = new google.maps.Geocoder();
      geocoder.geocode({
        address: address
      }, function(results, status) {
        if (status == google.maps.GeocoderStatus.OK) {
          var latitude = results[0].geometry.location.lat();
          var longitude = results[0].geometry.location.lng();
          handler.removeMarkers(markers);
          markers = handler.addMarkers(
            [{
              lat: latitude,
              lng: longitude,
            }], {
              animation: google.maps.Animation.DROP,
              draggable: true
            }
          );
          markers[0].panTo();
        } else {
          console.log('error');
          return false
        }
      })
    }

  }
}


$(document).ready(ready);
$(document).on('page:load', ready);
