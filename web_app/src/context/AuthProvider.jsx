import { useState, useEffect } from "react";  
import { getAuth, onAuthStateChanged } from "firebase/auth";
import { AuthContext } from "./AuthContext";

export function AuthProvider({ children }) {
  // Hoiab praegust kasutajat (null, kui pole sisse logitud)
  const [user, setUser] = useState(null);
  // Hoiab laadimise olekut (true, kuni auth ei ole kontrollitud)
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const auth = getAuth(); // Hangi Firebase auth objekt

    // Kuula autentimise oleku muutusi
    const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
      // Kui kasutaja on olemas, salvesta user, muidu null
      setUser(currentUser ?? null);
      // Pane loading false, sest auth olek on teada
      setLoading(false);
    });

    // Cleanup funktsioon, eemaldab kuulaja komponentide unmountimisel
    return () => unsubscribe();
  }, []);

  // väärtused, mida jagatakse konteksti kaudu
  const values = { user, setUser };

  return (
    <AuthContext.Provider value={values}>
      {/* Näita lapskomponente ainult siis, kui auth olek on teada */}
      {!loading && children}
    </AuthContext.Provider>
  );
}