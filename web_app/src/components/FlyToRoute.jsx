import { useEffect, useRef } from 'react'; 

export function FlyToRoute({ map, points }) {
  // Refs hoiavad Google Maps objektid hilisemaks kustutamiseks
  const polylineRef = useRef(null);  
  const startMarkerRef = useRef(null);
  const endMarkerRef = useRef(null);

  useEffect(() => {
    // Kui kaart või punktid puuduvad, siis ei tee midagi
    if (!map || !points || points.length === 0) return;

    // Eemalda eelnevalt joonistatud marsruut ja markerid
    if (polylineRef.current) polylineRef.current.setMap(null);
    if (startMarkerRef.current) startMarkerRef.current.setMap(null);
    if (endMarkerRef.current) endMarkerRef.current.setMap(null);

    // Loo sinine marsruudi joon
    const polyline = new window.google.maps.Polyline({
      path: points.map(pt => ({ lat: pt.lat, lng: pt.lng })), // Punktide koordinaadid
      geodesic: true,           // Joon järgib Maa kõverust
      strokeColor: '#0f53ff',   // Joon sinine
      strokeOpacity: 1.0,       // Täielikult nähtav
      strokeWeight: 7,          // Joon paksus
    });

    polyline.setMap(map);       // Lisa joon kaardile
    polylineRef.current = polyline;

    // Keskenda kaart marsruudile
    const bounds = new window.google.maps.LatLngBounds();
    points.forEach(pt => bounds.extend(new window.google.maps.LatLng(pt.lat, pt.lng)));
    map.fitBounds(bounds); // Sobita kaardi vaade punktidega

    // Algus- ja lõpp-punkt
    const start = points[0];
    const end = points[points.length - 1];

    // Loo roheline start marker
    const startMarker = new window.google.maps.Marker({
      position: { lat: start.lat, lng: start.lng },
      map,
      label: 'A',
      title: 'Alguspunkt',
      icon: {
        path: window.google.maps.SymbolPath.CIRCLE,
        scale: 10,
        fillColor: 'green',
        fillOpacity: 1,
        strokeColor: 'white',
        strokeWeight: 2,
      },
    });

    // Loo punane lõpp marker
    const endMarker = new window.google.maps.Marker({
      position: { lat: end.lat, lng: end.lng },
      map,
      label: 'B',
      title: 'Lõpp-punkt',
      icon: {
        path: window.google.maps.SymbolPath.CIRCLE,
        scale: 10,
        fillColor: 'red',
        fillOpacity: 1,
        strokeColor: 'white',
        strokeWeight: 2,
      },
    });

    startMarkerRef.current = startMarker;
    endMarkerRef.current = endMarker;

    // Puhastus komponentide eemaldamisel
    return () => {
      polyline.setMap(null);
      startMarker.setMap(null);
      endMarker.setMap(null);
    };
  }, [map, points]);

  return null;
}