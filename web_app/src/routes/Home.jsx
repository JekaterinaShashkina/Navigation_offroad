import { useEffect, useRef, useState } from 'react'; 
import { signOut, getAuth } from 'firebase/auth';
import { useNavigate } from 'react-router';
import { LayerToggleButton } from '../components/LayerToggleButton';
import { UserMenuButton } from '../components/UserMenuButton';
import { RouteBuilderButton } from '../components/RouteBuilderButton';

export function Home() {
  const auth = getAuth(); // Firebase auth objekt
  const navigate = useNavigate(); // Navigeerimisfunktsioon
  const [userMenuOpen, setUserMenuOpen] = useState(false); // Kasutajamenüü avatud/kinni
  const [layerMenuOpen, setLayerMenuOpen] = useState(false); // Kihtide menüü avatud/kinni

  // Refid Google Maps objektidele ja kihtidele
  const mapRef = useRef(null);
  const kaitsealaLayerRef = useRef(null);
  const hoiualaLayerRef = useRef(null);
  const keelualaLayerRef = useRef(null);

  const [map, setMap] = useState(null); // Google Maps instants
  const [layers, setLayers] = useState({
    kaitseala: true,
    hoiuala: false,
    keeluala: false,
  });

  // Funktsioon välja logimiseks
  const handleSignOut = async () => {
    try {
      await signOut(auth);
      alert('You have signed out');
      navigate('/signin'); // Navigeeri login lehele
    } catch (error) {
      console.error('Sign-out error:', error); // Viga konsoolis
      alert('Sign-out error: ' + error.message);
    }
  };

  // Funktsioon kihi nähtavuse muutmiseks
  const toggleLayer = (layerName) => {
    setLayers((prev) => ({
      ...prev,
      [layerName]: !prev[layerName],
    }));
  };

  // Laadib Google Maps
  useEffect(() => {
    const loadMap = () => {
      const mapInstance = new window.google.maps.Map(mapRef.current, {
        center: { lat: 59.0, lng: 26.0 }, // Kaardi keskpunkt
        zoom: 8,                           // Algne suum
        mapTypeId: window.google.maps.MapTypeId.HYBRID, // Hübriidkaart
      });

      setMap(mapInstance);
    };

    // Kui Google Maps script pole veel laaditud, lisa see
    if (!window.google) {
      const script = document.createElement('script');
      script.src = `https://maps.googleapis.com/maps/api/js?key=AIzaSyBmoEPfvez7-e6S0npZc5xPNvXrkSFsfqY&libraries=geometry`;
      script.async = true;
      script.defer = true;
      script.onload = loadMap;
      document.head.appendChild(script);
    } else {
      loadMap();
    }
  }, []);

  // Uuendab kaardi kihte vastavalt valikule
  useEffect(() => {
    if (!map) return;

    // Eemalda olemasolevad kihid
    if (kaitsealaLayerRef.current) kaitsealaLayerRef.current.setMap(null);
    if (hoiualaLayerRef.current) hoiualaLayerRef.current.setMap(null);
    if (keelualaLayerRef.current) keelualaLayerRef.current.setMap(null);

    // Kaitseala kihi lisamine, kui valitud
    if (layers.kaitseala) {
      kaitsealaLayerRef.current = new window.google.maps.Data();
      kaitsealaLayerRef.current.loadGeoJson('../geo/kr_kaitseala.geojson');
      kaitsealaLayerRef.current.setStyle({
        fillColor: 'red',
        strokeColor: 'red',
        strokeWeight: 2,
        fillOpacity: 0.3,
      });
      kaitsealaLayerRef.current.setMap(map);
    }

    // Hoiuala kihi lisamine, kui valitud
    if (layers.hoiuala) {
      hoiualaLayerRef.current = new window.google.maps.Data();
      hoiualaLayerRef.current.loadGeoJson('../geo/kr_hoiuala.geojson');
      hoiualaLayerRef.current.setStyle({
        fillColor: 'orange',
        strokeColor: 'orange',
        strokeWeight: 2,
        fillOpacity: 0.3,
      });
      hoiualaLayerRef.current.setMap(map);
    }

    // Keeluala kihi lisamine, kui valitud
    if (layers.keeluala) {
      keelualaLayerRef.current = new window.google.maps.Data();
      keelualaLayerRef.current.loadGeoJson('../geo/kpo_piirangukeelualad.geojson');
      keelualaLayerRef.current.setStyle({
        fillColor: 'blue',
        strokeColor: 'blue',
        strokeWeight: 2,
        fillOpacity: 0.3,
      });
      keelualaLayerRef.current.setMap(map);
    }
  }, [layers, map]);

  return (
    <>
      {/* Google Maps konteiner */}
      <div ref={mapRef} id="map" style={{ width: '100vw', height: '100vh' }} />

      {/* Kihtide lüliti nupp */}
      <LayerToggleButton
        layerMenuOpen={layerMenuOpen}
        setLayerMenuOpen={setLayerMenuOpen}
        layers={layers}
        toggleLayer={toggleLayer}
      />

      {/* Kasutajamenüü nupp */}
      <UserMenuButton
        userMenuOpen={userMenuOpen}
        setUserMenuOpen={setUserMenuOpen}
        handleSignOut={handleSignOut}
        map={map}
      />

      {/* Marsruudi ehitaja nupp */}
      <RouteBuilderButton map={map} />
    </>
  );
}