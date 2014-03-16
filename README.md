template
========

## use google map (sample) #####

### controller

    @hash = Gmaps4rails.build_markers(@users) do |user, marker|
      marker.lat user.latitude
      marker.lng user.longitude
      marker.infowindow user.description
      marker.json({name: user.name})
    end

### model

    geocoded_by :address
    after_validation :geocode

### view

    :javascript
      handler = Gmaps.build('Google');
      handler.buildMap({ provider: {}, internal: {id: 'map'}}, function(){
      markers = handler.addMarkers(
        =raw @hash.to_json
      );
      handler.bounds.extendWith(markers);
      handler.fitMapToBounds();
    });

    %style{:width => '800px'}
      #map{:style=>"width:800px; height:400px;"}