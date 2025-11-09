import { getAuth } from 'firebase/auth'; 
import { useEffect, useState } from 'react';
import { MyRoutesModal } from '../components/MyRoutesModal';

export function UserMenuButton({ userMenuOpen, setUserMenuOpen, handleSignOut, map }) {
  // Hoiab kasutaja emaili
  const [email, setEmail] = useState('');
  // Hoiab modaalakna avatud/seisundi
  const [showMyRoutesModal, setShowMyRoutesModal] = useState(false);

  useEffect(() => {
    const auth = getAuth();
    const currentUser = auth.currentUser;
    if (currentUser) {
      setEmail(currentUser.email); // Salvesta kasutaja email
    }
  }, []);

  return (
    <>
      <div style={{
        position: 'absolute', // fikseeritud asukoht
        top: 80,
        right: 10,
        zIndex: 1000,
      }}>
        {/* Nupp kasutajamenüü avamiseks */}
        <button
          onClick={() => setUserMenuOpen(!userMenuOpen)} // Vaheta menüü avatud/seisundit
          style={{
            width: 40,
            height: 40,
            borderRadius: '50%',
            border: 'none',
            backgroundColor: '#fff',
            backgroundImage: 'url("https://img.icons8.com/ios-filled/50/user-male-circle.png")',
            backgroundSize: '60%',
            backgroundRepeat: 'no-repeat',
            backgroundPosition: 'center',
            cursor: 'pointer',
            boxShadow: '0 2px 6px rgba(0,0,0,0.25)',
          }}
        />
        {userMenuOpen && (
          <div style={{
            position: 'absolute',
            top: 45,
            right: 0,
            backgroundColor: 'white',
            padding: '10px 12px',
            borderRadius: 8,
            fontSize: 14,
            boxShadow: '0 2px 6px rgba(0,0,0,0.25)',
            minWidth: 160,
          }}>
            {/* Näita tervitust, kui email olemas */}
            {email && (
              <div style={{
                marginBottom: 8,
                fontWeight: 'bold',
                color: '#333',
                wordBreak: 'break-word',
              }}>
                Hello, {email}
              </div>
            )}
            {/* Nupp "My Routes" */}
            <button
              onClick={() => {
                setShowMyRoutesModal(true);
                setUserMenuOpen(false);
              }}
              style={{
                backgroundColor: '#eeeeee',
                color: '#000',
                border: 'none',
                padding: '6px 10px',
                borderRadius: 4,
                cursor: 'pointer',
                width: '100%',
                marginBottom: 6,
              }}
            >
              My Routes
            </button>
            {/* Nupp "Sign Out" */}
            <button
              onClick={() => {
                handleSignOut();
                setUserMenuOpen(false);
              }}
              style={{
                backgroundColor: '#1a1a1a',
                color: 'white',
                border: 'none',
                padding: '6px 10px',
                borderRadius: 4,
                cursor: 'pointer',
                width: '100%',
              }}
            >
              Sign Out
            </button>
          </div>
        )}
      </div>

      {/* Ava MyRoutes modaalaken, kui showMyRoutesModal true */}
      {showMyRoutesModal && (
        <MyRoutesModal map={map} onClose={() => setShowMyRoutesModal(false)} />
      )}
    </>
  );
}