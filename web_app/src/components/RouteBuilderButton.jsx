import { useState, useEffect } from 'react'; 
import { collection, addDoc, getFirestore, Timestamp } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';
import { FlyToRoute } from './FlyToRoute';

export function RouteBuilderButton({ map }) {
  const [menuOpen, setMenuOpen] = useState(false);
  const [buildingRoute, setBuildingRoute] = useState(false);
  const [routePoints, setRoutePoints] = useState([]);
  const [polyline, setPolyline] = useState(null);
  const [lengthKm, setLengthKm] = useState(0);
  const [markers, setMarkers] = useState([]);
  const [routeName, setRouteName] = useState('');
  const [savedRoutePoints, setSavedRoutePoints] = useState(null);
  const [isPrivate, setIsPrivate] = useState(false);

  const auth = getAuth();
  const db = getFirestore();

  // Eemaldab salvestatud marsruudi kuvamise, kui menüü on suletud
  useEffect(() => {
    if (!menuOpen) {
      setSavedRoutePoints(null);
    }
  }, [menuOpen]);

  // Lisab kaardile klikikuulaja, et lisada marsruudi punkte
  useEffect(() => {
    if (!map || !buildingRoute) return;

    const listener = map.addListener('click', (e) => {
      const newPoint = { lat: e.latLng.lat(), lng: e.latLng.lng() };
      setRoutePoints((prev) => [...prev, newPoint]);

      const marker = new window.google.maps.Marker({
        position: newPoint,
        map: map,
        icon: {
          path: window.google.maps.SymbolPath.CIRCLE,
          scale: 6,
          fillColor: '#FF0000',
          fillOpacity: 1,
          strokeWeight: 1,
        },
      });

      setMarkers((prev) => [...prev, marker]);
    });

    return () => {
      window.google.maps.event.removeListener(listener);
    };
  }, [map, buildingRoute]);

  // Uuendab polüliini kaardil, kui marsruudi punktid muutuvad
  useEffect(() => {
    if (!map) return;
    // Eemaldab eelneva joone enne uue loomist
    if (polyline) {
      polyline.setMap(null);
    }

    if (routePoints.length === 0) {
      setLengthKm(0);
      return;
    }

    const path = routePoints.map(pt => new window.google.maps.LatLng(pt.lat, pt.lng));

    const newPolyline = new window.google.maps.Polyline({
      path,
      geodesic: true,
      strokeColor: '#FF0000',
      strokeOpacity: 1.0,
      strokeWeight: 3,
      map,
    });
    // Määrab uue polüliini objekti
    setPolyline(newPolyline);
    // Arvutab marsruudi pikkuse
    let distMeters = 0;
    for (let i = 1; i < path.length; i++) {
      distMeters += window.google.maps.geometry.spherical.computeDistanceBetween(path[i - 1], path[i]);
    }
    setLengthKm((distMeters / 1000).toFixed(2));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [routePoints, map]);

  const clearMarkers = () => {
    markers.forEach(marker => marker.setMap(null));
    setMarkers([]);
  };

  const startRoute = () => {
    clearMarkers();
    setRoutePoints([]);
    setLengthKm(0);
    setRouteName('');
    setBuildingRoute(true);
    setSavedRoutePoints(null);
  };

  const finishRoute = () => {
    setBuildingRoute(false);
  };

  const deleteLastPoint = () => {
    setRoutePoints(prev => prev.slice(0, -1));
    setMarkers(prev => {
      const last = prev[prev.length - 1];
      if (last) last.setMap(null);
      return prev.slice(0, -1);
    });
  };

  // Funktsioon marsruudi punktide interpoleerimiseks
  // Tagastab massiivi punktidest kahe antud punkti vahel määratud sammuga meetrites
  function interpolatePoints(start, end, stepMeters = 5) {
    const interpolated = [];

    const startLatLng = new window.google.maps.LatLng(start.lat, start.lng);
    const endLatLng = new window.google.maps.LatLng(end.lat, end.lng);

    const distance = window.google.maps.geometry.spherical.computeDistanceBetween(startLatLng, endLatLng);
    const steps = Math.floor(distance / stepMeters);

    for (let i = 1; i < steps; i++) {
      const fraction = i / steps;
      const interpolatedLatLng = window.google.maps.geometry.spherical.interpolate(startLatLng, endLatLng, fraction);
      interpolated.push({
        lat: interpolatedLatLng.lat(),
        lng: interpolatedLatLng.lng()
      });
    }

    return interpolated;
  }

  // Funktsioon sileda marsruudi genereerimiseks - jagab marsruudi väiksemateks sammudeks iga 5 meetri järel
  const generateSmoothRoute = (points, stepMeters = 5) => {
    const smoothPoints = [];

    for (let i = 0; i < points.length - 1; i++) {
      const current = points[i];
      const next = points[i + 1];

      smoothPoints.push(current); // marsruudi punkt
      const between = interpolatePoints(current, next, stepMeters);
      smoothPoints.push(...between); // interpoleeritud punktid
    }

    smoothPoints.push(points[points.length - 1]); // viimane punkt
    return smoothPoints;
  };

  const saveRoute = async () => {
    if (!auth.currentUser) {
      alert('Please log in to save the route');
      return;
    }

    if (routePoints.length === 0) {
      alert('The route is empty, nothing to save');
      return;
    }

    if (!routeName.trim()) {
      alert('Please enter a route name');
      return;
    }

    try {
      const userUid = auth.currentUser.uid;
      // Interpoleerib marsruudi punktid täpsemaks salvestamiseks
      const smoothRoutePoints = generateSmoothRoute(routePoints, 5); // 5 meters step

      const newRoute = {
        userId: userUid,
        name: routeName.trim(),
        points: smoothRoutePoints,
        lengthKm: Number(lengthKm),
        createdAt: Timestamp.fromDate(new Date()),
        isPrivate: isPrivate,
      };

      await addDoc(collection(db, 'routes'), newRoute);

      alert('Route saved!');
      // Salvestab marsruudi kuvamiseks
      setSavedRoutePoints(smoothRoutePoints);
      // Tühjendab marsruudi oleku
      setRoutePoints([]);
      setLengthKm(0);
      setRouteName('');
      setBuildingRoute(false);
      clearMarkers();
    } catch (error) {
      console.error('Error saving route:', error);
      alert('Error saving route: ' + error.message);
    }
  };

  return (
    <div style={{
      position: 'absolute',
      bottom: 210,
      right: 10.5,
      zIndex: 1000,
    }}>
      {/* Menu avamise nupp */}
      <button
        onClick={() => setMenuOpen(!menuOpen)}
        style={{
          width: 39,
          height: 39,
          borderRadius: 24,
          backgroundColor: 'white',
          border: 'none',
          cursor: 'pointer',
          backgroundImage: 'url("https://img.icons8.com/ios-filled/50/route.png")',
          backgroundSize: '60%',
          backgroundRepeat: 'no-repeat',
          backgroundPosition: 'center',
          boxShadow: buildingRoute ? '0 0 10px 2px red' : undefined,
        }}
        title="Route planning"
      />
      {menuOpen && (
        <div style={{
          position: 'absolute',
          bottom: 60,
          right: 50,
          backgroundColor: 'white',
          padding: '10px 12px',
          borderRadius: 8,
          fontSize: 14,
          minWidth: 210,
          boxShadow: '0 2px 6px rgba(0,0,0,0.25)',
        }}>
          {!buildingRoute && (
            <button onClick={startRoute} style={{ width: '100%', marginBottom: 8 }}>
              Start route planning
            </button>
          )}
          {buildingRoute && (
            <>
              <input
                type="text"
                value={routeName}
                onChange={(e) => setRouteName(e.target.value)}
                placeholder="Route name"
                style={{
                  width: '100%',
                  marginBottom: 8,
                  padding: '6px 8px',
                  borderRadius: 4,
                  border: '1px solid #ccc',
                  boxSizing: 'border-box',
                }}
              />
              <label style={{ display: 'flex', alignItems: 'center', marginBottom: 8 }}>
                <input
                  type="checkbox"
                  checked={isPrivate}
                  onChange={(e) => setIsPrivate(e.target.checked)}
                  style={{ marginRight: 6 }}
                />
                Private route
              </label>
              <button onClick={deleteLastPoint} disabled={routePoints.length === 0} style={{ width: '100%', marginBottom: 8 }}>
                Delete last point
              </button>
              <button onClick={finishRoute} style={{ width: '100%', marginBottom: 8 }}>
                Finish route
              </button>
            </>
          )}
          <button onClick={saveRoute} disabled={routePoints.length === 0} style={{ width: '100%', marginBottom: 8 }}>
            Save route
          </button>
          <div><b>Route length:</b> {lengthKm} km</div>
        </div>
      )}
      {/* Kuvab salvestatud marsruudi FlyToRoute abil */}
      {savedRoutePoints && <FlyToRoute map={map} points={savedRoutePoints} />}
    </div>
  );
}