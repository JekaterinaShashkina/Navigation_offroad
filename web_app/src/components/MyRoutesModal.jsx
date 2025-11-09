import { 
  collection,
  deleteDoc,
  doc,
  getDocs,
  getFirestore,
  query,
  where,
  orderBy,
  updateDoc
} from 'firebase/firestore';
import { getAuth, onAuthStateChanged } from 'firebase/auth';
import { useEffect, useState } from 'react';
import { FlyToRoute } from './FlyToRoute';

export function MyRoutesModal({ onClose, map }) {
  const [routes, setRoutes] = useState([]);
  const [activeRouteId, setActiveRouteId] = useState(null);
  const db = getFirestore();
  const auth = getAuth();

  useEffect(() => {
    // Kui kasutaja muutub (login/logout), laeme tema marsruudid
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!user) return;
      const q = query(
        collection(db, 'routes'),
        where('userId', '==', user.uid),
        orderBy('createdAt', 'desc') // Sort by creation date, needs Firestore index
      );
      const querySnapshot = await getDocs(q);
      const result = [];
      querySnapshot.forEach(docSnap => {
        result.push({ id: docSnap.id, ...docSnap.data() });
      });
      setRoutes(result);
    });

    return () => unsubscribe();
  }, []);

  // Funktsioon marsruudi kustutamiseks koos kinnitusküsimusega
  const deleteRoute = async (id) => {
    const confirmDelete = window.confirm("Are you sure you want to delete this route?");
    if (!confirmDelete) return;

    await deleteDoc(doc(db, 'routes', id));
    setRoutes(prev => prev.filter(route => route.id !== id));

    if (activeRouteId === id) {
      setActiveRouteId(null);
    }
  };

  // Funktsioon marsruudi privaatsuse muutmiseks
  const togglePrivacy = async (id, currentValue) => {
    const routeRef = doc(db, 'routes', id);
    await updateDoc(routeRef, { isPrivate: !currentValue });

    // Uuendame lokaalselt, et kohe ekraanil muutuks
    setRoutes(prev =>
      prev.map(route =>
        route.id === id ? { ...route, isPrivate: !currentValue } : route
      )
    );
  };

  const activeRoute = routes.find(route => route.id === activeRouteId);

  return (
    <>
      <div style={{
        position: 'fixed',
        top: 60,
        left: 20,
        transform: 'none',
        zIndex: 2000,
        backgroundColor: 'white',
        padding: '16px 20px',
        borderRadius: 10,
        boxShadow: '0 2px 10px rgba(0,0,0,0.25)',
        width: '90%',
        maxWidth: 400,
        maxHeight: 300,
        overflowY: 'auto',
      }}>
        <div style={{ marginBottom: 12, fontSize: 18, fontWeight: 'bold' }}>My Routes</div>
        {routes.length === 0 ? (
          <div>No saved routes.</div>
        ) : (
          routes.map(route => {
            const isActive = route.id === activeRouteId;
            return (
              <div key={route.id}
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  marginBottom: 10,
                  borderBottom: '1px solid #eee',
                  paddingBottom: 6,
                  backgroundColor: isActive ? '#f0f8ff' : 'transparent',
                  borderRadius: 6,
                }}
              >
                {/* Valides -> näitab marsruudi kaardil */}
                <div
                  style={{ cursor: 'pointer', flex: 1 }}
                  onClick={() => setActiveRouteId(route.id)}
                >
                  <div style={{ fontWeight: isActive ? 'bold' : 'normal' }}>
                    {route.name || 'Unnamed'}
                  </div>
                  <div style={{ fontSize: 12, color: '#666' }}>
                    {route.createdAt?.toDate().toLocaleString()} — {route.lengthKm} km
                  </div>
                </div>

                {/* Nupp privaatsuse muutmiseks */}
                <button
                  onClick={() => togglePrivacy(route.id, route.isPrivate)}
                  style={{
                    padding: '4px 8px',
                    borderRadius: 4,
                    border: '1px solid #ccc',
                    backgroundColor: route.isPrivate ? '#ffeaea' : '#eaffea',
                    cursor: 'pointer',
                    fontSize: 12,
                    color: '#666',
                    marginLeft: 6,
                  }}
                >
                  {route.isPrivate ? 'Make Public' : 'Make Private'}
                </button>

                {/* Kustutamise ikoon koos kinnitusküsimusega */}
                <img
                  src="https://img.icons8.com/ios-glyphs/30/trash--v1.png"
                  alt="Delete"
                  title="Delete route"
                  onClick={() => deleteRoute(route.id)}
                  style={{ cursor: 'pointer', marginLeft: 8 }}
                />
              </div>
            );
          })
        )}
        <div style={{ textAlign: 'right', marginTop: 10 }}>
          <button
            onClick={onClose}
            style={{
              padding: '6px 12px',
              borderRadius: 4,
              border: 'none',
              backgroundColor: '#1a1a1a',
              color: 'white',
              cursor: 'pointer',
            }}
          >
            Close
          </button>
        </div>
      </div>

      {/* Kui aktiivne marsruut, siis liigume kaardil tema juurde */}
      {activeRoute && <FlyToRoute map={map} points={activeRoute.points} />}
    </>
  );
}