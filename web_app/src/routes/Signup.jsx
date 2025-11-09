import { useState } from 'react'; 
import { getAuth, createUserWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc } from 'firebase/firestore';
import { useNavigate, Link } from 'react-router';

export function SignUp() {
  const [email, setEmail] = useState(''); // Kasutaja e-posti seisundi hoidmine
  const [password, setPassword] = useState(''); // Kasutaja parooli seisundi hoidmine
  const auth = getAuth(); // Firebase autentimise objekt
  const db = getFirestore(); // Firestore andmebaas
  const navigate = useNavigate(); // Navigatsiooni hook

  async function handleSignUp(e) {
    e.preventDefault(); // Takistab vormi vaikimisi saatmist
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password); // Uue kasutaja loomine Firebase abil
      const user = userCredential.user;

      await setDoc(doc(db, 'users', user.uid), { // Kasutaja andmete salvestamine Firestore'i
        userID: user.uid,
        email: user.email,
        img: '',
        name: '',
        phone: '',
        description: '',
        location_sharing: false
      });

      alert('User created and data saved!'); // Teade kasutaja edukast loomisest
      navigate('/home'); // Navigeerimine avalehele pärast registreerimist
    } catch (error) {
      console.error('Error signing up:', error); // Logime vea konsooli
      alert('Error signing up: ' + error.message); // Kuvame vea kasutajale
    }
  }

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      height: '100vh',
      backgroundColor: '#f0f2f5',
    }}>
      <div style={{
        backgroundColor: 'white',
        padding: '40px 30px',
        borderRadius: 12,
        boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
        width: '100%',
        maxWidth: 400,
      }}>
        <h2 style={{ textAlign: 'center', marginBottom: 16, marginTop: 0 }}>Sign Up</h2> {/* Pealkiri kasutajale */}
        <form onSubmit={handleSignUp}>
          <div style={{ marginBottom: 16 }}>
            <label htmlFor="email" style={{ display: 'block', marginBottom: 6, fontWeight: 500 }}>Email</label>
            <input
              onChange={(e) => setEmail(e.target.value)}
              type="email"
              id="email"
              required
              style={{
                width: '94%',
                padding: '10px 12px',
                border: '1px solid #ccc',
                borderRadius: 6,
                fontSize: 14,
              }}
            />
          </div>
          <div style={{ marginBottom: 24 }}>
            <label htmlFor="password" style={{ display: 'block', marginBottom: 6, fontWeight: 500 }}>Password</label>
            <input
              onChange={(e) => setPassword(e.target.value)}
              type="password"
              id="password"
              required
              style={{
                width: '94%',
                padding: '10px 12px',
                border: '1px solid #ccc',
                borderRadius: 6,
                fontSize: 14,
              }}
            />
          </div>
          <button type="submit" style={{
            width: '100%',
            padding: '12px',
            backgroundColor: '#1a1a1a',
            color: 'white',
            fontWeight: 'bold',
            border: 'none',
            borderRadius: 6,
            cursor: 'pointer',
            fontSize: 16,
          }}>
            Sign Up
          </button>
        </form>
        <p style={{ marginTop: 20, fontSize: 14, textAlign: 'center' }}>
          Already have an account?{' '}
          <Link to="/signin" style={{ color: '#646cff', textDecoration: 'underline' }}>
            Sign In
          </Link>
        </p>
      </div>
    </div>
  );
}